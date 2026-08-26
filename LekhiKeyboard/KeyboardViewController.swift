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

    // MARK: - State

    private let session = InputSession()
    private var engine: LekhiEngine?
    private var router: KeyRouter!

    private var hostingController: UIHostingController<KeyboardRootView>?

    // MARK: - Lifecycle

    override func loadView() {
        super.loadView()
        updateBackgroundTheme()
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
        updateBackgroundTheme()
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
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateBackgroundTheme()
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

        let isDark = (overrideUserInterfaceStyle == .dark) || (overrideUserInterfaceStyle == .unspecified && traitCollection.userInterfaceStyle == .dark)
        let resolved = session.theme.resolvedPalette(for: isDark ? .dark : .light)
        let bg = resolved.uiBackgroundPlate

        view.backgroundColor = bg
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
        let center = CFNotificationCenterGetDarwinNotifyCenter()
        let observer = Unmanaged.passUnretained(self).toOpaque()
        CFNotificationCenterAddObserver(
            center,
            observer,
            { _, observerPtr, _, _, _ in
                guard let observerPtr else { return }
                let controller = Unmanaged<KeyboardViewController>
                    .fromOpaque(observerPtr)
                    .takeUnretainedValue()
                DispatchQueue.main.async {
                    controller.handleSettingsChanged()
                }
            },
            DarwinNotification.settingsChanged,
            nil,
            .deliverImmediately
        )
    }

    private func handleSettingsChanged() {
        let newLayout = LayoutStore.current()
        let newMode = TypingModeStore.current()
        let newTheme = ThemeStore.current()

        if session.theme != newTheme {
            session.theme = newTheme
            updateBackgroundTheme()
        }

        guard newLayout != session.layout || newMode != session.mode else {
            return
        }
        session.layout = newLayout
        session.mode = newMode
        rebuildEngine()
        router = KeyRouter(session: session, engine: engine)
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

    private var isDispatching = false

    // MARK: - Action dispatch

    private func dispatch(action: KeyAction) {
        if case .character = action {
            UISelectionFeedbackGenerator().selectionChanged()
        } else if case .backspace = action {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }

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
            UISelectionFeedbackGenerator().selectionChanged()
            return
        }

        guard let engine else { return }
        _ = engine.commitCandidate(at: index)
        engine.finishSession()
        textDocumentProxy.insertText(chosen)
        session.buffer = ""
        session.clearSuggestions()
        UISelectionFeedbackGenerator().selectionChanged()
    }

    // MARK: - Text-document callbacks

    override func textWillChange(_ textInput: (any UITextInput)?) {
        super.textWillChange(textInput)
    }

    override func textDidChange(_ textInput: (any UITextInput)?) {
        super.textDidChange(textInput)
        guard !isDispatching else { return }
        // End the session if the user moved the cursor externally.
        engine?.finishSession()
        session.clearSuggestions()
        session.buffer = ""
    }
}
