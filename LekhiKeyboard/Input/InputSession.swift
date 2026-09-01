//
//  InputSession.swift
//  LekhiKeyboard
//
//  Observable model representing the current transliteration & keyboard state.
//

import Foundation
import Observation

@Observable
public final class InputSession {

    // MARK: - Mode / layout

    public var layout: Layout
    public var mode: TypingMode
    public var theme: KeyboardThemeID
    public var heightOption: KeyboardHeightOption
    public var showCharacterPreview: Bool

    // MARK: - View state

    public var isShifted: Bool = false
    public var layoutMode: KeyboardLayoutMode = .letters
    public var isEmojiMode: Bool = false

    public var isSymbolMode: Bool {
        get { layoutMode != .letters }
        set { layoutMode = newValue ? .numbers : .letters }
    }

    public func cycleLanguage(forward: Bool = true) {
        let target = forward ? layout.nextLanguage : layout.previousLanguage
        layout = target
        LayoutStore.set(target)
    }

    /// Up to three visible candidates.
    public var candidates: [String] = []

    /// Live in-progress pre-edit string (Bengali transliteration).
    public var preEditText: String = ""

    /// Index of the highlighted candidate.
    public var selectedIndex: Int = -1

    /// Whether an active transliteration session is in progress.
    public var hasActiveSession: Bool = false

    /// Raw typed characters in current buffer.
    public var buffer: String = ""

    public init(
        layout: Layout = LayoutStore.current(),
        mode: TypingMode = TypingModeStore.current(),
        theme: KeyboardThemeID = ThemeStore.current(),
        heightOption: KeyboardHeightOption = KeyboardHeightStore.current(),
        showCharacterPreview: Bool = CharacterPreviewStore.current()
    ) {
        self.layout = layout
        self.mode = mode
        self.theme = theme
        self.heightOption = heightOption
        self.showCharacterPreview = showCharacterPreview
    }

    // MARK: - Mutation helpers

    /// Apply a freshly generated suggestion to the visible state.
    public func apply(_ suggestion: Suggestion) {
        candidates = suggestion.topThree
        preEditText = suggestion.preEditText
        selectedIndex = candidates.isEmpty ? -1 : suggestion.defaultIndex
        // riti represents phonetic-only composition as Suggestion::Single even
        // while its buffer is active. Keep that marked-text session alive until
        // space/return instead of committing and resetting after every letter.
        hasActiveSession = !suggestion.candidates.isEmpty
            && (!suggestion.isLonely || mode == .phoneticOnly)
    }

    /// Clear the suggestion bar.
    public func clearSuggestions() {
        candidates = []
        preEditText = ""
        selectedIndex = -1
        hasActiveSession = false
    }
}
