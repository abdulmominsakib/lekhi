//
//  KeyboardViewController.swift
//  LekhoKeyboard
//
//  The custom-keyboard entry point. Subclass of UIInputViewController
//  that hosts the SwiftUI keyboard tree and routes user actions to
//  the riti-backed transliteration engine.
//

import UIKit
import SwiftUI

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
    private var engine: LekhiEngine?
    private var router: KeyRouter!

    private var hostingController: UIHostingController<KeyboardRootView>?
    private var heightConstraint: NSLayoutConstraint?

    // MARK: - Lifecycle

    override func loadView() {
        super.loadView()
        // Do not query traitCollection before view is in hierarchy
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Spin up the engine. Fail soft — keyboard still works for
        // unaccented English if the engine never initialises.
        rebuildEngine()

        // Wire the router to the freshly-built session/engine.
        router = KeyRouter(session: session, engine: engine)

        // Listen for settings changes from the host app.
        observeSettingsChanges()

        // Install the SwiftUI tree.
        installKeyboardView()
        updateBackgroundTheme()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        session.theme = ThemeStore.current()
        session.heightOption = KeyboardHeightStore.current()
        session.showCharacterPreview = CharacterPreviewStore.current()
        updateBackgroundTheme()
        updateKeyboardHeightConstraint()
        if session.layout != LayoutStore.current()
            || session.mode != TypingModeStore.current() {
            rebuildEngine()
            router = KeyRouter(session: session, engine: engine)
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
        if session.hasActiveSession {
            engine?.finishSession()
            session.clearSuggestions()
            session.buffer = ""
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateBackgroundTheme()
        updateKeyboardHeightConstraint()
    }

    override func updateViewConstraints() {
        super.updateViewConstraints()
        updateKeyboardHeightConstraint()
    }

    private func updateKeyboardHeightConstraint() {
        guard view.frame.width > 0 else { return }
        let targetHeight = session.heightOption.totalHeight
        if let heightConstraint {
            if heightConstraint.constant != targetHeight {
                heightConstraint.constant = targetHeight
            }
        } else {
            let constraint = view.heightAnchor.constraint(equalToConstant: targetHeight)
            constraint.priority = UILayoutPriority(999)
            constraint.isActive = true
            self.heightConstraint = constraint
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateBackgroundTheme()
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
        let bg = resolved.uiBackgroundPlate

        viewIfLoaded?.backgroundColor = bg
        inputView?.backgroundColor = bg
        hostingController?.view.backgroundColor = .clear
    }

    // MARK: - Engine

    private func rebuildEngine() {
        engine?.teardown()
        engine = LekhiEngineFactory.make(
            layout: session.layout,
            mode: session.mode
        )
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
    }

    private func handleSettingsChanged() {
        let newLayout = LayoutStore.current()
        let newMode = TypingModeStore.current()
        let newTheme = ThemeStore.current()
        let newHeight = KeyboardHeightStore.current()
        let newPreview = CharacterPreviewStore.current()

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

        if session.showCharacterPreview != newPreview {
            session.showCharacterPreview = newPreview
        }

        if newLayout != session.layout || newMode != session.mode {
            session.layout = newLayout
            session.mode = newMode
            rebuildEngine()
            router = KeyRouter(session: session, engine: engine)
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
    }

    private func handleSwipeLanguage(forward: Bool) {
        if session.hasActiveSession {
            let chosen = router.resolveCurrentCandidate()
            if !chosen.isEmpty {
                textDocumentProxy.insertText(chosen + " ")
            }
            engine?.finishSession()
            session.clearSuggestions()
            session.buffer = ""
        }
        session.cycleLanguage(forward: forward)
        rebuildEngine()
        router = KeyRouter(session: session, engine: engine)
        HapticManager.shared.candidateSelected()
    }

    private var isDispatching = false

    // MARK: - Action dispatch

    private func dispatch(action: KeyAction) {
        isDispatching = true
        defer { isDispatching = false }

        let outcome = router.route(action)

        switch outcome {
        case .setMarkedText(let text):
            textDocumentProxy.setMarkedText(
                text,
                selectedRange: NSRange(location: text.utf16.count, length: 0)
            )
        case .commitText(let text):
            textDocumentProxy.insertText(text)
        case .unmarkText:
            textDocumentProxy.unmarkText()
        case .insert(let text):
            textDocumentProxy.insertText(text)
        case .deleteBackward:
            textDocumentProxy.deleteBackward()
        case .advanceInputMode:
            advanceToNextInputMode()
        case .none:
            break
        }
    }

    private func commitCandidate(at index: Int) {
        guard session.hasActiveSession else { return }
        guard index >= 0, index < session.candidates.count else { return }

        isDispatching = true
        defer { isDispatching = false }

        let chosen = session.candidates[index]

        if session.layout == .english {
            let count = session.buffer.utf16.count
            for _ in 0..<count {
                textDocumentProxy.deleteBackward()
            }
            textDocumentProxy.insertText(chosen + " ")
            session.buffer = ""
            session.clearSuggestions()
            HapticManager.shared.candidateSelected()
            return
        }

        guard let engine else { return }
        _ = engine.commitCandidate(at: index)
        engine.finishSession()
        textDocumentProxy.insertText(chosen)
        session.buffer = ""
        session.clearSuggestions()
        HapticManager.shared.candidateSelected()
    }

    // MARK: - Text-document callbacks

    override func textWillChange(_ textInput: (any UITextInput)?) {
        super.textWillChange(textInput)
    }

    override func textDidChange(_ textInput: (any UITextInput)?) {
        super.textDidChange(textInput)
    }
}
