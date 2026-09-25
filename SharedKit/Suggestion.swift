//
//  Suggestion.swift
//  SharedKit
//
//  Plain-Swift value type representing a single engine result.
//  Independent of the riti FFI to keep SwiftUI views decoupled.
//

import Foundation

/// What the engine returned for a key press.
public struct Suggestion: Equatable, Sendable {
    /// Ordered list of candidate strings. May contain a single
    /// element (the "lonely" case) when the engine is in
    /// phonetic-only mode.
    public let candidates: [String]

    /// Auxiliary / pre-edit text (for displaying the typed buffer).
    public let preEditText: String

    /// Index of the candidate that should be selected by default.
    /// For `.phoneticFirst` this is the index of the literal
    /// phonetic output; for `.smart` it is always 0.
    public let defaultIndex: Int

    /// `true` when the engine returned only a single candidate and
    /// the caller should commit it inline rather than show a bar.
    public let isLonely: Bool

    public init(
        candidates: [String],
        preEditText: String = "",
        defaultIndex: Int = 0,
        isLonely: Bool = false
    ) {
        self.candidates = candidates
        self.preEditText = preEditText
        self.defaultIndex = max(0, min(defaultIndex, max(0, candidates.count - 1)))
        self.isLonely = isLonely
    }

    public static let empty = Suggestion(candidates: [])

    /// Most candidates the bar lists for one word. The bar scrolls, so this is
    /// about keeping the list useful, not about fitting it on screen.
    public static let maxBarCount = 12

    /// Top candidate, or empty string if there are none.
    public var top: String { candidates.first ?? "" }

    /// Up to three candidates to display in the suggestion bar.
    public var topThree: [String] {
        Array(candidates.prefix(3))
    }
}
