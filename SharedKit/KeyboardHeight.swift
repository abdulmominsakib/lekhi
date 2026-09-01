//
//  KeyboardHeight.swift
//  SharedKit
//
//  Options and store for customizable keyboard height.
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
        case .compact:    return "Saves vertical screen space (~39 pt keys)"
        case .standard:   return "Default native iOS-like proportions (44 pt keys)"
        case .mediumTall: return "Slightly taller for easier reach (~47.5 pt keys)"
        case .tall:       return "Comfortable large keys (~51 pt keys)"
        case .extraTall:  return "Maximum size & thumb clearance (~55 pt keys)"
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

    /// Key height in points for standard letter/number rows.
    public var keyHeight: CGFloat {
        round(44.0 * scaleFactor * 2) / 2 // round to nearest half-point
    }

    /// Suggestion bar height in points.
    public var suggestionBarHeight: CGFloat {
        round(42.0 * max(0.92, scaleFactor * 0.96) * 2) / 2
    }

    /// Top padding above the key grid / emoji picker.
    public var topPadding: CGFloat {
        4.0
    }

    /// Bottom padding below the key grid.
    public var bottomPadding: CGFloat {
        round(6.0 * scaleFactor * 2) / 2
    }

    /// Row spacing between key rows.
    public var rowSpacing: CGFloat {
        round(6.0 * max(0.90, scaleFactor * 0.95) * 2) / 2
    }

    /// Total height for the UIInputViewController extension in portrait mode.
    public var totalHeight: CGFloat {
        let gridH = (keyHeight * 4) + (rowSpacing * 3)
        return suggestionBarHeight + topPadding + gridH + bottomPadding + 6.0
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
