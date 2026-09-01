//
//  Theme.swift
//  LekhiKeyboard
//
//  Visual constants for the Lekhi keyboard UI. Precisely sized to match
//  the 3D mechanical keyboard design: rounded white keys on a soft gray
//  background, physical 3D bevel skirts, electric blue Return key, and
//  clean typography.
//

import SwiftUI

public enum Theme {

    // MARK: - Active Palette

    public static var palette: KeyboardColorPalette {
        ThemeStore.current().palette
    }

    // MARK: - Legacy / Dynamic Proxies

    public static var background: Color { palette.backgroundPlate }
    public static var keyFace: Color { palette.keyFaceTop }
    public static var keyBorder: Color { palette.keyBorder }
    public static var keyForeground: Color { palette.keyForeground }
    public static var keyPressed: Color { palette.keyPressedFace }
    public static var keyFaceDark: Color { palette.actionKeyFaceTop }

    public static var returnKeyFace: Color { palette.returnKeyFaceTop }
    public static var returnKeyForeground: Color { palette.returnKeyForeground }
    public static var returnKeyPressed: Color { palette.returnKeyPressed }

    public static var selectionFill: Color { palette.candidateSelectedFill }
    public static var divider: Color { palette.candidateDivider }

    // MARK: - Mechanical Metrics

    /// Smooth rounded squircle corner radius matching the reference image.
    public static let keyCornerRadius: CGFloat = 9.5

    /// Physical 3D bevel skirt height (gives keycaps their raised mechanical profile).
    public static let bevelHeight: CGFloat = 3.5

    /// Depression offset when a key is physically tapped down.
    public static let pressedDepression: CGFloat = 2.0

    public static let rowSpacing: CGFloat = 6.0
    public static let keySpacing: CGFloat = 5.0
    public static let sideInset: CGFloat = 5.0
    public static let bottomInset: CGFloat = 6.0

    public static let keyHeight: CGFloat = 44.0
    public static let suggestionBarHeight: CGFloat = 42.0

    /// Total keyboard height on Portrait iPhone (~220-260 pt).
    public static let keyboardHeight: CGFloat = 260.0

    // MARK: - Typography

    /// Clean, crisp letter glyphs matching the reference image ("q w e r t").
    public static let letterFont: Font = .system(size: 22, weight: .regular, design: .default)

    /// Action key labels & icons (shift, backspace, return, 123).
    public static let actionFont: Font = .system(size: 16, weight: .medium, design: .default)

    /// Candidate labels in the suggestion bar.
    public static let candidateFont: Font = .system(size: 17, weight: .medium, design: .default)
    public static let rawCandidateFont: Font = .system(size: 16, weight: .regular, design: .default)
}
