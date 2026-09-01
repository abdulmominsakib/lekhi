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
public enum KeyOutcome: Equatable {
    /// Update the current marked/composing text in the document.
    case setMarkedText(String)
    /// Replace the marked text with committed text (e.g. chosen candidate + space).
    case commitText(String)
    /// Remove marked text without inserting new text.
    case unmarkText
    /// Insert this literal string at the cursor (no active marked session).
    case insert(String)
    /// Delete the previous character (no-op if cursor is at start).
    case deleteBackward
    /// Pass control to iOS to switch input modes.
    case advanceInputMode
    /// Nothing to do (e.g. shift key, layout toggle with no engine work).
    case none
}

public final class KeyRouter {

    public weak var session: InputSession?
    public var engine: LekhiEngine?

    public init(session: InputSession, engine: LekhiEngine?) {
        self.session = session
        self.engine = engine
    }

    @discardableResult
    public func route(_ action: KeyAction) -> KeyOutcome {
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
        guard let session else { return .insert(text) }
        if session.hasActiveSession {
            let chosen = resolveCurrentCandidate()
            commitAndFinish()
            return .commitText(chosen + text)
        }
        return .insert(text)
    }

    private func handleCharacter(_ c: Character) -> KeyOutcome {
        guard let session else {
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
                session.buffer = ""
                session.clearSuggestions()
            }
            session.isShifted = false
            return .insert(String(c))
        }

        guard let engine else {
            session.isShifted = false
            return .insert(String(c))
        }

        // Bengali digit substitution when no session is active.
        if !session.hasActiveSession,
           let bengali = BengaliDigitInput.bengaliDigit(for: c) {
            session.isShifted = false
            return .insert(String(bengali))
        }

        // Check if character is non-ASCII (e.g. Bengali punctuation from symbol mode).
        guard let scalar = c.unicodeScalars.first, scalar.value < 0x80 else {
            if session.hasActiveSession {
                let chosen = resolveCurrentCandidate()
                commitAndFinish()
                session.isShifted = false
                return .commitText(chosen + String(c))
            }
            session.isShifted = false
            return .insert(String(c))
        }

        // Engine produces a suggestion for the key.
        let suggestion = engine.handleKey(c)
        guard !suggestion.candidates.isEmpty else {
            // Fail closed if riti rejects a key or its context becomes invalid.
            // Leaving marked text active here would desynchronise the document
            // proxy from the engine and could make the next boundary unsafe.
            engine.finishSession()
            session.buffer = ""
            session.clearSuggestions()
            session.isShifted = false
            return .insert(String(c))
        }

        session.buffer.append(c)
        session.apply(suggestion)
        session.isShifted = false

        // Phonetic-only is returned by riti as a single suggestion while the
        // word is still composing. Keep replacing marked text until a boundary.
        if session.mode == .phoneticOnly, suggestion.isLonely {
            let text = suggestion.top.isEmpty ? String(c) : suggestion.top
            return .setMarkedText(text)
        }

        // Other lonely results are punctuation / immediately committed output.
        if suggestion.isLonely {
            let committed = suggestion.top.isEmpty ? String(c) : suggestion.top
            session.clearSuggestions()
            session.buffer = ""
            engine.finishSession()
            return .commitText(committed)
        }

        let preEdit = suggestion.preEditText.isEmpty ? (suggestion.top.isEmpty ? String(c) : suggestion.top) : suggestion.preEditText
        return .setMarkedText(preEdit)
    }

    private func handleBackspace(word: Bool) -> KeyOutcome {
        guard let session else { return .deleteBackward }

        if session.layout == .english {
            if word {
                session.buffer = ""
                session.clearSuggestions()
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

        if session.hasActiveSession {
            let suggestion = engine.backspace(word: word)
            if word {
                session.buffer = ""
            } else if !session.buffer.isEmpty {
                session.buffer.removeLast()
            }
            session.apply(suggestion)

            if session.mode == .phoneticOnly,
               !suggestion.candidates.isEmpty,
               engine.hasActiveSession {
                session.hasActiveSession = true
            }

            if suggestion.candidates.isEmpty || session.buffer.isEmpty || !engine.hasActiveSession {
                session.buffer = ""
                session.clearSuggestions()
                engine.finishSession()
                return .setMarkedText("")
            }

            let preEdit = suggestion.preEditText.isEmpty ? suggestion.top : suggestion.preEditText
            return .setMarkedText(preEdit)
        }
        return .deleteBackward
    }

    private func handleSpace() -> KeyOutcome {
        guard let session else { return .insert(" ") }
        if session.layout == .english {
            session.buffer = ""
            session.clearSuggestions()
            return .insert(" ")
        }
        if session.hasActiveSession {
            let chosen = resolveCurrentCandidate()
            commitAndFinish()
            return .commitText(chosen + " ")
        }
        return .insert(" ")
    }

    private func handleReturn() -> KeyOutcome {
        guard let session else { return .insert("\n") }
        if session.layout == .english {
            session.buffer = ""
            session.clearSuggestions()
            return .insert("\n")
        }
        if session.hasActiveSession {
            let chosen = resolveCurrentCandidate()
            commitAndFinish()
            return .commitText(chosen + "\n")
        }
        return .insert("\n")
    }

    private func handleShift() {
        session?.isShifted.toggle()
    }

    private func handleLayoutToggle() {
        guard let session else { return }
        if session.layoutMode == .letters {
            session.layoutMode = .numbers
        } else {
            session.layoutMode = .letters
        }
    }

    private func handleSymbolsToggle() {
        guard let session else { return }
        if session.layoutMode == .numbers {
            session.layoutMode = .symbols
        } else {
            session.layoutMode = .numbers
        }
    }

    private func handleEmojiToggle() {
        session?.isEmojiMode.toggle()
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

    private func commitAndFinish() {
        guard let session, let engine, session.hasActiveSession else { return }
        if session.selectedIndex >= 0 && session.selectedIndex < session.candidates.count, engine.hasActiveSession {
            _ = engine.commitCandidate(at: session.selectedIndex)
        }
        engine.finishSession()
        session.clearSuggestions()
        session.buffer = ""
    }
}
