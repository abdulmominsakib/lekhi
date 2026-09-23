//
//  KeyRouter.swift
//  LekhiKeyboard
//
//  Interprets a `KeyAction` against the current engine + session
//  and mutates both. Pure logic — no UIKit / no SwiftUI.
//

import Foundation

/// Outcome of routing a `KeyAction`. The view controller uses
/// this to decide what to insert into the text document proxy.
///
/// Direct-commit model: the keyboard keeps the latin buffer and the
/// already-inserted Bengali chunk (`InputSession.committedBengali`) as its
/// own source of truth and syncs to the host document using only
/// `insertText` / `deleteBackward` — never `setMarkedText`, which most real
/// host apps (Messages, Safari, Chrome, …) ignore or mishandle.
public enum KeyOutcome: Equatable {
    /// Delete `deleteCount` times before the cursor, then insert `insert`.
    /// `deleteCount` counts `deleteBackward()` calls — Unicode scalars, not
    /// grapheme clusters (see `DocumentEdit.deletionSteps(for:)`). `insert`
    /// may be empty (pure deletion, e.g. backspace-to-empty).
    case replaceComposing(deleteCount: Int, insert: String)
    /// Insert this literal string at the cursor (no active marked session).
    case insert(String)
    /// Delete the previous character (no-op if cursor is at start).
    case deleteBackward
    /// Pass control to iOS to switch input modes.
    case advanceInputMode
    /// Nothing to do in the document (e.g. shift key, or the newly computed
    /// Bengali chunk is identical to what is already displayed).
    case none
}

/// Translating a string into `UITextDocumentProxy` edits.
public enum DocumentEdit {

    /// Number of `deleteBackward()` calls needed to remove `text` from a host
    /// document.
    ///
    /// The proxy deletes one Unicode *scalar*, so a Bengali base letter and
    /// its vowel sign — "বা", a single Swift `Character` but two scalars —
    /// needs two calls. Counting `String.count` removed only the vowel sign
    /// and left the base letter behind, so every re-render of a composing word
    /// stacked another copy of its stem in the document: `bangla` came out as
    /// "বববাবাংলা".
    ///
    /// Emoji are the exception: the system removes a whole emoji cluster in
    /// one call. Recognising them by the emoji-presentation property alone
    /// missed keycaps such as 1️⃣ — a plain digit, U+FE0F and U+20E3, none of
    /// which has that property — so replacing one took three deletes and
    /// swallowed the two characters before it.
    public static func deletionSteps(for text: String) -> Int {
        var steps = 0
        for character in text {
            let scalars = character.unicodeScalars
            if scalars.count == 1 || RitiEngine.isEmoji(String(character)) {
                steps += 1
            } else {
                steps += scalars.count
            }
        }
        return steps
    }

    /// The smallest edit that turns `old` into `new` at the cursor.
    ///
    /// Most keystrokes only append to the transliteration, so diffing off the
    /// shared prefix usually means inserting one mark and deleting nothing —
    /// far less churn in the host document than deleting and re-inserting the
    /// whole word on every key.
    ///
    /// The comparison runs in Unicode scalars, the same unit the text proxy
    /// edits in. Mixing units here is silently destructive: `commonPrefix(with:)`
    /// matches scalars while `dropFirst` drops grapheme clusters, so
    /// "বাংল" -> "বাংলা" reported a four-long shared prefix and then dropped
    /// all four of the new string's *clusters*, leaving nothing to insert — the
    /// final vowel sign never reached the document.
    public static func replacement(from old: String, to new: String) -> KeyOutcome {
        guard old != new else { return .none }

        let oldScalars = Array(old.unicodeScalars)
        let newScalars = Array(new.unicodeScalars)
        var shared = 0
        while shared < oldScalars.count,
              shared < newScalars.count,
              oldScalars[shared] == newScalars[shared] {
            shared += 1
        }

        let removed = String(String.UnicodeScalarView(oldScalars[shared...]))
        let added = String(String.UnicodeScalarView(newScalars[shared...]))
        guard !removed.isEmpty || !added.isEmpty else { return .none }
        return .replaceComposing(deleteCount: deletionSteps(for: removed), insert: added)
    }
}

