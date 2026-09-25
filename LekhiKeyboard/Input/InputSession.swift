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

    // MARK: - User preferences
    //
    // Mirrored onto the session rather than read from `UserDefaults` inside
    // `body`. The views used to call the stores while rendering, which meant
    // a defaults lookup per keycap per frame.

    public var showCharacterPreview: Bool
    public var spacebarSwipeEnabled: Bool
    public var showKeyHints: Bool

    /// Whether this keyboard has to draw its own input-mode switcher. iOS
    /// answers through `UIInputViewController.needsInputModeSwitchKey`; on
    /// versions that provide a system globe below the keyboard, drawing one
    /// here too would be a duplicate.
    public var showsGlobeKey: Bool = true

    /// True when iOS's own keyboard container should serve as the plate.
    ///
    /// On iOS 26 the keyboard sits inside a system container that iOS paints
    /// itself, including a strip above this view that the extension cannot
    /// draw into. Any opaque plate therefore meets that strip along a visible
    /// edge. When the theme's light/dark matches the container's, leaving the
    /// plate transparent makes the container the one continuous background.
    public var plateUsesSystemContainer: Bool = false

    // MARK: - View state

    public var isShifted: Bool = false
    public var isCapsLocked: Bool = false
    public var layoutMode: KeyboardLayoutMode = .letters
    public var isEmojiMode: Bool = false

    /// Host field keyboard type (number pad, email, etc.).
    public var hostKeyboardContext: HostKeyboardContext = .standard

    /// Host field needs ASCII digits (number/phone/decimal/numbersAndPunctuation).
    public var isNumericHostField: Bool {
        hostKeyboardContext.forcesASCIIDigits
    }

    /// User is typing a query for emoji search (letter keys feed `emojiSearchQuery`).
    public var isEmojiSearchActive: Bool = false
    public var emojiSearchQuery: String = ""

    public var isSymbolMode: Bool {
        get { layoutMode != .letters }
        set { layoutMode = newValue ? .numbers : .letters }
    }

    public func clearEmojiSearch() {
        isEmojiSearchActive = false
        emojiSearchQuery = ""
    }

    /// Whether more than one layout is turned on, i.e. whether a spacebar
    /// swipe has anywhere to go.
    public var canSwitchLayouts: Bool = LayoutStore.enabled().count > 1

    /// Move to the next layout the user has turned on. Returns `false` when
    /// there is nothing to switch to.
    @discardableResult
    public func cycleLanguage(forward: Bool = true) -> Bool {
        let target = LayoutStore.neighbour(of: layout, forward: forward)
        guard target != layout else { return false }
        layout = target
        LayoutStore.set(target)
        return true
    }

    /// The engine's visible candidates, up to `Suggestion.maxBarCount`.
    public var candidates: [String] = []

    /// What has been typed of the current word, in the script completions
    /// are matched against.
    private var typedForCompletion: String {
        if layout == .english { return buffer }
        return committedBengali.isEmpty ? preEditText : committedBengali
    }

    /// Saved favourites that complete the word being composed, in favourites
    /// order. Shown ahead of the engine's candidates so a phrase the user saved
    /// ("আসসালামু আলাইকুম") is one tap away once its beginning is typed.
    public var savedWordMatches: [String] {
        PinnedKeywordsStore.completions(of: typedForCompletion, in: pinnedKeywords)
    }

    /// Built-in everyday phrases that complete the word being composed.
    ///
    /// Offered *after* the engine's candidates, not before: favourites ahead
    /// of the engine are the user's own choice, but a built-in list there
    /// would push the reading actually in the document off the visible bar on
    /// every short prefix — আ alone completes to half the list.
    ///
    /// Matched against every Bangla reading in the bar, not only the one in
    /// the document: in phonetic-first mode `ami` is written অমি, while the
    /// word meant — and the start of "আমি ভালো আছি" — is the engine's আমি.
    public var commonPhraseMatches: [String] {
        guard layout != .english else { return [] }
        let shown = Set(savedWordMatches + candidates)
        let prefixes = ([typedForCompletion] + candidates)
            .filter { !$0.isEmpty && Self.usesBengaliScript($0) }
        guard !prefixes.isEmpty else { return [] }

        var matches: [String] = []
        for phrase in CommonPhrases.bangla where !shown.contains(phrase) {
            guard prefixes.contains(where: { phrase.count > $0.count && phrase.hasPrefix($0) }) else { continue }
            matches.append(phrase)
            if matches.count == CommonPhrases.maxCompletions { break }
        }
        return matches
    }

    /// The full list the suggestion bar shows while composing: favourite
    /// completions, the engine's candidates, then built-in completions. The
    /// bar scrolls, so all of them are reachable.
    public var barCandidates: [String] {
        savedWordMatches + candidates + commonPhraseMatches
    }

    /// Where a suggestion-bar tap lands: a saved keyword, or an index into the
    /// engine's `candidates` (the index `engine.commitCandidate` expects).
    public enum BarChoice: Equatable {
        case savedWord(String)
        case engineCandidate(Int)
    }

    public func barChoice(at index: Int) -> BarChoice? {
        guard index >= 0 else { return nil }
        let matches = savedWordMatches
        if index < matches.count { return .savedWord(matches[index]) }
        let engineIndex = index - matches.count
        if engineIndex < candidates.count { return .engineCandidate(engineIndex) }
        // A built-in phrase replaces the word exactly like a favourite does.
        let phraseIndex = engineIndex - candidates.count
        let phrases = commonPhraseMatches
        guard phraseIndex < phrases.count else { return nil }
        return .savedWord(phrases[phraseIndex])
    }

    /// Favourite keywords shown in the suggestion bar while idle
    /// (before the user starts typing a word).
    public var pinnedKeywords: [String]

    /// Brief confirmation shown in the suggestion bar after a long press
    /// saves a candidate as a favourite.
    public var favouriteNotice: FavouriteNotice?

    /// Live in-progress pre-edit string (Bengali transliteration).
    public var preEditText: String = ""

    /// Index of the highlighted candidate.
    public var selectedIndex: Int = -1

    /// Whether an active transliteration session is in progress.
    public var hasActiveSession: Bool = false

    /// Raw typed characters in current buffer.
    public var buffer: String = ""

    /// True when the suggestion bar should show pinned favourites instead
    /// of live candidates — nothing typed yet, no composition in flight.
    public var isShowingPinnedKeywords: Bool {
        buffer.isEmpty && !hasActiveSession
    }

    /// What the bar offers while idle, before anything is typed.
    ///
    /// Favourites lead on every layout. Bangla layouts follow them with the
    /// built-in everyday phrases, a swipe along the bar. The English layout
    /// has no use for Bengali script — tapping one would drop Bengali into an
    /// English sentence — so English shows only its Latin favourites and,
    /// until there are enough of those to fill the bar, common English words
    /// behind them.
    public var idleCandidates: [String] {
        guard layout == .english else {
            var seen = Set(pinnedKeywords)
            return pinnedKeywords + CommonPhrases.bangla.filter { seen.insert($0).inserted }
        }

        let english = pinnedKeywords.filter { !Self.usesBengaliScript($0) }
        guard english.count < 3 else { return english }

        var result = english
        for word in EnglishSuggestionService.idleWords {
            guard result.count < 3 else { break }
            guard !result.contains(where: { $0.caseInsensitiveCompare(word) == .orderedSame }) else { continue }
            result.append(word)
        }
        return result
    }

    /// Whether a keyword needs Bengali script. A mixed keyword counts as
    /// Bengali, so English mode never surfaces one.
    private static func usesBengaliScript(_ keyword: String) -> Bool {
        keyword.unicodeScalars.contains { (0x0980...0x09FF).contains($0.value) }
    }

    /// Exact Bengali chunk currently inserted in the host document for the
    /// active composition. Direct-commit model: the host document is the
    /// display surface (no `setMarkedText`), so every keystroke deletes this
    /// many graphemes and inserts the new transliteration.
    public var committedBengali: String = ""

    public init(
        layout: Layout = LayoutStore.current(),
        mode: TypingMode = TypingModeStore.current(),
        theme: KeyboardThemeID = ThemeStore.current(),
        heightOption: KeyboardHeightOption = KeyboardHeightStore.current(),
        showCharacterPreview: Bool = CharacterPreviewStore.current(),
        spacebarSwipeEnabled: Bool = SpacebarSwipeStore.current(),
        showKeyHints: Bool = KeyHintStore.current(),
        pinnedKeywords: [String] = PinnedKeywordsStore.current()
    ) {
        self.layout = layout
        self.mode = mode
        self.theme = theme
        self.heightOption = heightOption
        self.showCharacterPreview = showCharacterPreview
        self.spacebarSwipeEnabled = spacebarSwipeEnabled
        self.showKeyHints = showKeyHints
        self.pinnedKeywords = pinnedKeywords
    }

    public struct FavouriteNotice: Equatable {
        public let id = UUID()
        public let result: PinnedKeywordsStore.AddResult
        public let keyword: String
    }

    // MARK: - Mutation helpers

    /// Apply a freshly generated suggestion to the visible state.
    ///
    /// `engineSessionActive` is riti's own answer to "am I still composing a
    /// word?". The keyboard used to infer it from the shape of the result and
    /// treat every `Suggestion::Single` as the end of a word, which dropped
    /// the composition on the first letter of any word riti has only one
    /// reading for — every vowel-initial word, `ami` included.
    public func apply(_ suggestion: Suggestion, engineSessionActive: Bool) {
        candidates = suggestion.candidates
        preEditText = suggestion.preEditText
        selectedIndex = candidates.isEmpty ? -1 : suggestion.defaultIndex
        hasActiveSession = !suggestion.candidates.isEmpty && engineSessionActive
    }

    /// Clear the suggestion bar.
    public func clearSuggestions() {
        candidates = []
        preEditText = ""
        selectedIndex = -1
        hasActiveSession = false
    }

    /// End the composition entirely: suggestion bar, latin buffer, and the
    /// record of what was inserted into the host document.
    public func resetComposing() {
        buffer = ""
        committedBengali = ""
        clearSuggestions()
    }
}
