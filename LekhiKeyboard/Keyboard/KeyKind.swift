//
//  KeyKind.swift
//  LekhiKeyboard
//
//  Visual variants for mechanical keyboard keys.
//

import SwiftUI

public enum KeyKind: Equatable {
    /// Standard letter or symbol key (3D white cap).
    case letter
    /// Wide action key (shift, backspace, ABC, 123, #+=).
    case action
    /// The signature vibrant blue 3D Return key.
    case `return`
    /// Globe key for switching keyboards.
    case globe
    /// Emoji switcher key (Smile icon 😊).
    case emoji
    /// Microphone key (Dictation 🎙️).
    case mic
    /// The mechanical spacebar.
    case space

    public var isReturn: Bool { self == .return }
    public var isSpace: Bool { self == .space }
    public var isAction: Bool { self == .action || self == .globe || self == .emoji || self == .mic }

    public func faceGradient(palette: KeyboardColorPalette) -> LinearGradient {
        switch self {
        case .letter:
            return LinearGradient(
                colors: [palette.keyFaceTop, palette.keyFaceBottom],
                startPoint: .top,
                endPoint: .bottom
            )
        case .action, .globe:
            return LinearGradient(
                colors: [palette.actionKeyFaceTop, palette.actionKeyFaceBottom],
                startPoint: .top,
                endPoint: .bottom
            )
        case .return:
            return LinearGradient(
                colors: [palette.returnKeyFaceTop, palette.returnKeyFaceBottom],
                startPoint: .top,
                endPoint: .bottom
            )
        case .space:
            return LinearGradient(
                colors: [palette.spacebarFace, palette.keyFaceBottom],
                startPoint: .top,
                endPoint: .bottom
            )
        case .emoji, .mic:
            return LinearGradient(
                colors: [palette.actionKeyFaceTop, palette.actionKeyFaceBottom],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    public func bevelColor(palette: KeyboardColorPalette) -> Color {
        switch self {
        case .letter:       return palette.keyBevelSkirt
        case .action, .globe: return palette.actionKeyBevelSkirt
        case .return:       return palette.returnKeyBevelSkirt
        case .space:        return palette.spacebarBevel
        case .emoji, .mic:  return palette.actionKeyBevelSkirt
        }
    }

    public func foreground(palette: KeyboardColorPalette) -> Color {
        switch self {
        case .return:       return palette.returnKeyForeground
        case .action:       return palette.actionKeyForeground
        case .emoji, .mic:  return palette.accessoryIconColor
        default:            return palette.keyForeground
        }
    }

    public var font: Font {
        switch self {
        case .letter: return Theme.letterFont
        default:      return Theme.actionFont
        }
    }

    public var widthMultiplier: CGFloat {
        switch self {
        case .letter:           return 1.0
        case .action:           return 1.45   // shift / backspace / ABC
        case .space:            return 6.75   // wide spacebar
        case .return:           return 1.8    // return button
        case .globe:            return 1.15
        case .emoji:            return 1.45
        case .mic:              return 1.0
        }
    }
}
