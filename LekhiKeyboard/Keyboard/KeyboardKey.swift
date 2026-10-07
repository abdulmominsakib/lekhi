//
//  KeyboardKey.swift
//  LekhiKeyboard
//
//  A mechanical keycap drawn the way the reference design draws it: a light
//  bevel skirt, a bright rim, a concave dish shaded from #F0F0F0 down to
//  #FCFCFC, and a soft drop shadow on the plate. Also draws the press, the
//  Apple-style character balloon and the spacebar's language-swipe label.
//  Touches themselves are handled once for the whole grid by
//  `KeyTouchSurface`, which drives this key through its `KeyPressVisual`.
//

import SwiftUI

public struct KeyboardKey: View {

    public let descriptor: KeyDescriptor
    public let palette: KeyboardColorPalette
    public let isShifted: Bool
    public let isCapsLocked: Bool
    public let spacebarLabel: String?
    /// Height of the drawn cap face. The skirt sits below it.
    public let keyHeight: CGFloat
    public let skirtHeight: CGFloat
    public let showsCharacterPreview: Bool
    public let spacebarSwipeEnabled: Bool
    public let showsKeyHints: Bool
    public let isFirstInRow: Bool
    public let isLastInRow: Bool
    /// Distance from the top of this cap to the top of the keyboard view.
    /// iOS clips a keyboard extension to its own bounds, so the preview
    /// balloon must not rise further than this.
    public let popupHeadroom: CGFloat
    /// Press state, written by the grid's touch surface.
    public let visual: KeyPressVisual
    /// Fires the key for VoiceOver and other assistive activation. Touches go
    /// through the touch surface instead.
    public let onPress: () -> Void

    private var isPressed: Bool { visual.isPressed }
    private var dragOffset: CGFloat { visual.dragOffset }
    private var swipeForward: Bool { visual.swipeForward }

    public init(
        descriptor: KeyDescriptor,
        palette: KeyboardColorPalette = Theme.palette,
        isShifted: Bool = false,
        isCapsLocked: Bool = false,
        spacebarLabel: String? = nil,
        keyHeight: CGFloat,
        skirtHeight: CGFloat,
        showsCharacterPreview: Bool = true,
        spacebarSwipeEnabled: Bool = true,
        showsKeyHints: Bool = true,
        isFirstInRow: Bool = false,
        isLastInRow: Bool = false,
        popupHeadroom: CGFloat = .infinity,
        visual: KeyPressVisual,
        onPress: @escaping () -> Void
    ) {
        self.descriptor = descriptor
        self.palette = palette
        self.isShifted = isShifted
        self.isCapsLocked = isCapsLocked
        self.spacebarLabel = spacebarLabel
        self.keyHeight = keyHeight
        self.skirtHeight = skirtHeight
        self.showsCharacterPreview = showsCharacterPreview
        self.spacebarSwipeEnabled = spacebarSwipeEnabled
        self.showsKeyHints = showsKeyHints
        self.isFirstInRow = isFirstInRow
        self.isLastInRow = isLastInRow
        self.popupHeadroom = popupHeadroom
        self.visual = visual
        self.onPress = onPress
    }

    private var bodyHeight: CGFloat { keyHeight + skirtHeight }

    private var shouldShowCharacterPreview: Bool {
        showsCharacterPreview && descriptor.kind == .letter && descriptor.label.count <= 2
    }

    /// How far the spacebar drag has travelled into a language swipe, 0…1.
    /// Ramped from a small dead zone so a tap or a jittery press leaves the
    /// label alone, and reaching full emphasis right where the swipe fires
    /// (55 pt) so the label is already lit when the layout actually flips.
    private var languageSwipeProgress: CGFloat {
        guard descriptor.kind.isSpace, spacebarSwipeEnabled,
              isPressed || dragOffset != 0 else { return 0 }
        let deadZone: CGFloat = 10
        let switchPoint: CGFloat = 55
        return min(max((abs(dragOffset) - deadZone) / (switchPoint - deadZone), 0), 1)
    }

