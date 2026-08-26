//
//  LekhiEngine.swift
//  SharedKit
//
//  Abstraction over the transliteration engine. The keyboard
//  extension depends only on this protocol; the FFI-backed
//  implementation lives in `RitiEngine.swift`.
//

import Foundation

public protocol LekhiEngine: AnyObject {
    /// Process a single character key press and return the new
    /// candidate list / pre-edit text.
    func handleKey(_ character: Character) -> Suggestion

    /// Backspace event. If `ctrl` is true the whole word is
    /// removed and the input session ends.
    func backspace(word: Bool) -> Suggestion

    /// The user tapped the candidate at `index` in the suggestion
    /// bar. Subsequent key events will continue from the committed
    /// candidate.
    func commitCandidate(at index: Int) -> Suggestion

    /// Finish the current input session without committing. Called
    /// when the user moves the cursor away or deletes everything.
    func finishSession()

    /// Whether there is an active transliteration session.
    var hasActiveSession: Bool { get }

    /// Clean up engine resources.
    func teardown()
}

public extension LekhiEngine {

    func backspace() -> Suggestion { backspace(word: false) }

    func commitCandidate(at index: Int) -> Suggestion {
        commitCandidate(at: index)
    }
}

/// Factory for the default engine implementation.
public enum LekhiEngineFactory {

    /// Create a riti-backed engine. Returns `nil` if the bundle
    /// resources are missing or the FFI cannot be initialised.
    public static func make(layout: Layout, mode: TypingMode) -> LekhiEngine? {
        return RitiEngine(layout: layout, mode: mode)
    }
}