public final class KeyRouter {

    public weak var session: InputSession?

    /// Resolved on demand: the engine is built off the main thread so the
    /// keyboard can present immediately, and the first key press waits for it
    /// rather than the whole keyboard waiting on start-up.
    private let engineProvider: () -> LekhiEngine?

    private var engine: LekhiEngine? { engineProvider() }

    public init(session: InputSession, engineProvider: @escaping () -> LekhiEngine?) {
        self.session = session
        self.engineProvider = engineProvider
    }

    public convenience init(session: InputSession, engine: LekhiEngine?) {
        self.init(session: session, engineProvider: { engine })
    }

    @discardableResult
    public func route(_ action: KeyAction) -> KeyOutcome {
        // Caps lock latches on two *consecutive* shift taps, like the system
        // keyboard: anything struck in between closes the window. Without this
        // the window was simply "two shift taps inside 0.35 s", which a fast
        // typist hits by accident — shift, letter, shift is under 0.35 s from
        // roughly 70 WPM — and in Avro phonetic a stuck caps lock silently
        // changes every following letter (`s` -> স but `S` -> শ).
        if action != .shift {
            lastShiftTap = nil
        }

        switch action {
        case .character(let c):        return handleCharacter(c)
        case .insertText(let s):       return handleInsertText(s)
        case .backspace(let word):     return handleBackspace(word: word)
        case .space:                   return handleSpace()
        case .return:                  return handleReturn()
        case .shift:                   handleShift(); return .none
        case .switchLayout:            handleLayoutToggle(); return .none
        case .switchSymbols:           handleSymbolsToggle(); return .none
        case .nextKeyboard:            return .advanceInputMode
        case .emoji:                   handleEmojiToggle(); return .none
        case .mic:                     return .none
        case .noop:                    return .none
        }
    }

    // MARK: - Handlers

    private func handleInsertText(_ text: String) -> KeyOutcome {
        // The chosen Bengali chunk is already in the document via
        // direct-commit; just close the engine session and append.
        if session?.hasActiveSession == true {
            commitAndFinish()
        }
        return .insert(text)
    }

