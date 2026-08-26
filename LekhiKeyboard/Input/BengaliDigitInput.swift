//
//  BengaliDigitInput.swift
//  LekhiKeyboard
//
//  Convert ASCII digits to Bengali digits when no transliteration
//  session is active.
//

import Foundation

public enum BengaliDigitInput {

    /// Bengali digits ০–৯ indexed 0–9.
    private static let bengaliDigits: [Character] = [
        "\u{09E6}", "\u{09E7}", "\u{09E8}", "\u{09E9}", "\u{09EA}",
        "\u{09EB}", "\u{09EC}", "\u{09ED}", "\u{09EE}", "\u{09EF}"
    ]

    /// If `c` is an ASCII digit and Bengali digit mode is enabled, return its Bengali equivalent.
    public static func bengaliDigit(for c: Character) -> Character? {
        guard BengaliDigitStore.current() else { return nil }
        guard let scalar = c.unicodeScalars.first,
              scalar.value >= 0x30, scalar.value <= 0x39 else {
            return nil
        }
        return bengaliDigits[Int(scalar.value - 0x30)]
    }
}
