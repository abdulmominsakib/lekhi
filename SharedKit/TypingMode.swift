//
//  TypingMode.swift
//  SharedKit
//
//  The three typing behaviours supported by Lekho, matching the
//  macOS upstream's TypingMode enum.
//

import Foundation

public enum TypingMode: String, CaseIterable, Identifiable, Sendable {
    /// Dictionary, autocorrect, and emoji suggestions; the engine's
    /// top-ranked candidate is selected/committed by default.
    case smart

    /// The full suggestion list is shown, but the literal phonetic
    /// transliteration is selected/committed by default unless the
    /// user has a remembered selection. This is the recommended
    /// default — predictable output, dictionary on tap.
    case phoneticFirst

    /// A single phonetic transliteration committed inline — no
    /// candidate popup, no autocorrect, no emoji.
    case phoneticOnly

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .smart:         return "Smart"
        case .phoneticFirst: return "Phonetic First"
        case .phoneticOnly:  return "Phonetic Only"
        }
    }

    public var subtitle: String {
        switch self {
        case .smart:
            return "Dictionary wins. Top suggestion is committed automatically."
        case .phoneticFirst:
            return "Phonetic output by default; tap a suggestion to use a dictionary word."
        case .phoneticOnly:
            return "Pure phonetic typing. No suggestions, no autocorrect."
        }
    }

    /// Whether this mode shows the candidate suggestion bar.
    public var showsSuggestionBar: Bool {
        self != .phoneticOnly
    }
}

// MARK: - Persistence

public enum TypingModeStore {
    private static let key = "LekhiTypingMode"
    private static let legacyKey = "LekhiPhoneticOnlyMode"

    public static func current() -> TypingMode {
        let d = AppGroup.defaults
        if let raw = d.string(forKey: key),
           let mode = TypingMode(rawValue: raw) {
            return mode
        }
        // Legacy migration: phonetic-only users keep their setting.
        if d.bool(forKey: legacyKey) { return .phoneticOnly }
        return .phoneticFirst
    }

    public static func set(_ mode: TypingMode) {
        AppGroup.defaults.set(mode.rawValue, forKey: key)
        postSettingsChanged()
    }
}

public enum LayoutStore {
    private static let key = "LekhiLayout"

    public static func current() -> Layout {
        let raw = AppGroup.defaults.string(forKey: key) ?? Layout.avroPhonetic.rawValue
        return Layout(rawValue: raw) ?? .avroPhonetic
    }

    public static func set(_ layout: Layout) {
        AppGroup.defaults.set(layout.rawValue, forKey: key)
        postSettingsChanged()
    }
}
