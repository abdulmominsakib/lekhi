//
//  KeyboardRootView.swift
//  LekhiKeyboard
//
//  Top-level SwiftUI view for the keyboard. Hosts the
//  candidate suggestion bar and the key grid.
//  The system already draws globe + mic below us — no extra bar needed.
//

import SwiftUI

public struct KeyboardRootView: View {

    @Bindable public var session: InputSession
    public let onAction: (KeyAction) -> Void
    public let onCommitCandidate: (Int) -> Void

    public init(
        session: InputSession,
        onAction: @escaping (KeyAction) -> Void,
        onCommitCandidate: @escaping (Int) -> Void
    ) {
        self.session = session
        self.onAction = onAction
        self.onCommitCandidate = onCommitCandidate
    }

    @Environment(\.colorScheme) private var colorScheme

    private var palette: KeyboardColorPalette {
        session.theme.resolvedPalette(for: colorScheme)
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Suggestion / Candidate Bar (always visible)
            if !session.isEmojiMode && session.mode.showsSuggestionBar {
                SuggestionBarView(
                    candidates: session.candidates,
                    rawBuffer: session.buffer,
                    selectedIndex: session.selectedIndex,
                    palette: palette,
                    onTap: onCommitCandidate
                )
            }

            // Keyboard or Emoji Picker
            if session.isEmojiMode {
                EmojiPickerView(
                    session: session,
                    palette: palette,
                    onInsert: { text in
                        onAction(.insertText(text))
                    },
                    onDelete: {
                        onAction(.backspace(word: false))
                    }
                )
                .padding(.top, 4)
                .transition(.opacity)
            } else {
                // Mechanical Key Grid (Rows 1–4)
                KeyboardGrid(session: session, palette: palette, onAction: onAction)
                    .padding(.horizontal, Theme.sideInset)
                    .padding(.top, 4)
                    .padding(.bottom, Theme.bottomInset)
                    .transition(.opacity)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(palette.backgroundPlate)
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 0.2), value: session.isEmojiMode)
    }
}

/// The four mechanical QWERTY / Number / Symbol rows.
private struct KeyboardGrid: View {

    @Bindable var session: InputSession
    let palette: KeyboardColorPalette
    let onAction: (KeyAction) -> Void

    var body: some View {
        let rows: [KeyRow] = {
            switch session.layoutMode {
            case .letters:
                return KeyboardLayoutFactory.letters(isShifted: session.isShifted)
            case .numbers:
                return KeyboardLayoutFactory.numbers()
            case .symbols:
                return KeyboardLayoutFactory.symbols()
            }
        }()

        GeometryReader { proxy in
            let totalWidth = proxy.size.width
            let standardUnit = (totalWidth - (9 * Theme.keySpacing)) / 10.0

            VStack(spacing: Theme.rowSpacing) {
                ForEach(rows) { row in
                    rowView(for: row, totalWidth: totalWidth, unitWidth: standardUnit)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .frame(height: (Theme.keyHeight * 4) + (Theme.rowSpacing * 3))
    }

    private func rowView(for row: KeyRow, totalWidth: CGFloat, unitWidth: CGFloat) -> some View {
        let count = CGFloat(row.keys.count)
        let totalSpacing = (count - 1) * Theme.keySpacing
        let hasCustomWeights = row.keys.contains { $0.widthWeight != 1.0 }

        return HStack(spacing: Theme.keySpacing) {
            ForEach(row.keys) { key in
                let keyWidth: CGFloat = {
                    if !hasCustomWeights {
                        return unitWidth
                    } else if key.kind.isSpace {
                        let otherKeysWidth = row.keys.filter { !$0.kind.isSpace }.reduce(CGFloat(0)) { acc, k in
                            acc + (k.widthWeight * unitWidth)
                        }
                        return max(totalWidth - otherKeysWidth - totalSpacing, unitWidth * 3)
                    } else {
                        return key.widthWeight * unitWidth
                    }
                }()

                KeyboardKey(
                    descriptor: key,
                    palette: palette,
                    isShifted: session.isShifted,
                    spacebarLabel: key.kind.isSpace ? session.layout.spacebarLabel : nil,
                    onSwipeLanguage: key.kind.isSpace ? { forward in
                        withAnimation(.easeInOut(duration: 0.15)) {
                            session.cycleLanguage(forward: forward)
                        }
                    } : nil
                ) {
                    onAction(key.action)
                }
                .frame(width: keyWidth)
            }
        }
    }
}
