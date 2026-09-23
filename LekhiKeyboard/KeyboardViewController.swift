//
//  KeyboardViewController.swift
//  LekhiKeyboard
//
//  The custom-keyboard entry point. Subclass of UIInputViewController
//  that hosts the SwiftUI keyboard tree and routes user actions to
//  the riti-backed transliteration engine.
//

import UIKit
import SwiftUI

/// Loads the transliteration engine off the main thread.
///
/// riti parses a 150 000-word dictionary when its context is created. Doing
/// that inline in `viewDidLoad` stalled the keyboard's first appearance,
/// which on slower devices is long enough to look like a hang. The keyboard
/// now presents immediately and the first key press waits — by then loading
/// has almost always already finished.
private final class EngineLoader {

    private let group = DispatchGroup()
    private let lock = NSLock()
    private var loaded: LekhiEngine?
    private var isFinished = false

    init(layout: Layout, mode: TypingMode) {
        group.enter()
        DispatchQueue.global(qos: .userInitiated).async { [self] in
            let built = LekhiEngineFactory.make(layout: layout, mode: mode)
            lock.lock()
            loaded = built
            isFinished = true
            lock.unlock()
            group.leave()
        }
    }

    /// Blocks until loading finishes. Safe to call from several places; a
    /// `DispatchGroup` returns straight away once it is empty.
    func engine() -> LekhiEngine? {
        group.wait()
        lock.lock()
        defer { lock.unlock() }
        return loaded
    }

    /// Non-blocking peek, for lifecycle paths that must never stall.
    func engineIfLoaded() -> LekhiEngine? {
        lock.lock()
        defer { lock.unlock() }
        return isFinished ? loaded : nil
    }

    func teardown() {
        group.wait()
        lock.lock()
        let engine = loaded
        loaded = nil
        lock.unlock()
        engine?.teardown()
    }
}

final class KeyboardViewController: UIInputViewController {

    // MARK: - Darwin notification helper
    //
    // We must NOT store a raw unretained pointer to `self` in the
    // CF notification center — if the VC is ever deallocated the
    // pointer becomes dangling and the next notification causes an
    // EXC_BAD_ACCESS (SIGSEGV at 0x20) crash.
    //
    // Instead we:
    //  • wrap `self` in a WeakBox (weak reference, no retain cycle)
    //  • passRetained the box so the C callback always has a live object
    //  • store the raw ptr so we can release it in deinit

    private final class WeakBox {
        weak var controller: KeyboardViewController?
        init(_ c: KeyboardViewController) { controller = c }
    }

    private var darwinObserverPtr: UnsafeMutableRawPointer?

    // MARK: - State

    private let session = InputSession()
    private var engineLoader: EngineLoader?
    private var router: KeyRouter!

    private var hostingController: UIHostingController<KeyboardRootView>?
    private var heightConstraint: NSLayoutConstraint?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // Kick the engine off in the background, then build the UI. Fail soft —
        // the keyboard still types plain Latin if the engine never initialises,
        // and the reason is recorded for the host app's diagnostics screen.
        rebuildEngine()

        router = KeyRouter(session: session) { [weak self] in
            self?.engineLoader?.engine()
        }

        // Listen for settings changes from the host app, and for light/dark
        // flips so `.systemAuto` repaints its plate.
        observeSettingsChanges()
        observeAppearanceChanges()

        syncFullAccess()

        // Let the input view take its height from our own constraint rather
        // than the system default.
        inputView?.allowsSelfSizing = true

        installKeyboardView()
        updateBackgroundTheme()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        syncFullAccess()
        syncPreferences()
        syncHostKeyboardType()
        let newLayout = LayoutStore.current()
        let newMode = TypingModeStore.current()
        updateBackgroundTheme()
        updateKeyboardHeightConstraint()
        if session.layout != newLayout || session.mode != newMode {
            commitActiveComposition()
            session.layout = newLayout
            session.mode = newMode
            rebuildEngine()
            installKeyboardView()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateBackgroundTheme()
        updateKeyboardHeightConstraint()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        pendingReconcile?.cancel()
        pendingReconcile = nil
        commitActiveComposition()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateGlobeKeyVisibility()
        updateKeyboardHeightConstraint()
    }

