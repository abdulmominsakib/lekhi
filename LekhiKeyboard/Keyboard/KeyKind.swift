//
//  KeyKind.swift
//  LekhiKeyboard
//
//  Visual variants for mechanical keyboard keys.
//
//  The reference design keeps every cap white — shift, backspace, ABC, the
//  spacebar and the mode keys included — and colours only the Return key.
//  The variants below still exist so each key can carry its own glyph
//  treatment and width, but they share the white keycap material.
//

import SwiftUI

public enum KeyKind: Equatable {
    /// Standard letter or symbol key.
    case letter
    /// Wide action key (shift, backspace, ABC, 123, #+=).
    case action
    /// The signature blue 3D Return key.
    case `return`
    /// Globe key for switching keyboards.
    case globe
    /// Emoji switcher key.
    case emoji
    /// Microphone key (Dictation).
    case mic
    /// The mechanical spacebar.
    case space

    public var isReturn: Bool { self == .return }
    public var isSpace: Bool { self == .space }
    public var isAction: Bool { self == .action || self == .globe || self == .emoji || self == .mic }

    /// Top-of-dish colour (the soft shading at the top of the moulded face).
    public func dishTop(palette: KeyboardColorPalette) -> Color {
        switch self {
        case .return:                      return palette.returnKeyDishTop
        case .action, .globe, .emoji, .mic: return palette.actionKeyDishTop
        case .letter, .space:              return palette.keyDishTop
        }
    }

    /// Bottom-of-dish colour.
    public func dishBottom(palette: KeyboardColorPalette) -> Color {
        switch self {
        case .return:                      return palette.returnKeyFaceBottom
        case .action, .globe, .emoji, .mic: return palette.actionKeyFaceBottom
        case .letter, .space:              return palette.keyFaceBottom
        }
    }

    /// Colour of the bright rim surrounding the dish.
    public func rimColor(palette: KeyboardColorPalette) -> Color {
        switch self {
        case .return:                      return palette.returnKeyFaceTop
        case .action, .globe, .emoji, .mic: return palette.actionKeyFaceTop
        case .space:                       return palette.spacebarFace
        case .letter:                      return palette.keyFaceTop
        }
    }

    public func faceGradient(palette: KeyboardColorPalette) -> LinearGradient {
        LinearGradient(
            colors: [dishTop(palette: palette), dishBottom(palette: palette)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    public func bevelColor(palette: KeyboardColorPalette) -> Color {
        switch self {
        case .return:                      return palette.returnKeyBevelSkirt
        case .action, .globe, .emoji, .mic: return palette.actionKeyBevelSkirt
        case .space:                       return palette.spacebarBevel
        case .letter:                      return palette.keyBevelSkirt
        }
    }

    public func pressedFace(palette: KeyboardColorPalette) -> Color {
        isReturn ? palette.returnKeyPressed : palette.keyPressedFace
    }

    public func foreground(palette: KeyboardColorPalette) -> Color {
        switch self {
        case .return:       return palette.returnKeyForeground
        case .action:       return palette.actionKeyForeground
        case .globe, .emoji, .mic: return palette.accessoryIconColor
        default:            return palette.keyForeground
        }
    }

    public var font: Font {
        switch self {
        case .letter: return Theme.letterFont
        default:      return Theme.actionFont
        }
    }

    /// Width in "letter key" units, matching the reference design:
    /// letter 143 px, shift/backspace 220 px (1.538), mode key 362 px (2.53),
    /// space 789 px (5.52), return 363 px (2.54).
    public var widthMultiplier: CGFloat {
        switch self {
        case .letter:           return 1.0
        case .action:           return 1.54
        case .space:            return 5.52
        case .return:           return 2.2
        case .globe:            return 1.2
        case .emoji:            return 1.2
        case .mic:              return 1.2
        }
    }
}
