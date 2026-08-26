//
//  KeyboardLayout.swift
//  LekhiKeyboard
//
//  Static description of the mechanical keyboard rows and layout modes.
//

import Foundation

/// One row of keys in the mechanical layout.
public struct KeyRow: Identifiable {
    public let id = UUID()
    public var keys: [KeyDescriptor]

    public init(keys: [KeyDescriptor]) {
        self.keys = keys
    }
}

/// Description of a single key.
public struct KeyDescriptor: Identifiable {
    public let id = UUID()
    public let label: String
    public let bengaliHint: String?
    public let kind: KeyKind
    public let action: KeyAction
    public let widthWeight: CGFloat

    public init(
        label: String,
        bengaliHint: String? = nil,
        kind: KeyKind,
        action: KeyAction,
        widthWeight: CGFloat? = nil
    ) {
        self.label = label
        self.bengaliHint = bengaliHint
        self.kind = kind
        self.action = action
        self.widthWeight = widthWeight ?? kind.widthMultiplier
    }
}

public enum KeyboardLayoutMode {
    case letters
    case numbers
    case symbols
}

public enum KeyboardLayoutFactory {

    /// Four rows: q-p / a-l / shift z-m backspace / 123 space return
    public static func letters(isShifted: Bool) -> [KeyRow] {
        let top    = letterRow("qwertyuiop", shifted: isShifted)
        let middle = letterRow("asdfghjkl",  shifted: isShifted)
        let bottom = shiftRow(shifted: isShifted)
        let pads   = bottomRow(modeLabel: "123", modeAction: .switchLayout)
        
        return [top, middle, bottom, pads]
    }

    /// Numbers and punctuation ("123").
    public static func numbers() -> [KeyRow] {
        let row1 = KeyRow(keys: "1234567890".map {
            KeyDescriptor(label: String($0), kind: .letter, action: .character($0))
        })
        let row2 = letterRow("-/:;()$&@\"", shifted: false)
        let row3 = KeyRow(keys: [
            KeyDescriptor(label: "#+=", kind: .action, action: .switchSymbols, widthWeight: 2.75),
            KeyDescriptor(label: ".", kind: .letter, action: .character(".")),
            KeyDescriptor(label: ",", kind: .letter, action: .character(",")),
            KeyDescriptor(label: "?", kind: .letter, action: .character("?")),
            KeyDescriptor(label: "!", kind: .letter, action: .character("!")),
            KeyDescriptor(label: "'", kind: .letter, action: .character("'")),
            KeyDescriptor(label: "⌫", kind: .action, action: .backspace(word: false), widthWeight: 2.75)
        ])
        let pads = numberBottomRow(modeLabel: "ABC", modeAction: .switchLayout)

        return [row1, row2, row3, pads]
    }

    /// Symbol mode ("#+=").
    public static func symbols() -> [KeyRow] {
        let row1 = letterRow("[]{}#%^*+=", shifted: false)
        let row2 = letterRow("_\\|~<>€£¥•", shifted: false)
        let row3 = KeyRow(keys: [
            KeyDescriptor(label: "123", kind: .action, action: .switchSymbols, widthWeight: 2.75),
            KeyDescriptor(label: "।", kind: .letter, action: .character("।")), // Bangla Dari
            KeyDescriptor(label: "ঃ", kind: .letter, action: .character("ঃ")), // Bisarga
            KeyDescriptor(label: "ং", kind: .letter, action: .character("ং")), // Anusvara
            KeyDescriptor(label: "ঁ", kind: .letter, action: .character("ঁ")), // Chandrabindu
            KeyDescriptor(label: "'", kind: .letter, action: .character("'")),
            KeyDescriptor(label: "⌫", kind: .action, action: .backspace(word: false), widthWeight: 2.75)
        ])
        let pads = numberBottomRow(modeLabel: "ABC", modeAction: .switchLayout)

        return [row1, row2, row3, pads]
    }

    // MARK: - Helpers

    private static func letterRow(_ letters: String, shifted: Bool) -> KeyRow {
        let chars = shifted ? letters.uppercased() : letters
        let keys = chars.map { ch in
            KeyDescriptor(label: String(ch), kind: .letter, action: .character(ch))
        }
        return KeyRow(keys: keys)
    }

    private static func shiftRow(shifted: Bool) -> KeyRow {
        let shift = KeyDescriptor(
            label: "⇧",
            kind: .action,
            action: .shift
        )
        let backspace = KeyDescriptor(
            label: "⌫",
            kind: .action,
            action: .backspace(word: false)
        )
        return KeyRow(keys:
            [shift] +
            letterRow("zxcvbnm", shifted: shifted).keys +
            [backspace]
        )
    }

    private static func bottomRow(modeLabel: String, modeAction: KeyAction) -> KeyRow {
        KeyRow(keys: [
            KeyDescriptor(label: modeLabel, kind: .action, action: modeAction, widthWeight: 1.45),
            KeyDescriptor(label: "space", kind: .space, action: .space, widthWeight: 6.75),
            KeyDescriptor(label: "↵", kind: .return, action: .return, widthWeight: 1.8)
        ])
    }

    private static func numberBottomRow(modeLabel: String, modeAction: KeyAction) -> KeyRow {
        KeyRow(keys: [
            KeyDescriptor(label: modeLabel, kind: .action, action: modeAction, widthWeight: 1.45),
            KeyDescriptor(label: "😊", kind: .emoji, action: .emoji, widthWeight: 1.45),
            KeyDescriptor(label: "space", kind: .space, action: .space, widthWeight: 5.3),
            KeyDescriptor(label: "↵", kind: .return, action: .return, widthWeight: 1.8)
        ])
    }
}