    override func updateViewConstraints() {
        super.updateViewConstraints()
        updateKeyboardHeightConstraint()
    }

    /// Publish whether iOS granted Full Access so the host app can explain it.
    ///
    /// A custom keyboard needs Full Access to drive the Taptic Engine; typing,
    /// suggestions and the settings shared through the App Group work either
    /// way.
    ///
    /// Only reported, never acted on: the feedback calls still go out either
    /// way. Suppressing them here would silence working haptics on any OS
    /// version that turns out not to gate them.
    private func syncFullAccess() {
        FullAccessReporter.record(hasFullAccess)
    }

    /// Mirror the shared preferences onto the session once, instead of having
    /// every keycap read `UserDefaults` while it renders.
    private func syncPreferences() {
        session.theme = ThemeStore.current()
        session.heightOption = KeyboardHeightStore.current()
        session.showCharacterPreview = CharacterPreviewStore.current()
        session.spacebarSwipeEnabled = SpacebarSwipeStore.current()
        session.showKeyHints = KeyHintStore.current()
        session.pinnedKeywords = PinnedKeywordsStore.current()
        session.canSwitchLayouts = LayoutStore.enabled().count > 1
        updateGlobeKeyVisibility()
    }

    /// iOS tells us whether this keyboard has to draw its own globe. Showing
    /// one unconditionally duplicated the system switcher on iOS versions
    /// that provide their own, and showed a dead key when Lekhi is the only
    /// third-party keyboard installed.
    private func updateGlobeKeyVisibility() {
        if session.showsGlobeKey != needsInputModeSwitchKey {
            session.showsGlobeKey = needsInputModeSwitchKey
        }
    }

    private func updateKeyboardHeightConstraint() {
        guard view.frame.width > 0 else { return }
        let safeBottom = view.safeAreaInsets.bottom
        let targetHeight: CGFloat
        if session.isEmojiMode {
            // Apple emoji keyboard is taller than bare letter keys: search +
            // four emoji rows + category strip.
            targetHeight = session.heightOption.emojiPanelHeight(safeAreaBottom: safeBottom)
        } else {
            let showsBar = !session.isEmojiSearchActive
                && !session.hostKeyboardContext.isDigitPad
                && session.mode.showsSuggestionBar
            var height = session.heightOption.totalHeight(
                showsSuggestionBar: showsBar,
                safeAreaBottom: safeBottom
            )
            // Search chrome replaces the suggestion bar and needs room for results.
            if session.isEmojiSearchActive {
                let searchChrome = 44 + (96 * session.heightOption.scaleFactor) + 12
                height += searchChrome
            }
            targetHeight = height
        }
        if let heightConstraint {
            if abs(heightConstraint.constant - targetHeight) > 0.5 {
                heightConstraint.constant = targetHeight
            }
        } else {
            let constraint = view.heightAnchor.constraint(equalToConstant: targetHeight)
            constraint.priority = UILayoutPriority(999)
            constraint.isActive = true
            self.heightConstraint = constraint
        }
    }

    /// Adapt layout to the host field's keyboard type (numpad, email, etc.).
    private func syncHostKeyboardType() {
        let context: HostKeyboardContext = {
            switch textDocumentProxy.keyboardType {
            case .numberPad, .asciiCapableNumberPad:
                return .numberPad
            case .phonePad:
                return .phonePad
            case .decimalPad:
                return .decimalPad
            case .numbersAndPunctuation:
                return .numbersAndPunctuation
            case .emailAddress:
                return .email
            default:
                return .standard
            }
        }()

        let previous = session.hostKeyboardContext
        guard previous != context else {
            // Stay locked on the pad / numbers page if the user somehow left it.
            if context.isDigitPad, !session.isEmojiMode {
                // Digit pads ignore layoutMode; nothing to force.
            } else if context == .numbersAndPunctuation,
                      session.layoutMode == .letters,
                      !session.isEmojiMode {
                session.layoutMode = .numbers
            }
            return
        }

        session.hostKeyboardContext = context
        session.isEmojiMode = false
        session.clearEmojiSearch()

        switch context {
        case .numberPad, .phonePad, .decimalPad:
            session.layoutMode = .numbers
            if session.hasActiveSession {
                commitActiveComposition()
            }
        case .numbersAndPunctuation:
            session.layoutMode = .numbers
            if session.hasActiveSession {
                commitActiveComposition()
            }
        case .email, .standard:
            if previous.isDigitPad || previous == .numbersAndPunctuation {
                session.layoutMode = .letters
            }
        }

        updateKeyboardHeightConstraint()
    }

