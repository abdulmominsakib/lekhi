//
//  Layout.swift
//  SharedKit
//
//  Phonetic keyboard layouts supported by Lekho. The user picks one
//  in Settings; the keyboard rebuilds its engine on switch.
//

import Foundation

public enum Layout: String, CaseIterable, Identifiable, Sendable {
    /// Direct English typing (bypasses transliteration engine).
    case english

    /// Avro Phonetic — the default. `ami` → আমি, `bangla` → বাংলা.
    case avroPhonetic

    /// Probhat — alternative phonetic layout.
    case probhat

    public var id: String { rawValue }

    /// The layout name passed to `riti_config_set_layout_file()`.
    public var ritiLayoutName: String {
        switch self {
        case .english, .avroPhonetic: return "avro_phonetic"
        case .probhat:                return "probhat"
        }
    }

    public var displayName: String {
        switch self {
        case .english:      return "English"
        case .avroPhonetic: return "Avro Phonetic"
        case .probhat:      return "Probhat"
        }
    }

    /// Short label displayed on the spacebar keycap.
    public var spacebarLabel: String {
        switch self {
        case .english:      return "English"
        case .avroPhonetic: return "বাংলা (Avro)"
        case .probhat:      return "বাংলা (প্রভাত)"
        }
    }

    public var subtitle: String {
        switch self {
        case .english:
            return "Standard Latin QWERTY input without transliteration."
        case .avroPhonetic:
            return "ami → আমি — the classic Avro phonetic layout."
        case .probhat:
            return "Probhat phonetic layout from the data folder."
        }
    }
}
