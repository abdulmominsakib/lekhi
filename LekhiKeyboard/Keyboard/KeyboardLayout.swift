//
//  KeyboardLayout.swift
//  LekhiKeyboard
//
//  Static description of the mechanical keyboard rows and layout modes.
//
//  Row shapes follow the reference design, where every row spans the full
//  plate width: the home row widens its outer two caps (220 px vs 143 px)
//  rather than being inset, and the bottom row is mode | space | return.
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

    /// Total width of the row in "letter key" units.
    public var totalWeight: CGFloat {
        keys.reduce(0) { $0 + $1.widthWeight }
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
    /// Keys that absorb whatever width is left over once the fixed-width keys
    /// have been laid out — only the spacebar, in practice.
    public let isFlexible: Bool

    public init(
        id: String? = nil,
        label: String,
        bengaliHint: String? = nil,
        kind: KeyKind,
        action: KeyAction,
        widthWeight: CGFloat? = nil,
        isFlexible: Bool = false
    ) {
        self.id = id ?? label
        self.label = label
        self.bengaliHint = bengaliHint
        self.kind = kind
        self.action = action
        self.widthWeight = widthWeight ?? kind.widthMultiplier
        self.isFlexible = isFlexible || kind.isSpace
    }
}

public enum KeyboardLayoutMode {
    case letters
    case numbers
    case symbols
}

/// Host text field keyboard type, mapped from `UITextDocumentProxy.keyboardType`.
public enum HostKeyboardContext: Equatable, Sendable {
    case standard
    /// Digits only (PIN / numberPad / asciiCapableNumberPad).
    case numberPad
    /// Digits with phone punctuation (* # +).
    case phonePad
    /// Digits with decimal separator.
    case decimalPad
    /// Full numbers & punctuation page (system "numbers and punctuation").
    case numbersAndPunctuation
    /// Email address — letters with @ and . on the bottom row.
    case email

    public var isDigitPad: Bool {
        switch self {
        case .numberPad, .phonePad, .decimalPad: return true
        default: return false
        }
    }

    /// Force ASCII digit insertion (no Bengali substitution).
    public var forcesASCIIDigits: Bool {
        switch self {
        case .numberPad, .phonePad, .decimalPad, .numbersAndPunctuation:
            return true
        default:
            return false
        }
    }
}

public enum KeyboardLayoutFactory {

    /// Width of the home row's outer caps, in letter-key units.
    /// Design: 220 px against a 143 px letter cap.
    private static let homeRowEdgeWeight: CGFloat = 1.538

    private static let avroHints: [Character: String] = [
        "q": "ক", "w": "ও", "e": "এ", "r": "র", "t": "ত",
        "y": "য়", "u": "উ", "i": "ই", "o": "ও", "p": "প",
        "a": "আ", "s": "স", "d": "দ", "f": "ফ", "g": "গ",
        "h": "হ", "j": "জ", "k": "ক", "l": "ল", "z": "য",
        "x": "ক্স", "c": "চ", "v": "ভ", "b": "ব", "n": "ন", "m": "ম"
    ]

    private static let probhatHints: [Character: String] = [
        "q": "দ", "w": "ূ", "e": "ী", "r": "র", "t": "ট",
        "y": "এ", "u": "ু", "i": "ি", "o": "ো", "p": "প",
        "a": "া", "s": "স", "d": "ড", "f": "ত", "g": "গ",
        "h": "হ", "j": "জ", "k": "ক", "l": "ল", "z": "য়",
        "x": "শ", "c": "চ", "v": "আ", "b": "ব", "n": "ন", "m": "ম"
    ]

    /// Four rows: q-p / a-l / shift z-m backspace / 123 space return
    public static func letters(
        isShifted: Bool,
        layout: Layout,
        showsGlobeKey: Bool,
        hostContext: HostKeyboardContext = .standard
    ) -> [KeyRow] {
        let top = letterRow(
            rowId: "letters-row-0",
            letters: "qwertyuiop",
            shifted: isShifted,
            layout: layout
        )
        var middle = letterRow(
            rowId: "letters-row-1",
            letters: "asdfghjkl",
            shifted: isShifted,
            layout: layout
        )
        middle = widenEdges(of: middle)
        let bottom = shiftRow(rowId: "letters-row-2", shifted: isShifted, layout: layout)
        let pads: KeyRow = {
            switch hostContext {
            case .email:
                return emailBottomRow(rowId: "letters-row-3", showsGlobeKey: showsGlobeKey)
            default:
                return bottomRow(
                    rowId: "letters-row-3",
                    modeLabel: "123",
                    modeAction: .switchLayout,
                    showsGlobeKey: showsGlobeKey
                )
            }
        }()

        return [top, middle, bottom, pads]
    }