    private func observeAppearanceChanges() {
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, _) in
            self.updateBackgroundTheme()
        }
    }

    private func updateBackgroundTheme() {
        switch session.theme {
        case .amoledBlack, .darkMechanical:
            overrideUserInterfaceStyle = .dark
            hostingController?.overrideUserInterfaceStyle = .dark
        case .classicLight, .retroBeige:
            overrideUserInterfaceStyle = .light
            hostingController?.overrideUserInterfaceStyle = .light
        case .systemAuto:
            overrideUserInterfaceStyle = .unspecified
            hostingController?.overrideUserInterfaceStyle = .unspecified
        }

        let isDark: Bool = {
            if overrideUserInterfaceStyle == .dark { return true }
            if overrideUserInterfaceStyle == .light { return false }
            if isViewLoaded, let tc = viewIfLoaded?.traitCollection {
                return tc.userInterfaceStyle == .dark
            }
            return UITraitCollection.current.userInterfaceStyle == .dark
        }()
        let resolved = session.theme.resolvedPalette(for: isDark ? .dark : .light)
        // On iOS 26 the keyboard sits inside a system container with rounded
        // top corners, and the plate is drawn by SwiftUI in that same shape.
        // Painting the UIKit views too would put square corners back behind
        // it; earlier systems have a square, full-bleed keyboard, so there the
        // UIKit colour just covers the frame before SwiftUI's first pass.
        let bg: UIColor = Theme.usesRoundedContainer ? .clear : resolved.uiBackgroundPlate

        viewIfLoaded?.backgroundColor = bg
        inputView?.backgroundColor = bg
        hostingController?.view.backgroundColor = .clear

        let usesContainer = Theme.usesRoundedContainer && themeMatchesSystemContainer()
        if session.plateUsesSystemContainer != usesContainer {
            session.plateUsesSystemContainer = usesContainer
        }
    }

    /// Whether the system keyboard container will be the same light/dark as
    /// the active theme. The container follows the host text field — its
    /// `keyboardAppearance`, or else the host app's appearance — not this
    /// controller's override, so a forced-light theme in a dark app would put
    /// light keys on a dark container. Those themes keep their own plate.
    private func themeMatchesSystemContainer() -> Bool {
        let containerIsDark: Bool = {
            switch textDocumentProxy.keyboardAppearance {
            case .dark: return true
            case .light: return false
            default:
                let style = view.window?.traitCollection.userInterfaceStyle
                    ?? UITraitCollection.current.userInterfaceStyle
                return style == .dark
            }
        }()
        switch session.theme {
        case .systemAuto:     return true
        case .classicLight:   return !containerIsDark
        case .darkMechanical: return containerIsDark
        case .amoledBlack, .retroBeige: return false
        }
    }

    // MARK: - Engine

    private func rebuildEngine() {
        engineLoader?.teardown()
        engineLoader = EngineLoader(layout: session.layout, mode: session.mode)
    }

    private func observeSettingsChanges() {
        guard darwinObserverPtr == nil else { return }   // guard against double-registration

        let center = CFNotificationCenterGetDarwinNotifyCenter()
        let box = WeakBox(self)
        // passRetained keeps the box alive for the full lifetime of the registration.
        // takeUnretainedValue() inside the C callback is therefore always safe.
        let ptr = Unmanaged.passRetained(box).toOpaque()
        darwinObserverPtr = ptr

        CFNotificationCenterAddObserver(
            center,
            ptr,
            { _, observerPtr, _, _, _ in
                guard let observerPtr else { return }
                // Safe: the +1 from passRetained keeps the box alive.
                let box = Unmanaged<WeakBox>
                    .fromOpaque(observerPtr)
                    .takeUnretainedValue()
                DispatchQueue.main.async { [weak box] in
                    box?.controller?.handleSettingsChanged()
                }
            },
            DarwinNotification.settingsChanged,
            nil,
            .deliverImmediately
        )
    }

    deinit {
        // Remove the Darwin observer and balance the passRetained from
        // observeSettingsChanges().  Without this the raw pointer lives
        // forever and the next notification delivery crashes on freed memory.
        if let ptr = darwinObserverPtr {
            CFNotificationCenterRemoveObserver(
                CFNotificationCenterGetDarwinNotifyCenter(),
                ptr,
                CFNotificationName(DarwinNotification.settingsChanged),
                nil
            )
            Unmanaged<WeakBox>.fromOpaque(ptr).release()   // balance passRetained
            darwinObserverPtr = nil
        }
        engineLoader?.teardown()
    }

    private func handleSettingsChanged() {
        let newLayout = LayoutStore.current()
        let newMode = TypingModeStore.current()
        let newTheme = ThemeStore.current()
        let newHeight = KeyboardHeightStore.current()

        var needsReinstall = false

        if session.theme != newTheme {
            session.theme = newTheme
            updateBackgroundTheme()
        }

        if session.heightOption != newHeight {
            session.heightOption = newHeight
            updateKeyboardHeightConstraint()
            needsReinstall = true
        }

        session.showCharacterPreview = CharacterPreviewStore.current()
        session.spacebarSwipeEnabled = SpacebarSwipeStore.current()
        session.showKeyHints = KeyHintStore.current()
        session.pinnedKeywords = PinnedKeywordsStore.current()
        session.canSwitchLayouts = LayoutStore.enabled().count > 1

        if newLayout != session.layout || newMode != session.mode {
            commitActiveComposition()
            session.layout = newLayout
            session.mode = newMode
            rebuildEngine()
            updateKeyboardHeightConstraint()
            needsReinstall = true
        }

        if needsReinstall {
            installKeyboardView()
        }
    }

    // MARK: - SwiftUI hosting

    private func installKeyboardView() {
        hostingController?.willMove(toParent: nil)
        hostingController?.view.removeFromSuperview()
        hostingController?.removeFromParent()

        let root = KeyboardRootView(
            session: session,
            onAction: { [weak self] action in
                self?.dispatch(action: action)
            },
            onCommitCandidate: { [weak self] index in
                self?.commitCandidate(at: index)
            },
            onLongPressCandidate: { [weak self] index in
                self?.saveCandidateAsFavourite(at: index)
            },
            onSwipeLanguage: { [weak self] forward in
                self?.handleSwipeLanguage(forward: forward)
            }
        )

        let host = UIHostingController(rootView: root)
        host.view.translatesAutoresizingMaskIntoConstraints = false
        host.view.backgroundColor = .clear
        host.safeAreaRegions = []

        addChild(host)
        view.addSubview(host.view)
        NSLayoutConstraint.activate([
            host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            host.view.topAnchor.constraint(equalTo: view.topAnchor),
            host.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        host.didMove(toParent: self)
        hostingController = host
        updateBackgroundTheme()
    }

    private func handleSwipeLanguage(forward: Bool) {
        retractSpacebarSpace()
        guard LayoutStore.neighbour(of: session.layout, forward: forward) != session.layout else { return }
        commitActiveComposition()
        session.cycleLanguage(forward: forward)
        rebuildEngine()
        HapticManager.shared.candidateSelected()
    }

    /// Take back the space the spacebar emitted on touch-down, now that the
    /// press has turned out to be a language swipe.
    ///
    /// Decided from the keyboard's own record rather than by looking for a
    /// trailing space in `documentContextBeforeInput`: the proxy has not
    /// necessarily caught up with an insert this recent, so reading it would
    /// leave the stray space behind on exactly the slower hosts where the
    /// swipe is most awkward already.
    private func retractSpacebarSpace() {
        guard spacebarSpaceIsRetractable else { return }
        spacebarSpaceIsRetractable = false
        noteSelfEdit()
        isDispatching = true
        defer { isDispatching = false }
        textDocumentProxy.deleteBackward()
    }

    private var isDispatching = false

    /// What the word being composed has already put in the document, so a
    /// change callback that arrives late — after the next keystroke has moved
    /// the composition on — is recognised as ours instead of being mistaken
    /// for the host rewriting the text. See `ComposingHistory`.
    private var composingHistory = ComposingHistory()

    /// True while the space emitted by the current spacebar touch-down can
    /// still be taken back, i.e. until anything else touches the document.
    private var spacebarSpaceIsRetractable = false

    /// Bumped by every edit the keyboard makes, so a second look that was
    /// scheduled earlier can tell that typing carried on without it.
    private var selfEditGeneration = 0
    private var lastSelfEditAt: Date = .distantPast
    private var pendingReconcile: DispatchWorkItem?

    /// How long the host is given to catch up before a context that still
    /// disagrees is believed.
    private static let reconcileSettleDelay: TimeInterval = 0.15

    /// How long the keyboard must have been idle before a keystroke is allowed
    /// to resolve a pending second look on the spot rather than cancel it.
    private static let reconcileIdleThreshold: TimeInterval = 0.4

    /// Record that the keyboard itself just changed the document, and drop any
    /// second look that was waiting: it was asked about a document this edit
    /// has already moved past.
    private func noteSelfEdit() {
        selfEditGeneration &+= 1
        lastSelfEditAt = Date()
        pendingReconcile?.cancel()
        pendingReconcile = nil
    }

    /// Clear the composition, and with it the record of what it displayed.
    private func resetComposing() {
        session.resetComposing()
        composingHistory.reset()
    }

    // MARK: - Action dispatch

    private func dispatch(action: KeyAction) {
        // A second look is still waiting and the keyboard has been idle: the
        // change it was asked about cannot be our edits in flight, so it is the
        // user having moved somewhere else. Settle it before this keystroke
        // computes a deletion against a cursor that has moved.
        if pendingReconcile != nil,
           Date().timeIntervalSince(lastSelfEditAt) > Self.reconcileIdleThreshold {
            resolveReconcileNow()
        }
        noteSelfEdit()

        isDispatching = true
        defer { isDispatching = false }

        // Defensive: the direct-commit model never creates marked text, but
        // clear any legacy composition so it can't offset delete counts.
        textDocumentProxy.unmarkText()

        let outcome = router.route(action)

        switch outcome {
        case .replaceComposing(let deleteCount, let insert):
            // The keyboard's own record of what it inserted is the source of
            // truth here. `documentContextBeforeInput` is not usable for a
            // cross-check at this point: the proxy lags our own edits by a
            // frame, so it would report a stale prefix and we would skip the
            // delete, leaving the previous transliteration behind.
            // `reconcileExternalChange` handles genuine divergence instead,
            // where the context has settled.
            for _ in 0..<max(0, deleteCount) {
                textDocumentProxy.deleteBackward()
            }
            if !insert.isEmpty {
                textDocumentProxy.insertText(insert)
            }
        case .insert(let text):
            textDocumentProxy.insertText(text)
        case .deleteBackward:
            textDocumentProxy.deleteBackward()
        case .advanceInputMode:
            advanceToNextInputMode()
        case .none:
            break
        }

        // The spacebar emits on touch-down, before the keyboard can know
        // whether the finger is going to travel on into a language swipe, so
        // that space stays retractable until anything else edits the document.
        spacebarSpaceIsRetractable = (action == .space && outcome == .insert(" "))

        composingHistory.record(session.committedBengali)

        if case .emoji = action {
            // The candidate bar disappears in emoji mode, so the input view
            // needs to shrink with it.
            updateKeyboardHeightConstraint()
        }
    }

    private func commitCandidate(at index: Int) {
        noteSelfEdit()

        // Anything else reaching the document ends the window in which the
        // spacebar's touch-down space can still be taken back.
        spacebarSpaceIsRetractable = false

        // Idle bar shows the favourites for the active layout — tap inserts
        // them directly.
        if session.isShowingPinnedKeywords {
            let idle = session.idleCandidates
            guard index >= 0, index < idle.count else { return }
            let chosen = idle[index]
            guard !chosen.isEmpty else { return }
            textDocumentProxy.insertText(chosen)
            HapticManager.shared.candidateSelected()
            return
        }

        switch session.barChoice(at: index) {
        case .savedWord(let phrase):
            commitSavedWord(phrase)
        case .engineCandidate(let engineIndex):
            commitEngineCandidate(at: engineIndex)
        case nil:
            return
        }
    }

    /// Tapping a saved-keyword completion swaps the word being composed for
    /// the full phrase. The engine session is closed without teaching riti a
    /// candidate — the user picked their own phrase, not one of its readings.
    private func commitSavedWord(_ phrase: String) {
        guard !phrase.isEmpty else { return }

        isDispatching = true
        defer { isDispatching = false }

        engineLoader?.engineIfLoaded()?.finishSession()
        let old = session.layout == .english ? session.buffer : session.committedBengali
        resetComposing()

        if phrase != old {
            for _ in 0..<DocumentEdit.deletionSteps(for: old) {
                textDocumentProxy.deleteBackward()
            }
            textDocumentProxy.insertText(phrase)
        }
        HapticManager.shared.candidateSelected()
    }

    private func commitEngineCandidate(at index: Int) {
        guard session.hasActiveSession else { return }
        guard index >= 0, index < session.candidates.count else { return }

        isDispatching = true
        defer { isDispatching = false }

        let chosen = session.candidates[index]

        if session.layout == .english {
            for _ in 0..<DocumentEdit.deletionSteps(for: session.buffer) {
                textDocumentProxy.deleteBackward()
            }
            textDocumentProxy.insertText(chosen + " ")
            resetComposing()
            HapticManager.shared.candidateSelected()
            return
        }

        guard let engine = engineLoader?.engineIfLoaded() else { return }
        _ = engine.commitCandidate(at: index)
        engine.finishSession()
        // The live composing chunk is already in the document via
        // direct-commit: swap it for the picked candidate, then freeze.
        let old = session.committedBengali
        resetComposing()
        if chosen != old {
            for _ in 0..<DocumentEdit.deletionSteps(for: old) {
                textDocumentProxy.deleteBackward()
            }
            if !chosen.isEmpty {
                textDocumentProxy.insertText(chosen)
            }
        }
        HapticManager.shared.candidateSelected()
    }

    /// Long press on a live candidate: add it to the favourites list without
    /// touching the composition, so the user can keep typing the word.
    private func saveCandidateAsFavourite(at index: Int) {
        guard !session.isShowingPinnedKeywords,
              let choice = session.barChoice(at: index),
              case .engineCandidate(let engineIndex) = choice,
              engineIndex < session.candidates.count else { return }
        let keyword = session.candidates[engineIndex]

        let result = PinnedKeywordsStore.add(keyword)
        session.pinnedKeywords = PinnedKeywordsStore.current()
        HapticManager.shared.keyPress(isAction: true)

        let notice = InputSession.FavouriteNotice(result: result, keyword: keyword)
        session.favouriteNotice = notice
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) { [weak self] in
            // A newer long press owns the bar now; let its own timer clear it.
            guard let self, self.session.favouriteNotice?.id == notice.id else { return }
            self.session.favouriteNotice = nil
        }
    }

    /// Freeze the composition before an engine/layout transition. With the
    /// direct-commit model the displayed Bengali chunk is already in the
    /// document, so this only closes the engine session and clears keyboard
    /// state — it never inserts text (which would duplicate).
    private func commitActiveComposition() {
        let engine = engineLoader?.engineIfLoaded()

        guard session.hasActiveSession else {
            engine?.finishSession()
            resetComposing()
            return
        }

        // English input is inserted directly on every keypress; its candidate
        // state is advisory only, so there is nothing to commit here.
        if session.layout == .english {
            resetComposing()
            return
        }

        // Same as space: the word is already in the document, and only an
        // explicit tap should teach riti a selection.
        engine?.finishSession()

        // Repair-only fallback: if no Bengali was ever displayed for this
        // composition (e.g. desync), insert the resolved candidate so the
        // word isn't lost on the field/layout switch.
        let chosen = router?.resolveCurrentCandidate() ?? session.preEditText
        if session.committedBengali.isEmpty, !chosen.isEmpty {
            textDocumentProxy.insertText(chosen)
        }
        resetComposing()
    }

    private func discardStaleCompositionState() {
        pendingReconcile?.cancel()
        pendingReconcile = nil
        engineLoader?.engineIfLoaded()?.finishSession()
        resetComposing()
    }

    // MARK: - Text-document callbacks

    override func textDidChange(_ textInput: (any UITextInput)?) {
        super.textDidChange(textInput)
        updateBackgroundTheme()
        syncHostKeyboardType()
        reconcileExternalChange()
    }

    override func selectionDidChange(_ textInput: (any UITextInput)?) {
        super.selectionDidChange(textInput)
        reconcileExternalChange()
    }

    /// Freeze the composition when the host document diverged from what the
    /// keyboard inserted (cursor move, host autocorrect/rewrite, field
    /// change, dictation). Our own recent edits still end with
    /// `committedBengali`, so they pass the suffix check and keep state —
    /// this is what makes the check safe against async callbacks for our
    /// own `insertText` / `deleteBackward` batches (guarded separately by
    /// `isDispatching` for the synchronous case).
    private func reconcileExternalChange() {
        guard !isDispatching, session.hasActiveSession else { return }
        guard !session.committedBengali.isEmpty else { return }

        // A missing context is not evidence that anything changed. The proxy
        // reports nil for a beat after our own edit lands, and secure fields
        // never report one at all. Treating nil as "the host rewrote the text"
        // tore down the composition on the first letter of every word — the
        // document still ended up with the right characters, but the engine
        // restarted each time, so suggestions and multi-letter conjuncts never
        // worked. Whether the nil window was hit came down to how quickly the
        // host app answered, which is why it broke on some devices and apps
        // and not others.
        guard let before = textDocumentProxy.documentContextBeforeInput else {
            return
        }
        if contextIsOurs(before) {
            return
        }
        // Not recognised — but a mismatch on its own is not evidence of
        // anything. `documentContextBeforeInput` trails the keyboard's own
        // edits, and at the start of a word there is nothing of that word in it
        // to match at all, so the first letter of every word mismatched
        // whenever the host was a beat behind. Discarding there tore the
        // composition down mid-word, which is precisely what turns `bangla`
        // into "বআংলা" and stops `স্ব` ever forming: riti only builds a
        // conjunct out of consonants it sees inside a single session.
        //
        // So ask again once the host has gone quiet.
        scheduleReconcileConfirmation()
    }

    /// Whether a reported context ends with something this keyboard put there.
    private func contextIsOurs(_ context: String) -> Bool {
        if context.hasSuffix(session.committedBengali) { return true }
        return composingHistory.recognises(context)
    }

    /// Look again after the host has had time to catch up. Any edit of our own
    /// in the meantime cancels the check — during a burst of typing it
    /// therefore never runs, which is the whole point.
    private func scheduleReconcileConfirmation() {
        pendingReconcile?.cancel()
        let generation = selfEditGeneration
        let work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.pendingReconcile = nil
            guard generation == self.selfEditGeneration else { return }
            self.resolveReconcileNow()
        }
        pendingReconcile = work
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.reconcileSettleDelay, execute: work)
    }

    /// The second look. Only a context that still disagrees once the host is
    /// quiet counts as the cursor having moved, the host having rewritten the
    /// text, or dictation having taken over.
    private func resolveReconcileNow() {
        pendingReconcile?.cancel()
        pendingReconcile = nil

        guard !isDispatching, session.hasActiveSession else { return }
        guard !session.committedBengali.isEmpty else { return }
        guard let settled = textDocumentProxy.documentContextBeforeInput else { return }
        guard !contextIsOurs(settled) else { return }

        // Never delete across the new cursor. The already-inserted word stays
        // as-is; the next keystroke starts a fresh composition.
        discardStaleCompositionState()
    }
}
