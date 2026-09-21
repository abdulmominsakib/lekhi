//
//  ComposingHistory.swift
//  LekhiKeyboard
//
//  What the word being composed has already put in the host document, and the
//  one question the keyboard asks it: "is this context still mine?"
//

import Foundation

/// Every Bengali chunk the current composition has put in the document,
/// oldest first.
///
/// `documentContextBeforeInput` lags the keyboard's own edits, and how far it
/// lags depends on how quickly the host app answers. Typing fast, the change
/// callback for one keystroke arrives after the next keystroke has already
/// moved the composition on, so the context still ends with an *earlier* chunk
/// of the same word. Read as "the host rewrote the text", that tore the
/// composition down mid-word — the engine restarted on the next letter, so
/// conjuncts and suggestions broke exactly when typing was fastest, and
/// whether it happened at all came down to how quickly the host answered.
///
/// Matching a reported context against everything this word has displayed is
/// what tells the keyboard's own lagging edits apart from a real external
/// change (a cursor move, host autocorrect, dictation).
public struct ComposingHistory: Equatable {

    /// A word never shows more shapes than it has letters, so this cap is only
    /// here to stop a pathological composition growing without bound.
    public static let limit = 16

    public private(set) var chunks: [String] = []

    public init() {}

    /// Note the chunk now on screen. An empty chunk means the composition
    /// ended, so the record goes with it.
    public mutating func record(_ chunk: String) {
        guard !chunk.isEmpty else {
            chunks.removeAll()
            return
        }
        guard chunks.last != chunk else { return }
        chunks.append(chunk)
        if chunks.count > Self.limit {
            chunks.removeFirst()
        }
    }

    public mutating func reset() {
        chunks.removeAll()
    }

    /// Whether `contextBeforeInput` ends with something this composition put
    /// there — the chunk currently on screen, or an earlier one the host has
    /// not finished reporting.
    public func recognises(_ contextBeforeInput: String) -> Bool {
        chunks.contains { contextBeforeInput.hasSuffix($0) }
    }
}
