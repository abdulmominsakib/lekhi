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
    /// Bright rim around the outside of a keycap face.
    public let keyFaceTop: Color
    /// Bottom of the concave dish inside the cap.
    public let keyFaceBottom: Color
    /// Top of the concave dish inside the cap (the design's soft shading).
    public let keyDishTop: Color
    public let keyBevelSkirt: Color
    public let keyBorder: Color
    public let keyForeground: Color
    public let keyPressedFace: Color
    /// Colour of the soft drop shadow each cap casts on the plate.
    public let keyShadow: Color

    public let actionKeyFaceTop: Color
    public let actionKeyFaceBottom: Color
    public let actionKeyDishTop: Color
    public let actionKeyBevelSkirt: Color
    public let actionKeyForeground: Color

    public let returnKeyFaceTop: Color
    public let returnKeyFaceBottom: Color
    public let returnKeyDishTop: Color
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
            // Plate #E0E0E0 (matches the iOS keyboard container). Keycap rim
            // #FFFFFF over a dish that runs #F0F0F0 -> #FCFCFC, glyphs #4B4B4B,
            // and the single blue Return at #319AF7 over a #027FED skirt.
            return KeyboardColorPalette(
                backgroundPlate: Color(red: 0.878, green: 0.878, blue: 0.878),   // #E0E0E0
                keyFaceTop: Color.white,
                keyFaceBottom: Color(red: 0.996, green: 0.996, blue: 0.996),     // #FEFEFE
                keyDishTop: Color(red: 0.925, green: 0.925, blue: 0.929),        // #ECECED
                keyBevelSkirt: Color(red: 0.855, green: 0.855, blue: 0.863),     // #DADADC
                keyBorder: Color.black.opacity(0.035),
                keyForeground: Color(red: 0.294, green: 0.294, blue: 0.294),     // #4B4B4B
                keyPressedFace: Color(red: 0.898, green: 0.906, blue: 0.918),
                keyShadow: Color.black.opacity(0.16),

                // The design keeps every key white — only Return is coloured.
                actionKeyFaceTop: Color.white,
                actionKeyFaceBottom: Color(red: 0.992, green: 0.992, blue: 0.992),
                actionKeyDishTop: Color(red: 0.922, green: 0.922, blue: 0.925),
                actionKeyBevelSkirt: Color(red: 0.847, green: 0.847, blue: 0.855),
                actionKeyForeground: Color(red: 0.329, green: 0.329, blue: 0.341),

                returnKeyFaceTop: Color(red: 0.208, green: 0.624, blue: 0.976),  // #359FF9
                returnKeyFaceBottom: Color(red: 0.161, green: 0.584, blue: 0.949),
                returnKeyDishTop: Color(red: 0.145, green: 0.569, blue: 0.945),
                returnKeyBevelSkirt: Color(red: 0.008, green: 0.498, blue: 0.929), // #027FED
                returnKeyForeground: Color.white,
                returnKeyPressed: Color(red: 0.086, green: 0.482, blue: 0.851),

                spacebarFace: Color.white,
                spacebarBevel: Color(red: 0.855, green: 0.855, blue: 0.863),
                spacebarWell: Color(red: 0.824, green: 0.831, blue: 0.847),

                candidateBarBackground: Color.clear,
                candidateText: Color(red: 0.05, green: 0.05, blue: 0.06),
                candidateSelectedFill: Color.black.opacity(0.07),
                candidateDivider: Color.black.opacity(0.13),

                accessoryIconColor: Color(red: 0.333, green: 0.353, blue: 0.443) // #555A71
            )

        case .darkMechanical:
            return KeyboardColorPalette(
                backgroundPlate: Color(red: 0.098, green: 0.098, blue: 0.102),   // #19191A
                keyFaceTop: Color(red: 0.255, green: 0.275, blue: 0.318),
                keyFaceBottom: Color(red: 0.212, green: 0.231, blue: 0.271),
                keyDishTop: Color(red: 0.176, green: 0.192, blue: 0.227),
                keyBevelSkirt: Color(red: 0.098, green: 0.106, blue: 0.125),
                keyBorder: Color.white.opacity(0.05),
                keyForeground: Color(red: 0.941, green: 0.960, blue: 0.980),
                keyPressedFace: Color(red: 0.153, green: 0.165, blue: 0.196),
                keyShadow: Color.black.opacity(0.45),

                actionKeyFaceTop: Color(red: 0.212, green: 0.231, blue: 0.271),
                actionKeyFaceBottom: Color(red: 0.180, green: 0.196, blue: 0.231),
                actionKeyDishTop: Color(red: 0.153, green: 0.169, blue: 0.200),
                actionKeyBevelSkirt: Color(red: 0.086, green: 0.094, blue: 0.110),
                actionKeyForeground: Color(red: 0.878, green: 0.910, blue: 0.949),

                returnKeyFaceTop: Color(red: 0.145, green: 0.596, blue: 1.0),
                returnKeyFaceBottom: Color(red: 0.075, green: 0.518, blue: 0.949),
                returnKeyDishTop: Color(red: 0.055, green: 0.490, blue: 0.918),
                returnKeyBevelSkirt: Color(red: 0.016, green: 0.325, blue: 0.706),
                returnKeyForeground: Color.white,
                returnKeyPressed: Color(red: 0.0, green: 0.380, blue: 0.800),

                spacebarFace: Color(red: 0.255, green: 0.275, blue: 0.318),
                spacebarBevel: Color(red: 0.098, green: 0.106, blue: 0.125),
                spacebarWell: Color(red: 0.310, green: 0.337, blue: 0.396),

                candidateBarBackground: Color.clear,
                candidateText: Color(red: 0.941, green: 0.960, blue: 0.980),
                candidateSelectedFill: Color.white.opacity(0.13),
                candidateDivider: Color.white.opacity(0.14),

                accessoryIconColor: Color(red: 0.651, green: 0.698, blue: 0.780)
            )

        case .amoledBlack:
            return KeyboardColorPalette(
                backgroundPlate: Color.black,
                keyFaceTop: Color(red: 0.129, green: 0.129, blue: 0.149),
                keyFaceBottom: Color(red: 0.098, green: 0.098, blue: 0.114),
                keyDishTop: Color(red: 0.071, green: 0.071, blue: 0.086),
                keyBevelSkirt: Color(red: 0.027, green: 0.027, blue: 0.035),
                keyBorder: Color.white.opacity(0.09),
                keyForeground: Color.white,
                keyPressedFace: Color(red: 0.196, green: 0.196, blue: 0.227),
                keyShadow: Color.black.opacity(0.7),

                actionKeyFaceTop: Color(red: 0.102, green: 0.102, blue: 0.118),
                actionKeyFaceBottom: Color(red: 0.078, green: 0.078, blue: 0.090),
                actionKeyDishTop: Color(red: 0.055, green: 0.055, blue: 0.067),
                actionKeyBevelSkirt: Color(red: 0.020, green: 0.020, blue: 0.027),
                actionKeyForeground: Color.white.opacity(0.95),

                returnKeyFaceTop: Color(red: 0.082, green: 0.541, blue: 1.0),
                returnKeyFaceBottom: Color(red: 0.043, green: 0.439, blue: 0.961),
                returnKeyDishTop: Color(red: 0.035, green: 0.412, blue: 0.918),
                returnKeyBevelSkirt: Color(red: 0.020, green: 0.298, blue: 0.702),
                returnKeyForeground: Color.white,
                returnKeyPressed: Color(red: 0.020, green: 0.361, blue: 0.820),

                spacebarFace: Color(red: 0.129, green: 0.129, blue: 0.149),
                spacebarBevel: Color(red: 0.027, green: 0.027, blue: 0.035),
                spacebarWell: Color(red: 0.216, green: 0.216, blue: 0.251),

                candidateBarBackground: Color.black,
                candidateText: Color.white,
                candidateSelectedFill: Color.white.opacity(0.16),
                candidateDivider: Color.white.opacity(0.18),

                accessoryIconColor: Color.white.opacity(0.85)
            )

        case .retroBeige:
            return KeyboardColorPalette(
                backgroundPlate: Color(red: 0.855, green: 0.827, blue: 0.776),
                keyFaceTop: Color(red: 0.980, green: 0.965, blue: 0.937),
                keyFaceBottom: Color(red: 0.961, green: 0.941, blue: 0.906),
                keyDishTop: Color(red: 0.910, green: 0.886, blue: 0.843),
                keyBevelSkirt: Color(red: 0.804, green: 0.776, blue: 0.725),
                keyBorder: Color.black.opacity(0.08),
                keyForeground: Color(red: 0.267, green: 0.243, blue: 0.216),
                keyPressedFace: Color(red: 0.878, green: 0.851, blue: 0.804),
                keyShadow: Color(red: 0.25, green: 0.20, blue: 0.13).opacity(0.24),

                actionKeyFaceTop: Color(red: 0.976, green: 0.957, blue: 0.925),
                actionKeyFaceBottom: Color(red: 0.949, green: 0.925, blue: 0.886),
                actionKeyDishTop: Color(red: 0.898, green: 0.871, blue: 0.824),
                actionKeyBevelSkirt: Color(red: 0.788, green: 0.757, blue: 0.702),
                actionKeyForeground: Color(red: 0.298, green: 0.271, blue: 0.243),

                returnKeyFaceTop: Color(red: 0.902, green: 0.396, blue: 0.184),
                returnKeyFaceBottom: Color(red: 0.851, green: 0.341, blue: 0.137),
                returnKeyDishTop: Color(red: 0.824, green: 0.322, blue: 0.125),
                returnKeyBevelSkirt: Color(red: 0.639, green: 0.208, blue: 0.063),
                returnKeyForeground: Color.white,
                returnKeyPressed: Color(red: 0.722, green: 0.243, blue: 0.082),

                spacebarFace: Color(red: 0.980, green: 0.965, blue: 0.937),
                spacebarBevel: Color(red: 0.804, green: 0.776, blue: 0.725),
                spacebarWell: Color(red: 0.878, green: 0.851, blue: 0.804),

                candidateBarBackground: Color.clear,
                candidateText: Color(red: 0.200, green: 0.180, blue: 0.160),
                candidateSelectedFill: Color.black.opacity(0.07),
                candidateDivider: Color.black.opacity(0.13),

                accessoryIconColor: Color(red: 0.451, green: 0.400, blue: 0.357)
            )
        }
    }
}