    private func handleCharacter(_ c: Character) -> KeyOutcome {
        guard let session else {
            return .insert(String(c))
        }

        // The ঃ key sends the finished sign, but in Avro the visarga is a
        // letter of the word being spelled (`du:kho` -> দুঃখ). Treated as
        // punctuation it ended the composition, so দুঃখ came out as দুঃ
        // followed by a separate word খো. Hand it to the engine as Avro's `:`
        // instead and the word carries on through it, the way Ridmik does.
        if c == "ঃ", session.layout == .avroPhonetic, !session.isEmojiSearchActive,
           !session.isNumericHostField, engine != nil {
            return handleCharacter(":")
        }

        // Emoji search: letter keys feed the query, not the host field.
        if session.isEmojiSearchActive {
            if c.isNewline {
                return .none
            }
            session.emojiSearchQuery.append(c)
            consumeShift(session)
            return .none
        }

        // Numeric host fields always need ASCII digits (and decimal punctuation).
        if session.isNumericHostField {
            if session.hasActiveSession {
                if session.layout == .english {
                    session.resetComposing()
                } else {
                    commitAndFinish()
                }
            }
            consumeShift(session)
            return .insert(String(c))
        }

        // English layout typing: generate live English suggestions
        if session.layout == .english {
            if c.isLetter || c.isNumber || c == "'" {
                session.buffer.append(c)
                let suggestions = EnglishSuggestionService.suggestions(for: session.buffer)
                session.candidates = suggestions
                session.selectedIndex = suggestions.isEmpty ? -1 : 0
                session.hasActiveSession = !suggestions.isEmpty
            } else {
                session.resetComposing()
            }
            consumeShift(session)
            return .insert(String(c))
        }

        guard let engine else {
            consumeShift(session)
            return .insert(String(c))
        }

        // Bengali digit substitution when no session is active.
        if !session.hasActiveSession,
           let bengali = BengaliDigitInput.bengaliDigit(for: c) {
            consumeShift(session)
            return .insert(String(bengali))
        }

        // Check if character is non-ASCII (e.g. Bengali punctuation from symbol mode).
        guard let scalar = c.unicodeScalars.first, scalar.value < 0x80 else {
            if session.hasActiveSession {
                // Chosen chunk is already displayed; freeze and append.
                commitAndFinish()
            }
            consumeShift(session)
            return .insert(String(c))
        }

        // Engine produces a suggestion for the key.
        let suggestion = engine.handleKey(c)
        guard !suggestion.candidates.isEmpty else {
            // Fail closed if riti rejects a key or its context becomes invalid.
            // Previously inserted Bengali stays; just insert the raw key.
            engine.finishSession()
            session.resetComposing()
            consumeShift(session)
            return .insert(String(c))
        }

        session.buffer.append(c)
        session.apply(suggestion, engineSessionActive: engine.hasActiveSession)
        consumeShift(session)

        // riti returns Suggestion::Single both for a word still being composed
        // that happens to have a single reading, and for a character it
        // commits inline (punctuation). Only the second ends riti's input
        // session, so that — not the shape of the result — is what marks an
        // inline commit. They are NOT a re-render of the composing word, so
        // don't delete the displayed chunk, unless the committed text already
        // includes it as a prefix, in which case replace to avoid duplication.
        if suggestion.isLonely, session.mode != .phoneticOnly, !engine.hasActiveSession {
            let lonely = suggestion.top.isEmpty ? String(c) : suggestion.top
            let old = session.committedBengali
            engine.finishSession()
            session.buffer = ""
            session.committedBengali = ""
            session.clearSuggestions()
            if !old.isEmpty, lonely.hasPrefix(old) {
                return DocumentEdit.replacement(from: old, to: lonely)
            }
            return .insert(lonely)
        }

        // Live re-render: replace the previously inserted chunk with the new
        // transliteration. Skip the document edit when nothing changed.
        let newText = resolveCurrentCandidate()
        let old = session.committedBengali
        let text = newText.isEmpty ? String(c) : newText
        session.committedBengali = text
        return DocumentEdit.replacement(from: old, to: text)
    }

    private func handleBackspace(word: Bool) -> KeyOutcome {
        guard let session else { return .deleteBackward }

        if session.isEmojiSearchActive {
            if word {
                session.emojiSearchQuery = ""
            } else if !session.emojiSearchQuery.isEmpty {
                session.emojiSearchQuery.removeLast()
            }
            return .none
        }

        if session.layout == .english {
            if word {
                session.resetComposing()
            } else if !session.buffer.isEmpty {
                session.buffer.removeLast()
                if session.buffer.isEmpty {
                    session.clearSuggestions()
                } else {
                    let suggestions = EnglishSuggestionService.suggestions(for: session.buffer)
                    session.candidates = suggestions
                    session.selectedIndex = suggestions.isEmpty ? -1 : 0
                    session.hasActiveSession = !suggestions.isEmpty
                }
            } else {
                session.clearSuggestions()
            }
            return .deleteBackward
        }

        guard let engine else { return .deleteBackward }

        // No active composition: single grapheme passthrough.
        guard session.hasActiveSession else { return .deleteBackward }

        if word {
            // Whole-word delete: remove the entire composing chunk.
            let old = session.committedBengali
            _ = engine.backspace(word: true)
            engine.finishSession()
            session.resetComposing()
            guard !old.isEmpty else { return .deleteBackward }
            return .replaceComposing(deleteCount: DocumentEdit.deletionSteps(for: old), insert: "")
        }

        let suggestion = engine.backspace(word: false)
        if !session.buffer.isEmpty {
            session.buffer.removeLast()
        }
        session.apply(suggestion, engineSessionActive: engine.hasActiveSession)

        if suggestion.candidates.isEmpty || session.buffer.isEmpty || !engine.hasActiveSession {
            // Composition emptied: delete the displayed chunk.
            let old = session.committedBengali
            engine.finishSession()
            session.resetComposing()
            guard !old.isEmpty else { return .none }
            return .replaceComposing(deleteCount: DocumentEdit.deletionSteps(for: old), insert: "")
        }

        let newText = resolveCurrentCandidate()
        let old = session.committedBengali
        let text = newText.isEmpty ? session.buffer : newText
        session.committedBengali = text
        return DocumentEdit.replacement(from: old, to: text)
    }

