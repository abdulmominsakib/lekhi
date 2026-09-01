//
//  KeyboardKey.swift
//  LekhiKeyboard
//
//  A mechanical keycap with bevel, shadow, spring-down animation,
//  and Apple-style elevated character preview balloon on touch-down.
//

import SwiftUI

public struct KeyboardKey: View {

    public let descriptor: KeyDescriptor
    public let palette: KeyboardColorPalette
    public let isShifted: Bool
    public let spacebarLabel: String?
    public let keyHeight: CGFloat
    public let isFirstInRow: Bool
    public let isLastInRow: Bool
    public let onSwipeLanguage: ((Bool) -> Void)?
    public let onPress: () -> Void

    @State private var isPressed: Bool = false
    @State private var dragOffset: CGFloat = 0
    @State private var hasSwiped: Bool = false

    public init(
        descriptor: KeyDescriptor,
        palette: KeyboardColorPalette = Theme.palette,
        isShifted: Bool = false,
        spacebarLabel: String? = nil,
        keyHeight: CGFloat = Theme.keyHeight,
        isFirstInRow: Bool = false,
        isLastInRow: Bool = false,
        onSwipeLanguage: ((Bool) -> Void)? = nil,
        onPress: @escaping () -> Void
    ) {
        self.descriptor = descriptor
        self.palette = palette
        self.isShifted = isShifted
        self.spacebarLabel = spacebarLabel
        self.keyHeight = keyHeight
        self.isFirstInRow = isFirstInRow
        self.isLastInRow = isLastInRow
        self.onSwipeLanguage = onSwipeLanguage
        self.onPress = onPress
    }

    private var shouldShowCharacterPreview: Bool {
        CharacterPreviewStore.current() && descriptor.kind == .letter && descriptor.label.count <= 2
    }

