//
//  KeyboardTheme.swift
//  SharedKit
//
//  Design tokens & color themes for Lekhi mechanical keyboard.
//

import SwiftUI

public enum KeyboardThemeID: String, CaseIterable, Identifiable, Sendable {
    case systemAuto = "systemAuto"
    case classicLight = "classicLight"
    case darkMechanical = "darkMechanical"
    case amoledBlack = "amoledBlack"
    case retroBeige = "retroBeige"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .systemAuto:     return "System (Automatic Light/Dark)"
        case .classicLight:   return "Classic Mechanical (Light)"
        case .darkMechanical: return "Onyx Mechanical (Dark)"
        case .amoledBlack:    return "Pure AMOLED Black"
        case .retroBeige:     return "Retro 80s Beige"
        }
    }

    public var subtitle: String {
        switch self {
        case .systemAuto:     return "Automatically adapts to iOS Light or Dark Mode"
        case .classicLight:   return "Matches the tactile 3D white keycap reference design"
        case .darkMechanical: return "Sleek charcoal & dark slate mechanical aesthetic"
        case .amoledBlack:    return "Pure pitch black (#000000) for OLED battery savings & high contrast"
        case .retroBeige:     return "Vintage IBM Model M / Classic terminal feel"
        }
    }

    public func resolvedPalette(for colorScheme: ColorScheme) -> KeyboardColorPalette {
        switch self {
        case .systemAuto:
            return colorScheme == .dark ? KeyboardThemeID.darkMechanical.palette : KeyboardThemeID.classicLight.palette
        default:
            return palette
        }
    }
}

public enum ThemeStore {
    private static let key = "LekhiKeyboardTheme"

    public static func current() -> KeyboardThemeID {
        let d = AppGroup.defaults
        if let raw = d.string(forKey: key),
           let theme = KeyboardThemeID(rawValue: raw) {
            return theme
        }
        return .systemAuto
    }

    public static func set(_ theme: KeyboardThemeID) {
        AppGroup.defaults.set(theme.rawValue, forKey: key)
        postSettingsChanged()
    }
}

public struct KeyboardColorPalette {
    public let backgroundPlate: Color
    public let keyFaceTop: Color
    public let keyFaceBottom: Color
    public let keyBevelSkirt: Color
    public let keyBorder: Color
    public let keyForeground: Color
    public let keyPressedFace: Color

    public let actionKeyFaceTop: Color
    public let actionKeyFaceBottom: Color
    public let actionKeyBevelSkirt: Color
    public let actionKeyForeground: Color

    public let returnKeyFaceTop: Color
    public let returnKeyFaceBottom: Color
    public let returnKeyBevelSkirt: Color
    public let returnKeyForeground: Color
    public let returnKeyPressed: Color

    public let spacebarFace: Color
    public let spacebarBevel: Color
    public let spacebarWell: Color

    public let candidateBarBackground: Color
    public let candidateText: Color
    public let candidateSelectedFill: Color
    public let candidateDivider: Color

    public let accessoryIconColor: Color

    #if canImport(UIKit)
    public var uiBackgroundPlate: UIColor {
        UIColor(backgroundPlate)
    }
    #endif
}