    /// System-style number / phone / decimal pad (3×4), not the full 123 page.
    public static func digitPad(
        style: HostKeyboardContext,
        layout: Layout,
        showsGlobeKey: Bool
    ) -> [KeyRow] {
        let useBengaliLabels = layout != .english && BengaliDigitStore.current()
        let digitLabels = useBengaliLabels
            ? Array("১২৩৪৫৬৭৮৯০")
            : Array("1234567890")
        // Actions always ASCII; KeyRouter forces ASCII insert for digit pads.
        let digitActions = Array("1234567890")

        func padKey(id: String, label: String, action: KeyAction, kind: KeyKind = .letter) -> KeyDescriptor {
            KeyDescriptor(id: id, label: label, kind: kind, action: action, isFlexible: true)
        }

        func digit(_ index: Int) -> KeyDescriptor {
            // Labels for 1…9 use indices 0…8; 0 uses index 9.
            padKey(
                id: "pad-\(digitActions[index])",
                label: String(digitLabels[index]),
                action: .character(digitActions[index])
            )
        }

        let row1 = KeyRow(id: "pad-row-0", keys: [digit(0), digit(1), digit(2)])
        let row2 = KeyRow(id: "pad-row-1", keys: [digit(3), digit(4), digit(5)])
        let row3 = KeyRow(id: "pad-row-2", keys: [digit(6), digit(7), digit(8)])

        let bottomLeft: KeyDescriptor = {
            switch style {
            case .decimalPad:
                return padKey(id: "pad-decimal", label: ".", action: .character("."))
            case .phonePad:
                return padKey(id: "pad-star", label: "*", action: .character("*"))
            case .numberPad:
                if showsGlobeKey {
                    return padKey(id: "pad-globe", label: "globe", action: .nextKeyboard, kind: .globe)
                }
                return padKey(id: "pad-blank", label: "", action: .noop, kind: .action)
            default:
                return padKey(id: "pad-blank", label: "", action: .noop, kind: .action)
            }
        }()

        let bottomRight: KeyDescriptor = {
            switch style {
            case .phonePad:
                // Prefer delete for correcting mistypes (* is on the left).
                return padKey(id: "pad-backspace", label: "⌫", action: .backspace(word: false), kind: .action)
            default:
                return padKey(id: "pad-backspace", label: "⌫", action: .backspace(word: false), kind: .action)
            }
        }()

        // Phone: * 0 ⌫ (hash available via long-form punctuation if needed later)
        // Number: (blank|globe) 0 ⌫
        // Decimal: . 0 ⌫
        let row4 = KeyRow(id: "pad-row-3", keys: [bottomLeft, digit(9), bottomRight])
        return [row1, row2, row3, row4]
    }

    /// Numbers and punctuation ("123").
    ///
    /// Avro/Probhat show Bengali digit labels when the Bengali numerals setting
    /// is on; key actions stay ASCII `0`–`9` so `BengaliDigitInput` can convert.
    public static func numbers(showsGlobeKey: Bool, layout: Layout) -> [KeyRow] {
        let useBengaliLabels = layout != .english && BengaliDigitStore.current()
        let labels = useBengaliLabels ? "১২৩৪৫৬৭৮৯০" : "1234567890"
        let actions = "1234567890"
        let row1 = KeyRow(id: "numbers-row-0", keys: zip(labels, actions).enumerated().map { i, pair in
            let (label, action) = pair
            return KeyDescriptor(
                id: "num-\(i)-\(action)",
                label: String(label),
                kind: .letter,
                action: .character(action)
            )
        })
        let row2 = KeyRow(
            id: "numbers-row-1",
            keys: letterRow(rowId: "numbers-row-1", letters: "-/:;()$&@\"", shifted: false)
                .keys
                .map { key in
                    // Avro spells the visarga with `:`, but a Bengali typist
                    // reaching for that key wants the sign itself — দুঃখিত,
                    // not দু:খিত. English keeps the ASCII colon.
                    guard layout != .english, key.label == ":" else { return key }
                    return KeyDescriptor(
                        id: key.id,
                        label: "ঃ",
                        kind: .letter,
                        action: .character("ঃ")
                    )
                }
        )
        let row3 = KeyRow(id: "numbers-row-2", keys: [
            KeyDescriptor(id: "num-sym-toggle", label: "#+=", kind: .action, action: .switchSymbols, widthWeight: 2.6),
            KeyDescriptor(id: "num-dot", label: ".", kind: .letter, action: .character(".")),
            KeyDescriptor(id: "num-comma", label: ",", kind: .letter, action: .character(",")),
            KeyDescriptor(id: "num-question", label: "?", kind: .letter, action: .character("?")),
            KeyDescriptor(id: "num-exclaim", label: "!", kind: .letter, action: .character("!")),
            KeyDescriptor(id: "num-quote", label: "'", kind: .letter, action: .character("'")),
            KeyDescriptor(id: "num-backspace", label: "⌫", kind: .action, action: .backspace(word: false), widthWeight: 2.6)
        ])
        let pads = bottomRow(
            rowId: "numbers-row-3",
            modeLabel: "ABC",
            modeAction: .switchLayout,
            showsGlobeKey: showsGlobeKey
        )

        return [row1, row2, row3, pads]
    }