    public var body: some View {
        ZStack(alignment: .top) {
            // 1. Bevel skirt — the key body the cap sinks into.
            RoundedRectangle(cornerRadius: Theme.keyCornerRadius + 1, style: .continuous)
                .fill(descriptor.kind.bevelColor(palette: palette))
                .frame(height: bodyHeight)
                .shadow(
                    color: palette.keyShadow,
                    radius: isPressed ? 1.0 : 2.5,
                    x: 0,
                    y: isPressed ? 0.5 : 1.5
                )

            // 2. Keycap face — sinks into the skirt on press.
            keyFaceView
                .offset(
                    x: descriptor.kind.isSpace
                        ? max(-8, min(8, dragOffset * 0.08))
                        : 0
                )
                .offset(y: isPressed ? Theme.pressedDepression : 0)

            // 3. Apple-style elevated character preview balloon.
            if isPressed && shouldShowCharacterPreview {
                keyPreviewPopup
                    .zIndex(1000)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: bodyHeight)
        .zIndex(isPressed ? 999 : 1)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { onPress() }
    }

    // MARK: - Key Face

    private var keyFaceView: some View {
        let kind = descriptor.kind
        let rim = isPressed ? kind.pressedFace(palette: palette) : kind.rimColor(palette: palette)

        return ZStack {
            // Bright outer rim of the moulded cap.
            RoundedRectangle(cornerRadius: Theme.keyCornerRadius, style: .continuous)
                .fill(rim)

            // Concave dish: the shading that makes the cap read as moulded
            // rather than as a flat rounded rectangle.
            RoundedRectangle(cornerRadius: Theme.keyDishCornerRadius, style: .continuous)
                .fill(
                    isPressed
                        ? LinearGradient(
                            colors: [kind.pressedFace(palette: palette),
                                     kind.pressedFace(palette: palette)],
                            startPoint: .top, endPoint: .bottom
                          )
                        : kind.faceGradient(palette: palette)
                )
                .padding(.horizontal, Theme.keyDishInsetX)
                .padding(.top, Theme.keyDishInsetTop)
                .padding(.bottom, Theme.keyDishInsetBottom)
                .blur(radius: Theme.keyDishSoftness)

            // Hairline edge so the cap separates from the plate on any theme.
            RoundedRectangle(cornerRadius: Theme.keyCornerRadius, style: .continuous)
                .strokeBorder(palette.keyBorder, lineWidth: 0.5)

            glyphView
        }
        .frame(maxWidth: .infinity)
        .frame(height: keyHeight)
        .compositingGroup()
    }

    // MARK: - Apple-style Character Preview Popup

    private var keyPreviewPopup: some View {
        let popupWidth: CGFloat = 52.0
        let popupHeight: CGFloat = max(keyHeight * 1.18, 52.0)
        let horizontalShift: CGFloat = isFirstInRow ? 7.0 : (isLastInRow ? -7.0 : 0.0)

        return VStack(spacing: 0) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(palette.keyFaceTop)
                    .shadow(color: palette.keyShadow, radius: 6, x: 0, y: 2)

                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(palette.keyBorder, lineWidth: 0.5)

                Text(descriptor.label)
                    .font(.system(size: descriptor.label.count == 1 ? 34 : 26, weight: .regular))
                    .foregroundStyle(palette.keyForeground)
            }
            .frame(width: popupWidth, height: popupHeight)

            // Seamless stem overlapping the key face below.
            RoundedRectangle(cornerRadius: Theme.keyCornerRadius, style: .continuous)
                .fill(palette.keyFaceTop)
                .frame(maxWidth: .infinity)
                .frame(height: 12)
                .offset(y: -4)
        }
        .frame(width: popupWidth)
        // On the top row the full rise would push the balloon past the top of
        // the keyboard, where iOS cuts it off. Let it overlap its own key
        // instead; the balloon repeats that key's glyph anyway.
        .offset(x: horizontalShift, y: -min(popupHeight + 2, max(0, popupHeadroom)))
        .allowsHitTesting(false)
        .transition(.identity)
    }

    // MARK: - Glyph

    @ViewBuilder
    private var glyphView: some View {
        let fg = descriptor.kind.foreground(palette: palette)

        switch descriptor.label {
        case "⇧":
            Image(systemName: isCapsLocked
                  ? "capslock.fill"
                  : (isShifted ? "shift.fill" : "shift"))
                .font(.system(size: 18, weight: isShifted || isCapsLocked ? .semibold : .regular))
                .foregroundStyle(fg)

        case "⌫":
            Image(systemName: "delete.backward")
                .font(.system(size: 18, weight: .regular))
                .foregroundStyle(fg)

        case "↵", "return":
            Image(systemName: "return")
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(fg)

        case "space":
            spacebarGlyph(fg: fg)

        case "emoji", "😊":
            Image(systemName: "face.smiling")
                .font(.system(size: 19, weight: .regular))
                .foregroundStyle(fg)

        case "globe":
            Image(systemName: "globe")
                .font(.system(size: 18, weight: .regular))
                .foregroundStyle(fg)

        default:
            letterGlyph(fg: fg)
        }
    }

    @ViewBuilder
    private func spacebarGlyph(fg: Color) -> some View {
        // The design's spacebar carries no label at all. Lekhi needs one so
        // the active layout is visible, so it is drawn as quietly as possible —
        // until a swipe begins, when it grows, lifts and brightens so the
        // layout being moved to is the thing the eye lands on.
        if let label = spacebarLabel, !label.isEmpty {
            let progress = languageSwipeProgress

            HStack(spacing: 5) {
                if spacebarSwipeEnabled {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 7, weight: .semibold))
                        .foregroundStyle(fg.opacity(0.28 * (1 - progress)))
                }

                Text(label)
                    .foregroundStyle(fg.opacity(0.55 + (0.45 * progress)))
                    .offset(y: -4 * progress)
                    .modifier(SwipeLabelFont(
                        size: 12 + (5 * progress),
                        weight: progress > 0.4 ? .medium : .regular
                    ))
                    // Re-insert on every language change so the old name
                    // leaves with the finger and the new one follows it in,
                    // instead of the glyphs swapping in place.
                    .id(label)
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: swipeForward ? .leading : .trailing)
                                .combined(with: .opacity),
                            removal: .move(edge: swipeForward ? .trailing : .leading)
                                .combined(with: .opacity)
                        )
                    )

                if spacebarSwipeEnabled {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 7, weight: .semibold))
                        .foregroundStyle(fg.opacity(0.28 * (1 - progress)))
                }
            }
            .animation(.easeOut(duration: 0.18), value: label)
        } else {
            Text("space")
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(fg.opacity(0.5))
        }
    }

    @ViewBuilder
    private func letterGlyph(fg: Color) -> some View {
        if let hint = descriptor.bengaliHint, !hint.isEmpty, showsKeyHints {
            ZStack(alignment: .topTrailing) {
                Text(descriptor.label)
                    .font(descriptor.kind.font)
                    .foregroundStyle(fg)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                Text(hint)
                    .font(.system(size: hint.count > 1 ? 7 : 8.5, weight: .regular))
                    .foregroundStyle(fg.opacity(0.36))
                    .padding(.top, 4)
                    .padding(.trailing, 5)
            }
        } else {
            Text(descriptor.label)
                .font(descriptor.kind.font)
                .foregroundStyle(fg)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var accessibilityLabel: String {
        switch descriptor.label {
        case "⇧": return isCapsLocked ? "Caps lock on" : (isShifted ? "Shift on" : "Shift")
        case "⌫": return "Delete"
        case "↵", "return": return "Return"
        case "space": return spacebarLabel.map { "Space, \($0)" } ?? "Space"
        case "emoji", "😊": return "Emoji"
        case "globe": return "Next keyboard"
        default: return descriptor.label
        }
    }
}

/// Drives the spacebar label's type size through animatable data. `Text` does
/// not interpolate `.font` changes on its own, so a swipe that stops short of
/// the switch point would otherwise snap the label back to its resting size
/// instead of easing home with the spring.
private struct SwipeLabelFont: ViewModifier, Animatable {
    var size: CGFloat
    var weight: Font.Weight

    var animatableData: CGFloat {
        get { size }
        set { size = newValue }
    }

    func body(content: Content) -> some View {
        content.font(.system(size: size, weight: weight))
    }
}
