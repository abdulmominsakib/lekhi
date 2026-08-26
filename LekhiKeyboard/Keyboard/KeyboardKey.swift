//
//  KeyboardKey.swift
//  LekhiKeyboard
//
//  A mechanical keycap with bevel, shadow, and spring-down animation.
//  Clean Latin-only labels — no Bengali hints on the keycap face.
//  Feedback fires only once on touch-down via the custom button style.
//

import SwiftUI

public struct KeyboardKey: View {

    public let descriptor: KeyDescriptor
    public let palette: KeyboardColorPalette
    public let isShifted: Bool
    public let spacebarLabel: String?
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
        onSwipeLanguage: ((Bool) -> Void)? = nil,
        onPress: @escaping () -> Void
    ) {
        self.descriptor = descriptor
        self.palette = palette
        self.isShifted = isShifted
        self.spacebarLabel = spacebarLabel
        self.onSwipeLanguage = onSwipeLanguage
        self.onPress = onPress
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
                .offset(y: isPressed ? Theme.pressedDepression : 0)
        }
        .frame(maxWidth: .infinity)
        .frame(height: Theme.keyHeight)
        .contentShape(RoundedRectangle(cornerRadius: Theme.keyCornerRadius, style: .continuous))
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
                        if !hasSwiped {
                            if dragOffset > 35 {
                                hasSwiped = true
                                UISelectionFeedbackGenerator().selectionChanged()
                                onSwipeLanguage?(true)
                            } else if dragOffset < -35 {
                                hasSwiped = true
                                UISelectionFeedbackGenerator().selectionChanged()
                                onSwipeLanguage?(false)
                            }
                        }
                    }
                }
                .onEnded { _ in
                    if descriptor.kind.isSpace && !hasSwiped {
                        onPress()
                    }
                    withAnimation(.easeOut(duration: 0.12)) {
                        isPressed = false
                        hasSwiped = false
                        dragOffset = 0
                    }
                }
        )
    }

    // MARK: - Key Face

    private var keyFaceView: some View {
        let faceHeight = Theme.keyHeight - (isPressed ? 1.5 : Theme.bevelHeight)

        return ZStack {
            // Face background
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
                        : Color.white.opacity(0.65),
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

    // MARK: - Glyph

    @ViewBuilder
    private var glyphView: some View {
        let fg = descriptor.kind.foreground(palette: palette)

        switch descriptor.label {
        case "⇧":
            Image(systemName: isShifted ? "arrow.up.circle.fill" : "arrow.up")
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

        case "😊":
            Image(systemName: "face.smiling")
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(fg)

        default:
            Text(descriptor.label)
                .font(descriptor.kind.font)
                .foregroundStyle(fg)
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