    /// Symbol mode ("#+=").
    public static func symbols(showsGlobeKey: Bool) -> [KeyRow] {
        let row1 = letterRow(rowId: "symbols-row-0", letters: "[]{}#%^*+=", shifted: false)
        let row2 = letterRow(rowId: "symbols-row-1", letters: "_\\|~<>€£¥•", shifted: false)
        let row3 = KeyRow(id: "symbols-row-2", keys: [
            KeyDescriptor(id: "sym-123-toggle", label: "123", kind: .action, action: .switchSymbols, widthWeight: 2.6),
            KeyDescriptor(id: "sym-dari", label: "।", kind: .letter, action: .character("।")), // Bangla Dari
            KeyDescriptor(id: "sym-bisarga", label: "ঃ", kind: .letter, action: .character("ঃ")), // Bisarga
            KeyDescriptor(id: "sym-anusvara", label: "ং", kind: .letter, action: .character("ং")), // Anusvara
            KeyDescriptor(id: "sym-chandrabindu", label: "ঁ", kind: .letter, action: .character("ঁ")), // Chandrabindu
            KeyDescriptor(id: "sym-quote", label: "'", kind: .letter, action: .character("'")),
            KeyDescriptor(id: "sym-backspace", label: "⌫", kind: .action, action: .backspace(word: false), widthWeight: 2.6)
        ])
        let pads = bottomRow(
            rowId: "symbols-row-3",
            modeLabel: "ABC",
            modeAction: .switchLayout,
            showsGlobeKey: showsGlobeKey
        )

        return [row1, row2, row3, pads]
    }

    // MARK: - Helpers

    /// Stretch a nine-key row out to the full plate width by widening its
    /// outer caps, the way the design draws the home row.
    private static func widenEdges(of row: KeyRow) -> KeyRow {
        guard row.keys.count > 2 else { return row }
        var keys = row.keys
        keys[0] = resized(keys[0], to: homeRowEdgeWeight)
        keys[keys.count - 1] = resized(keys[keys.count - 1], to: homeRowEdgeWeight)
        return KeyRow(id: row.id, keys: keys)
    }

    private static func resized(_ key: KeyDescriptor, to weight: CGFloat) -> KeyDescriptor {
        KeyDescriptor(
            id: key.id,
            label: key.label,
            bengaliHint: key.bengaliHint,
            kind: key.kind,
            action: key.action,
            widthWeight: weight,
            isFlexible: key.isFlexible
        )
    }

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

    /// Apple-style email bottom row: 123 | @ | space | . | return (+ globe when needed).
    private static func emailBottomRow(rowId: String, showsGlobeKey: Bool) -> KeyRow {
        var keys: [KeyDescriptor] = [
            KeyDescriptor(id: "\(rowId)-mode", label: "123", kind: .action, action: .switchLayout, widthWeight: 1.75)
        ]
        if showsGlobeKey {
            keys.append(
                KeyDescriptor(id: "\(rowId)-globe", label: "globe", kind: .globe, action: .nextKeyboard, widthWeight: 1.15)
            )
        }
        keys.append(
            KeyDescriptor(id: "\(rowId)-at", label: "@", kind: .letter, action: .character("@"), widthWeight: 1.15)
        )
        keys.append(
            KeyDescriptor(id: "\(rowId)-space", label: "space", kind: .space, action: .space, isFlexible: true)
        )
        keys.append(
            KeyDescriptor(id: "\(rowId)-dot", label: ".", kind: .letter, action: .character("."), widthWeight: 1.15)
        )
        keys.append(
            KeyDescriptor(id: "\(rowId)-return", label: "↵", kind: .return, action: .return, widthWeight: 2.0)
        )
        return KeyRow(id: rowId, keys: keys)
    }

    /// The design's bottom row is mode | space | return. The globe is only
    /// added when iOS says this keyboard has to provide its own input-mode
    /// switcher — on iOS versions that draw a system globe below the
    /// keyboard, including one here would be a duplicate.
    private static func bottomRow(
        rowId: String,
        modeLabel: String,
        modeAction: KeyAction,
        showsGlobeKey: Bool
    ) -> KeyRow {
        var keys: [KeyDescriptor] = [
            KeyDescriptor(id: "\(rowId)-mode", label: modeLabel, kind: .action, action: modeAction, widthWeight: 1.75)
        ]
        if showsGlobeKey {
            keys.append(
                KeyDescriptor(id: "\(rowId)-globe", label: "globe", kind: .globe, action: .nextKeyboard, widthWeight: 1.25)
            )
        }
        keys.append(
            KeyDescriptor(id: "\(rowId)-emoji", label: "emoji", kind: .emoji, action: .emoji, widthWeight: 1.25)
        )
        keys.append(
            KeyDescriptor(id: "\(rowId)-space", label: "space", kind: .space, action: .space, isFlexible: true)
        )
        keys.append(
            KeyDescriptor(id: "\(rowId)-return", label: "↵", kind: .return, action: .return, widthWeight: 2.2)
        )
        return KeyRow(id: rowId, keys: keys)
    }
}
