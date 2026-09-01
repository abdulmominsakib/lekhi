//
//  KeyboardLayout.swift
//  LekhiKeyboard
//
//  Static description of the mechanical keyboard rows and layout modes.
//

import Foundation

/// One row of keys in the mechanical layout.
public struct KeyRow: Identifiable {
    public let id: String
    public var keys: [KeyDescriptor]

    public init(id: String, keys: [KeyDescriptor]) {
        self.id = id
        self.keys = keys
    }
}

/// Description of a single key.
public struct KeyDescriptor: Identifiable {
    public let id: String
    public let label: String
    public let bengaliHint: String?
    public let kind: KeyKind
    public let action: KeyAction
    public let widthWeight: CGFloat

    public init(
        id: String? = nil,
        label: String,
        bengaliHint: String? = nil,
        kind: KeyKind,
        action: KeyAction,
        widthWeight: CGFloat? = nil
    ) {
        self.id = id ?? label
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

    private static let avroHints: [Character: String] = [
        "q": "ক", "w": "ও", "e": "এ", "r": "র", "t": "ত",
        "y": "য়", "u": "উ", "i": "ই", "o": "ও", "p": "প",
        "a": "আ", "s": "স", "d": "দ", "f": "ফ", "g": "গ",
        "h": "হ", "j": "জ", "k": "ক", "l": "ল", "z": "য",
        "x": "ক্স", "c": "চ", "v": "ভ", "b": "ব", "n": "ন", "m": "ম"
    ]

    private static let probhatHints: [Character: String] = [
        "q": "দ", "w": "ূ", "e": "ী", "r": "র", "t": "ট",
        "y": "এ", "u": "ু", "i": "ি", "o": "ো", "p": "প",
        "a": "া", "s": "স", "d": "ড", "f": "ত", "g": "গ",
        "h": "হ", "j": "জ", "k": "ক", "l": "ল", "z": "য়",
        "x": "শ", "c": "চ", "v": "আ", "b": "ব", "n": "ন", "m": "ম"
    ]

    /// Four rows: q-p / a-l / shift z-m backspace / 123 space return
    public static func letters(isShifted: Bool, layout: Layout) -> [KeyRow] {
        let top = letterRow(
            rowId: "letters-row-0",
            letters: "qwertyuiop",
            shifted: isShifted,
            layout: layout
        )
        let middle = letterRow(
            rowId: "letters-row-1",
            letters: "asdfghjkl",
            shifted: isShifted,
            layout: layout
        )
        let bottom = shiftRow(rowId: "letters-row-2", shifted: isShifted, layout: layout)
        let pads   = bottomRow(rowId: "letters-row-3", modeLabel: "123", modeAction: .switchLayout)
        
        return [top, middle, bottom, pads]
    }

    /// Numbers and punctuation ("123").
    public static func numbers() -> [KeyRow] {
        let row1 = KeyRow(id: "numbers-row-0", keys: "1234567890".enumerated().map { i, ch in
            KeyDescriptor(id: "num-\(i)-\(ch)", label: String(ch), kind: .letter, action: .character(ch))
        })
        let row2 = letterRow(rowId: "numbers-row-1", letters: "-/:;()$&@\"", shifted: false)
        let row3 = KeyRow(id: "numbers-row-2", keys: [
            KeyDescriptor(id: "num-sym-toggle", label: "#+=", kind: .action, action: .switchSymbols, widthWeight: 2.75),
            KeyDescriptor(id: "num-dot", label: ".", kind: .letter, action: .character(".")),
            KeyDescriptor(id: "num-comma", label: ",", kind: .letter, action: .character(",")),
            KeyDescriptor(id: "num-question", label: "?", kind: .letter, action: .character("?")),
            KeyDescriptor(id: "num-exclaim", label: "!", kind: .letter, action: .character("!")),
            KeyDescriptor(id: "num-quote", label: "'", kind: .letter, action: .character("'")),
            KeyDescriptor(id: "num-backspace", label: "⌫", kind: .action, action: .backspace(word: false), widthWeight: 2.75)
        ])
        let pads = numberBottomRow(rowId: "numbers-row-3", modeLabel: "ABC", modeAction: .switchLayout)

        return [row1, row2, row3, pads]
    }

    /// Symbol mode ("#+=").
    public static func symbols() -> [KeyRow] {
        let row1 = letterRow(rowId: "symbols-row-0", letters: "[]{}#%^*+=", shifted: false)
        let row2 = letterRow(rowId: "symbols-row-1", letters: "_\\|~<>€£¥•", shifted: false)
        let row3 = KeyRow(id: "symbols-row-2", keys: [
            KeyDescriptor(id: "sym-123-toggle", label: "123", kind: .action, action: .switchSymbols, widthWeight: 2.75),
            KeyDescriptor(id: "sym-dari", label: "।", kind: .letter, action: .character("।")), // Bangla Dari
            KeyDescriptor(id: "sym-bisarga", label: "ঃ", kind: .letter, action: .character("ঃ")), // Bisarga
            KeyDescriptor(id: "sym-anusvara", label: "ং", kind: .letter, action: .character("ং")), // Anusvara
            KeyDescriptor(id: "sym-chandrabindu", label: "ঁ", kind: .letter, action: .character("ঁ")), // Chandrabindu
            KeyDescriptor(id: "sym-quote", label: "'", kind: .letter, action: .character("'")),
            KeyDescriptor(id: "sym-backspace", label: "⌫", kind: .action, action: .backspace(word: false), widthWeight: 2.75)
        ])
        let pads = numberBottomRow(rowId: "symbols-row-3", modeLabel: "ABC", modeAction: .switchLayout)

        return [row1, row2, row3, pads]
    }

    // MARK: - Helpers

    private static func letterRow(
        rowId: String,
        letters: String,
        shifted: Bool,
        layout: Layout? = nil
    ) -> KeyRow {
        let chars = shifted ? letters.uppercased() : letters
        let keys = chars.enumerated().map { i, ch in
            let hintKey = Character(String(ch).lowercased())
            let hint: String? = {
                switch layout {
                case .some(.avroPhonetic): return avroHints[hintKey]
                case .some(.probhat): return probhatHints[hintKey]
                case .some(.english), .none: return nil
                }
            }()
            return KeyDescriptor(
                id: "\(rowId)-\(i)",
                label: String(ch),
                bengaliHint: hint,
                kind: .letter,
                action: .character(ch)
            )
        }
        return KeyRow(id: rowId, keys: keys)
    }

    private static func shiftRow(rowId: String, shifted: Bool, layout: Layout) -> KeyRow {
        let shift = KeyDescriptor(
            id: "\(rowId)-shift",
            label: "⇧",
            kind: .action,
            action: .shift
        )
        let backspace = KeyDescriptor(
            id: "\(rowId)-backspace",
            label: "⌫",
            kind: .action,
            action: .backspace(word: false)
        )
        return KeyRow(
            id: rowId,
            keys: [shift] + letterRow(
                rowId: "\(rowId)-letters",
                letters: "zxcvbnm",
                shifted: shifted,
                layout: layout
            ).keys + [backspace]
        )
    }

    private static func bottomRow(rowId: String, modeLabel: String, modeAction: KeyAction) -> KeyRow {
        KeyRow(id: rowId, keys: [
            KeyDescriptor(id: "\(rowId)-mode", label: modeLabel, kind: .action, action: modeAction, widthWeight: 1.35),
            KeyDescriptor(id: "\(rowId)-globe", label: "globe", kind: .globe, action: .nextKeyboard, widthWeight: 0.95),
            KeyDescriptor(id: "\(rowId)-emoji", label: "emoji", kind: .emoji, action: .emoji, widthWeight: 0.95),
            KeyDescriptor(id: "\(rowId)-space", label: "space", kind: .space, action: .space, widthWeight: 4.95),
            KeyDescriptor(id: "\(rowId)-return", label: "↵", kind: .return, action: .return, widthWeight: 1.8)
        ])
    }

    private static func numberBottomRow(rowId: String, modeLabel: String, modeAction: KeyAction) -> KeyRow {
        KeyRow(id: rowId, keys: [
            KeyDescriptor(id: "\(rowId)-mode", label: modeLabel, kind: .action, action: modeAction, widthWeight: 1.35),
            KeyDescriptor(id: "\(rowId)-globe", label: "globe", kind: .globe, action: .nextKeyboard, widthWeight: 0.95),
            KeyDescriptor(id: "\(rowId)-emoji", label: "emoji", kind: .emoji, action: .emoji, widthWeight: 0.95),
            KeyDescriptor(id: "\(rowId)-space", label: "space", kind: .space, action: .space, widthWeight: 4.95),
            KeyDescriptor(id: "\(rowId)-return", label: "↵", kind: .return, action: .return, widthWeight: 1.8)
        ])
    }
}