    private func handleSpace() -> KeyOutcome {
        if session?.isEmojiSearchActive == true {
            session?.emojiSearchQuery.append(" ")
            return .none
        }
        finishCompositionBeforeSeparator()
        return .insert(" ")
    }

    private func handleReturn() -> KeyOutcome {
        if session?.isEmojiSearchActive == true {
            // Keep searching; return does not insert a newline into the host.
            return .none
        }
        finishCompositionBeforeSeparator()
        return .insert("\n")
    }

    /// Space and Return end the word. The composing chunk is already in the
    /// document under the direct-commit model, so this only freezes state.
    private func finishCompositionBeforeSeparator() {
        guard let session else { return }
        if session.layout == .english {
            session.resetComposing()
        } else if session.hasActiveSession {
            commitAndFinish()
        }
    }

    /// Tapping shift toggles it for one character; tapping it again inside
    /// the double-tap window, with nothing struck in between, latches caps
    /// lock, matching the system keyboard.
    /// Without this there was no way to type two capitals in a row, which
    /// matters in Avro phonetic where case selects a different letter
    /// (`s` -> স but `S` -> শ).
    private var lastShiftTap: Date?

    private func handleShift() {
        guard let session else { return }
        let now = Date()

        if session.isCapsLocked {
            session.isCapsLocked = false
            session.isShifted = false
        } else if let last = lastShiftTap, now.timeIntervalSince(last) < 0.35 {
            session.isCapsLocked = true
            session.isShifted = false
        } else {
            session.isShifted.toggle()
        }
        lastShiftTap = now
    }

    /// Drop the one-shot shift after a character, but leave caps lock alone.
    private func consumeShift(_ session: InputSession) {
        if !session.isCapsLocked {
            session.isShifted = false
        }
    }

    private func handleLayoutToggle() {
        guard let session else { return }
        // System digit pads have no ABC / 123 toggle.
        guard !session.hostKeyboardContext.isDigitPad else { return }
        if session.layoutMode == .letters {
            session.layoutMode = .numbers
        } else {
            session.layoutMode = .letters
        }
    }

    private func handleSymbolsToggle() {
        guard let session else { return }
        guard !session.hostKeyboardContext.isDigitPad else { return }
        if session.layoutMode == .numbers {
            session.layoutMode = .symbols
        } else {
            session.layoutMode = .numbers
        }
    }

    private func handleEmojiToggle() {
        guard let session else { return }
        guard !session.hostKeyboardContext.isDigitPad else { return }
        if session.isEmojiMode {
            session.isEmojiMode = false
        } else {
            // Entering the emoji panel from letters or emoji-search.
            session.clearEmojiSearch()
            session.isEmojiMode = true
        }
    }

    public func resolveCurrentCandidate() -> String {
        guard let session else { return "" }
        if session.selectedIndex >= 0 && session.selectedIndex < session.candidates.count {
            return session.candidates[session.selectedIndex]
        }
        if !session.preEditText.isEmpty {
            return session.preEditText
        }
        if let first = session.candidates.first {
            return first
        }
        return session.buffer
    }

    /// Freeze the word being composed. Its text is already in the document.
    ///
    /// This only ends riti's session. Reporting the default as a committed
    /// candidate would teach riti a "user choice" for every word the keyboard
    /// defaulted to on its own — in `.phoneticFirst` that is nearly every word,
    /// each one a write of riti's selections file — and those remembered picks
    /// would then override the dictionary if the user switches to `.smart`.
    /// Only an explicit tap in the suggestion bar teaches riti.
    private func commitAndFinish() {
        guard let session, let engine, session.hasActiveSession else { return }
        engine.finishSession()
        session.resetComposing()
    }
}
