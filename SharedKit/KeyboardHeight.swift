//
//  KeyboardHeight.swift
//  SharedKit
//
//  Options and store for customizable keyboard height.
//
//  The "standard" numbers are measured off the reference design:
//  a 1608 x 1368 px keyboard drawn for a 393 pt wide iPhone, i.e.
//  4.0916 px per point. Cap 177 px (43.3 pt), skirt 26 px (6.4 pt),
//  gap between rows 12 px (2.9 pt), candidate bar 198 px (48.4 pt).
//

import SwiftUI

public enum KeyboardHeightOption: String, CaseIterable, Identifiable, Sendable {
    case compact = "compact"
    case standard = "standard"
    case mediumTall = "mediumTall"
    case tall = "tall"
    case extraTall = "extraTall"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .compact:    return "Compact (Short)"
        case .standard:   return "Standard (Default)"
        case .mediumTall: return "Medium Tall"
        case .tall:       return "Tall"
        case .extraTall:  return "Extra Tall"
        }
    }

    public var subtitle: String {
        switch self {
        case .compact:    return "Saves vertical screen space (~38 pt keys)"
        case .standard:   return "Matches the reference design (43.5 pt keys)"
        case .mediumTall: return "Slightly taller for easier reach (~47 pt keys)"
        case .tall:       return "Comfortable large keys (~50.5 pt keys)"
        case .extraTall:  return "Maximum size & thumb clearance (~54.5 pt keys)"
        }
    }

    public var scaleFactor: CGFloat {
        switch self {
        case .compact:    return 0.88
        case .standard:   return 1.00
        case .mediumTall: return 1.08
        case .tall:       return 1.16
        case .extraTall:  return 1.25
        }
    }

    private static func halfPoint(_ value: CGFloat) -> CGFloat {
        (value * 2).rounded() / 2
    }

    /// Height of the drawn keycap face (excludes the bevel skirt below it).
    public var keyHeight: CGFloat {
        Self.halfPoint(43.5 * scaleFactor)
    }

    /// Height of the bevel skirt drawn under each cap; part of the key body.
    public var keySkirt: CGFloat {
        Self.halfPoint(6.5 * scaleFactor)
    }

    /// Full drawn height of one key: cap + skirt.
    public var keyBodyHeight: CGFloat {
        keyHeight + keySkirt
    }

    /// Candidate bar height.
    public var suggestionBarHeight: CGFloat {
        Self.halfPoint(48.0 * max(0.92, scaleFactor * 0.97))
    }

    /// Gap above the key grid.
    public var topPadding: CGFloat { 2.0 }

    /// Gap below the last key row, before the system accessory row.
    public var bottomPadding: CGFloat {
        Self.halfPoint(5.0 * scaleFactor)
    }

    /// Vertical gap between key rows — the design leaves just enough room
    /// for each cap's drop shadow.
    public var rowSpacing: CGFloat {
        Self.halfPoint(3.0 * max(0.9, scaleFactor))
    }

    /// Height of the four-row key grid, skirts included.
    public var gridHeight: CGFloat {
        (keyBodyHeight * 4) + (rowSpacing * 3)
    }

    // MARK: - Emoji panel (Apple-like: 4 visible rows)

    /// Columns across the emoji grid (Apple uses ~8 on iPhone).
    public var emojiColumnCount: Int { 8 }

    /// Visible emoji rows in the first viewport (Apple shows four).
    public var emojiVisibleRowCount: Int { 4 }

    /// Glyph size inside each cell.
    public var emojiFontSize: CGFloat {
        Self.halfPoint(34 * scaleFactor)
    }

    /// Fixed row height so four rows fill the viewport cleanly.
    public var emojiRowHeight: CGFloat {
        Self.halfPoint(48 * scaleFactor)
    }

    public var emojiRowSpacing: CGFloat {
        Self.halfPoint(2 * scaleFactor)
    }

    /// Exact height of the scroll viewport for four emoji rows.
    public var emojiGridViewportHeight: CGFloat {
        let rows = CGFloat(emojiVisibleRowCount)
        return (emojiRowHeight * rows) + (emojiRowSpacing * (rows - 1))
    }

    public var emojiSearchBarHeight: CGFloat {
        Self.halfPoint(40 * max(0.95, scaleFactor))
    }

    public var emojiCategoryBarHeight: CGFloat {
        Self.halfPoint(40 * max(0.95, scaleFactor))
    }

    /// Full emoji keyboard height: search + 4-row grid + category strip.
    public func emojiPanelHeight(safeAreaBottom: CGFloat = 0) -> CGFloat {
        let chromeSpacing: CGFloat = 12 // search↔grid↔category gaps + outer padding
        return emojiSearchBarHeight
            + emojiGridViewportHeight
            + emojiCategoryBarHeight
            + chromeSpacing
            + safeAreaBottom
    }

    /// Height to request for the input view.
    ///
    /// The candidate bar is only drawn in modes that have candidates, so it
    /// must not be reserved in `.phoneticOnly` — otherwise the keyboard
    /// carries a strip of dead plate. `safeAreaBottom` covers the home
    /// indicator on iOS versions that do not hand custom keyboards their own
    /// accessory row (iOS 26 does, and reports a zero inset there).
    public func totalHeight(showsSuggestionBar: Bool, safeAreaBottom: CGFloat = 0) -> CGFloat {
        let bar = showsSuggestionBar ? suggestionBarHeight : 0
        return bar + topPadding + gridHeight + bottomPadding + safeAreaBottom
    }
}

public enum KeyboardHeightStore {
    private static let key = "LekhiKeyboardHeightOption"

    public static func current() -> KeyboardHeightOption {
        let d = AppGroup.defaults
        if let raw = d.string(forKey: key),
           let option = KeyboardHeightOption(rawValue: raw) {
            return option
        }
        return .standard
    }

    public static func set(_ option: KeyboardHeightOption) {
        AppGroup.defaults.set(option.rawValue, forKey: key)
        postSettingsChanged()
    }
}