    public var body: some View {
        ZStack(alignment: .top) {
            // 1. Bevel Skirt — gives the 3-D depth illusion
            RoundedRectangle(cornerRadius: Theme.keyCornerRadius, style: .continuous)
                .fill(descriptor.kind.bevelColor(palette: palette))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .shadow(
                    color: Color.black.opacity(isPressed ? 0.06 : 0.14),
                    radius: isPressed ? 1.0 : 2.0,
                    x: 0,
                    y: isPressed ? 1.0 : 2.5
                )

            // 2. Key Face — slides down on press
            keyFaceView
                .offset(
                    x: descriptor.kind.isSpace
                        ? max(-8, min(8, dragOffset * 0.08))
                        : 0
                )
                .offset(y: isPressed ? Theme.pressedDepression : 0)

            // 3. Apple-style Elevated Character Preview Popup
            if isPressed && shouldShowCharacterPreview {
                keyPreviewPopup
                    .zIndex(1000)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: keyHeight)
        .zIndex(isPressed ? 999 : 1)
        .contentShape(RoundedRectangle(cornerRadius: Theme.keyCornerRadius, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { onPress() }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    if !isPressed {
                        isPressed = true
                        triggerFeedback()
                        if !descriptor.kind.isSpace {
                            onPress()
                        }
                    }

                    if descriptor.kind.isSpace && SpacebarSwipeStore.current() && onSwipeLanguage != nil {
                        dragOffset = value.translation.width
                        let horizontalDrag = abs(value.translation.width)
                        let verticalDrag = abs(value.translation.height)

                        // Require intentional horizontal drag (> 55pt) to avoid accidental triggers during typing
                        if !hasSwiped && horizontalDrag > 55 && horizontalDrag > verticalDrag * 1.4 {
                            hasSwiped = true
                            HapticManager.shared.candidateSelected()
                            onSwipeLanguage?(value.translation.width > 0)
                        }
                    }
                }
                .onEnded { _ in
                    if descriptor.kind.isSpace && !hasSwiped {
                        onPress()
                    }
                    withAnimation(.easeOut(duration: 0.10)) {
                        isPressed = false
                        hasSwiped = false
                        dragOffset = 0
                    }
                }
        )
    }

    // MARK: - Key Face

    private var keyFaceView: some View {
        let faceHeight = keyHeight - (isPressed ? 1.5 : Theme.bevelHeight)

        return ZStack {
            // Face background with active press highlight
            RoundedRectangle(cornerRadius: Theme.keyCornerRadius, style: .continuous)
                .fill(
                    isPressed
                    ? LinearGradient(
                        colors: [palette.keyPressedFace, palette.keyPressedFace],
                        startPoint: .top, endPoint: .bottom
                    )
                    : descriptor.kind.faceGradient(palette: palette)
                )

            // Top-edge specular highlight
            RoundedRectangle(cornerRadius: Theme.keyCornerRadius, style: .continuous)
                .stroke(
                    descriptor.kind.isReturn
                        ? Color.white.opacity(0.35)
                        : (isPressed ? Color.white.opacity(0.20) : Color.white.opacity(0.65)),
                    lineWidth: 0.75
                )

            // Outer border
            RoundedRectangle(cornerRadius: Theme.keyCornerRadius, style: .continuous)
                .stroke(palette.keyBorder, lineWidth: 0.5)

            glyphView
        }
        .frame(maxWidth: .infinity)
        .frame(height: faceHeight)
    }

    // MARK: - Apple-style Character Preview Popup

    private var keyPreviewPopup: some View {
        let popupWidth: CGFloat = 52.0
        let popupHeight: CGFloat = max(keyHeight * 1.18, 52.0)
        let horizontalShift: CGFloat = isFirstInRow ? 7.0 : (isLastInRow ? -7.0 : 0.0)

        return ZStack {
            // Popup Balloon Body
            VStack(spacing: 0) {
                // Top bubble containing the magnified character
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(palette.keyFaceTop)
                        .shadow(color: Color.black.opacity(0.25), radius: 6, x: 0, y: 2)

                    // Top specular highlight
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.white.opacity(0.6), lineWidth: 0.75)

                    // Subtle border
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(palette.keyBorder, lineWidth: 0.5)

                    // Magnified character glyph
                    Text(descriptor.label)
                        .font(.system(size: descriptor.label.count == 1 ? 34 : 26, weight: .regular, design: .default))
                        .foregroundStyle(palette.keyForeground)
                }
                .frame(width: popupWidth, height: popupHeight)

                // Seamless lower stem overlapping the key base
                RoundedRectangle(cornerRadius: Theme.keyCornerRadius, style: .continuous)
                    .fill(palette.keyFaceTop)
                    .frame(maxWidth: .infinity)
                    .frame(height: 12)
                    .offset(y: -4)
            }
        }
        .frame(width: popupWidth)
        .offset(x: horizontalShift, y: -(popupHeight + 2))
        .allowsHitTesting(false)
        .transition(.identity)
    }

    // MARK: - Glyph

    @ViewBuilder
    private var glyphView: some View {
        let fg = descriptor.kind.foreground(palette: palette)

        switch descriptor.label {
        case "⇧":
            Image(systemName: isShifted ? "shift.fill" : "shift")
                .font(.system(size: 17, weight: isShifted ? .bold : .semibold))
                .foregroundStyle(fg)

        case "⌫":
            Image(systemName: "delete.backward")
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(fg)

        case "↵", "return":
            Image(systemName: "return")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(fg)

        case "space":
            VStack(spacing: 2) {
                if let label = spacebarLabel, !label.isEmpty {
                    HStack(spacing: 4) {
                        if SpacebarSwipeStore.current() {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 7, weight: .bold))
                                .foregroundStyle(fg.opacity(0.35))
                        }

                        Text(label)
                            .font(.system(size: 11.5, weight: .medium, design: .rounded))
                            .foregroundStyle(fg.opacity(0.75))

                        if SpacebarSwipeStore.current() {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 7, weight: .bold))
                                .foregroundStyle(fg.opacity(0.35))
                        }
                    }
                } else {
                    Text("space")
                        .font(.system(size: 11.5, weight: .medium, design: .rounded))
                        .foregroundStyle(fg.opacity(0.6))
                }

                // Tactile mechanical indicator bar at the bottom
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(palette.spacebarWell)
                    .frame(width: 44, height: 3.5)
            }

        case "emoji", "😊":
            Image(systemName: "face.smiling")
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(fg)

        case "globe":
            Image(systemName: "globe")
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(fg)

        default:
            ZStack(alignment: .topTrailing) {
                Text(descriptor.label)
                    .font(descriptor.kind.font)
                    .foregroundStyle(fg)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                if let hint = descriptor.bengaliHint, !hint.isEmpty {
                    Text(hint)
                        .font(.system(size: hint.count > 1 ? 7 : 8.5, weight: .semibold))
                        .foregroundStyle(fg.opacity(0.48))
                        .padding(.top, 4)
                        .padding(.trailing, 5)
                }
            }
        }
    }

    private var accessibilityLabel: String {
        switch descriptor.label {
        case "⇧": return isShifted ? "Shift on" : "Shift"
        case "⌫": return "Delete"
        case "↵", "return": return "Return"
        case "space": return spacebarLabel.map { "Space, \($0)" } ?? "Space"
        case "emoji", "😊": return "Emoji"
        case "globe": return "Next keyboard"
        default: return descriptor.label
        }
    }

    // MARK: - Feedback

    private func triggerFeedback() {
        let soundEnabled = SoundStore.current() != .off
        let hapticsEnabled = HapticStore.current() != .off
        if soundEnabled {
            MechanicalSoundManager.shared.playKeyPress(
                isReturn: descriptor.kind.isReturn,
                isSpace: descriptor.kind.isSpace,
                isModifier: descriptor.kind.isAction
            )
        }
        if hapticsEnabled {
            HapticManager.shared.keyPress(isAction: descriptor.kind.isAction)
        }
    }
}