public extension KeyboardThemeID {
    var palette: KeyboardColorPalette {
        switch self {
        case .systemAuto, .classicLight:
            return KeyboardColorPalette(
                backgroundPlate: Color.clear,
                keyFaceTop: Color.white,
                keyFaceBottom: Color.white,
                keyBevelSkirt: Color(red: 0.54, green: 0.56, blue: 0.60), // #8A8F99
                keyBorder: Color.black.opacity(0.08),
                keyForeground: Color(red: 0.08, green: 0.09, blue: 0.11), // #14171C
                keyPressedFace: Color(red: 0.88, green: 0.90, blue: 0.93),

                actionKeyFaceTop: Color(red: 0.68, green: 0.71, blue: 0.76), // Native iOS slate #ACB4C2
                actionKeyFaceBottom: Color(red: 0.64, green: 0.67, blue: 0.72),
                actionKeyBevelSkirt: Color(red: 0.48, green: 0.51, blue: 0.56),
                actionKeyForeground: Color(red: 0.08, green: 0.09, blue: 0.11),

                returnKeyFaceTop: Color(red: 0.0, green: 0.48, blue: 1.0), // System Electric Blue #007AFF
                returnKeyFaceBottom: Color(red: 0.0, green: 0.42, blue: 0.95),
                returnKeyBevelSkirt: Color(red: 0.0, green: 0.30, blue: 0.75),
                returnKeyForeground: Color.white,
                returnKeyPressed: Color(red: 0.0, green: 0.35, blue: 0.80),

                spacebarFace: Color.white,
                spacebarBevel: Color(red: 0.54, green: 0.56, blue: 0.60),
                spacebarWell: Color(red: 0.75, green: 0.78, blue: 0.83),

                candidateBarBackground: Color.clear,
                candidateText: Color(red: 0.08, green: 0.09, blue: 0.11),
                candidateSelectedFill: Color.black.opacity(0.08),
                candidateDivider: Color.black.opacity(0.12),

                accessoryIconColor: Color(red: 0.25, green: 0.28, blue: 0.35)
            )

        case .darkMechanical:
            return KeyboardColorPalette(
                backgroundPlate: Color.clear,
                keyFaceTop: Color(red: 0.20, green: 0.22, blue: 0.26),
                keyFaceBottom: Color(red: 0.16, green: 0.18, blue: 0.21),
                keyBevelSkirt: Color(red: 0.10, green: 0.11, blue: 0.13),
                keyBorder: Color.white.opacity(0.06),
                keyForeground: Color(red: 0.94, green: 0.96, blue: 0.98),
                keyPressedFace: Color(red: 0.14, green: 0.15, blue: 0.18),

                actionKeyFaceTop: Color(red: 0.17, green: 0.19, blue: 0.22),
                actionKeyFaceBottom: Color(red: 0.14, green: 0.15, blue: 0.18),
                actionKeyBevelSkirt: Color(red: 0.08, green: 0.09, blue: 0.11),
                actionKeyForeground: Color(red: 0.88, green: 0.91, blue: 0.95),

                returnKeyFaceTop: Color(red: 0.0, green: 0.58, blue: 1.0),
                returnKeyFaceBottom: Color(red: 0.0, green: 0.46, blue: 0.92),
                returnKeyBevelSkirt: Color(red: 0.0, green: 0.32, blue: 0.70),
                returnKeyForeground: Color.white,
                returnKeyPressed: Color(red: 0.0, green: 0.38, blue: 0.80),

                spacebarFace: Color(red: 0.20, green: 0.22, blue: 0.26),
                spacebarBevel: Color(red: 0.10, green: 0.11, blue: 0.13),
                spacebarWell: Color(red: 0.28, green: 0.31, blue: 0.37),

                candidateBarBackground: Color.clear,
                candidateText: Color(red: 0.94, green: 0.96, blue: 0.98),
                candidateSelectedFill: Color.white.opacity(0.12),
                candidateDivider: Color.white.opacity(0.10),

                accessoryIconColor: Color(red: 0.65, green: 0.70, blue: 0.78)
            )

        case .amoledBlack:
            return KeyboardColorPalette(
                backgroundPlate: Color.black, // #000000
                keyFaceTop: Color(red: 0.10, green: 0.10, blue: 0.12), // #1A1A1E
                keyFaceBottom: Color(red: 0.06, green: 0.06, blue: 0.07), // #0F0F12
                keyBevelSkirt: Color(red: 0.02, green: 0.02, blue: 0.03), // #050508
                keyBorder: Color.white.opacity(0.10),
                keyForeground: Color.white,
                keyPressedFace: Color(red: 0.18, green: 0.18, blue: 0.22),

                actionKeyFaceTop: Color(red: 0.07, green: 0.07, blue: 0.08),
                actionKeyFaceBottom: Color(red: 0.04, green: 0.04, blue: 0.05),
                actionKeyBevelSkirt: Color(red: 0.01, green: 0.01, blue: 0.02),
                actionKeyForeground: Color.white.opacity(0.95),

                returnKeyFaceTop: Color(red: 0.08, green: 0.54, blue: 1.0), // Electric Blue #158AFF
                returnKeyFaceBottom: Color(red: 0.04, green: 0.44, blue: 0.96), // #0B70F5
                returnKeyBevelSkirt: Color(red: 0.02, green: 0.30, blue: 0.70),
                returnKeyForeground: Color.white,
                returnKeyPressed: Color(red: 0.02, green: 0.36, blue: 0.82),

                spacebarFace: Color(red: 0.10, green: 0.10, blue: 0.12),
                spacebarBevel: Color(red: 0.02, green: 0.02, blue: 0.03),
                spacebarWell: Color(red: 0.20, green: 0.20, blue: 0.24),

                candidateBarBackground: Color.black,
                candidateText: Color.white,
                candidateSelectedFill: Color.white.opacity(0.16),
                candidateDivider: Color.white.opacity(0.18),

                accessoryIconColor: Color.white.opacity(0.85)
            )

        case .retroBeige:
            return KeyboardColorPalette(
                backgroundPlate: Color(red: 0.86, green: 0.83, blue: 0.78), // #DCD4C7
                keyFaceTop: Color(red: 0.96, green: 0.94, blue: 0.90),
                keyFaceBottom: Color(red: 0.91, green: 0.88, blue: 0.83),
                keyBevelSkirt: Color(red: 0.74, green: 0.70, blue: 0.64),
                keyBorder: Color.black.opacity(0.10),
                keyForeground: Color(red: 0.22, green: 0.20, blue: 0.18),
                keyPressedFace: Color(red: 0.86, green: 0.83, blue: 0.78),

                actionKeyFaceTop: Color(red: 0.88, green: 0.85, blue: 0.80),
                actionKeyFaceBottom: Color(red: 0.83, green: 0.80, blue: 0.75),
                actionKeyBevelSkirt: Color(red: 0.68, green: 0.64, blue: 0.58),
                actionKeyForeground: Color(red: 0.22, green: 0.20, blue: 0.18),

                returnKeyFaceTop: Color(red: 0.90, green: 0.35, blue: 0.15), // Retro Orange/Amber
                returnKeyFaceBottom: Color(red: 0.80, green: 0.28, blue: 0.10),
                returnKeyBevelSkirt: Color(red: 0.60, green: 0.18, blue: 0.05),
                returnKeyForeground: Color.white,
                returnKeyPressed: Color(red: 0.72, green: 0.24, blue: 0.08),

                spacebarFace: Color(red: 0.96, green: 0.94, blue: 0.90),
                spacebarBevel: Color(red: 0.74, green: 0.70, blue: 0.64),
                spacebarWell: Color(red: 0.88, green: 0.85, blue: 0.80),

                candidateBarBackground: Color(red: 0.86, green: 0.83, blue: 0.78),
                candidateText: Color(red: 0.20, green: 0.18, blue: 0.16),
                candidateSelectedFill: Color.black.opacity(0.08),
                candidateDivider: Color.black.opacity(0.12),

                accessoryIconColor: Color(red: 0.45, green: 0.40, blue: 0.36)
            )
        }
    }
}
