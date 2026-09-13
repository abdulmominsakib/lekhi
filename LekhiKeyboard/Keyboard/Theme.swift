//
//  Theme.swift
//  LekhiKeyboard
//
//  Visual constants for the Lekhi keyboard UI, measured off the reference
//  design (1608 x 1368 px artboard drawn for a 393 pt wide iPhone, so
//  4.0916 px per point).
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

    // MARK: - Keyboard container

    /// iOS 26 draws every keyboard inside a container with rounded top
    /// corners. Earlier versions have a square, edge-to-edge keyboard.
    public static var usesRoundedContainer: Bool {
        if #available(iOS 26.0, *) { return true }
        return false
    }

    /// Top corner radius of that system container, continuous style. Measured
    /// off the stock keyboard on iOS 26 at 3x: a SwiftUI continuous corner of
    /// 30.5 pt traces the system curve to within ~2 px along its whole length.
    /// The plate uses the same shape so its corners disappear into the
    /// container instead of sticking out square.
    public static let containerCornerRadius: CGFloat = 30.5

    // MARK: - Mechanical Metrics

    /// Squircle corner radius of a keycap. Design: 25 px of a 143 px wide cap.
    public static let keyCornerRadius: CGFloat = 8.5

    /// Corner radius of the concave dish inside the cap — much rounder than
    /// the cap itself, which is what gives the design its moulded look.
    public static let keyDishCornerRadius: CGFloat = 14.0

    /// How far the dish is inset from the cap edge. Design: 20 px ≈ 5 pt on
    /// the sides, a little more at the top so the rim reads as a lip.
    public static let keyDishInsetX: CGFloat = 5.0
    public static let keyDishInsetTop: CGFloat = 5.0
    public static let keyDishInsetBottom: CGFloat = 3.5

    /// The dish is a soft moulded hollow, not a panel: blurring its edge is
    /// what separates it from a plain inset rectangle.
    public static let keyDishSoftness: CGFloat = 1.2

    /// Depression offset when a key is physically tapped down. The cap sinks
    /// into its own skirt rather than moving as a whole.
    public static let pressedDepression: CGFloat = 2.5

    /// Horizontal gap between drawn caps. Design: 12.7 px ≈ 3.1 pt.
    public static let keySpacing: CGFloat = 3.0
    /// Plate inset either side of the key grid. Design: 34 px ≈ 8.3 pt.
    public static let sideInset: CGFloat = 8.5
    public static let bottomInset: CGFloat = 5.0

    /// Extra touch area added around each drawn cap so the tight visual gaps
    /// of the design don't make the keys harder to hit than iOS's own. Half
    /// the gap on each side: neighbouring targets meet exactly, leaving
    /// neither a dead strip between keys nor an overlap that would hand part
    /// of one key's edge to its neighbour.
    public static let touchSlop: CGFloat = keySpacing / 2

    // MARK: - Typography

    /// Design: 'q' drawn at ~22 pt regular.
    public static let letterFont: Font = .system(size: 22, weight: .regular, design: .default)

    /// Action key labels ("ABC", "123", "#+=").
    public static let actionFont: Font = .system(size: 16, weight: .regular, design: .default)

    /// Candidate labels in the suggestion bar. Design: 17 pt.
    public static let candidateFont: Font = .system(size: 17, weight: .regular, design: .default)
    public static let rawCandidateFont: Font = .system(size: 17, weight: .regular, design: .default)
}
