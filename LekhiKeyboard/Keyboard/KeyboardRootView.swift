//
//  KeyboardRootView.swift
//  LekhiKeyboard
//
//  Top-level SwiftUI view for the keyboard. Hosts the candidate suggestion
//  bar and the key grid.
//
//  The bar and the grid are deliberately separate views that each observe
//  their own slice of `InputSession`. Every keystroke mutates the candidate
//  list, and when one view read both the candidates and the layout state
//  SwiftUI re-evaluated all thirty-odd keycaps — gradients, dish, shadow and
//  all — on each tap, which is what made fast typing feel heavy.
//

import SwiftUI

public struct KeyboardRootView: View {

    @Bindable public var session: InputSession
    public let onAction: (KeyAction) -> Void
    public let onCommitCandidate: (Int) -> Void
    public let onSwipeLanguage: ((Bool) -> Void)?

    public init(
        session: InputSession,
        onAction: @escaping (KeyAction) -> Void,
        onCommitCandidate: @escaping (Int) -> Void,
        onSwipeLanguage: ((Bool) -> Void)? = nil
    ) {
        self.session = session
        self.onAction = onAction
        self.onCommitCandidate = onCommitCandidate
        self.onSwipeLanguage = onSwipeLanguage
    }

    @Environment(\.colorScheme) private var colorScheme

    private var palette: KeyboardColorPalette {
        session.theme.resolvedPalette(for: colorScheme)
    }

    /// The plate follows the system keyboard container: rounded top corners on
    /// iOS 26, a plain rectangle before that.
    private var plateShape: UnevenRoundedRectangle {
        let radius = Theme.usesRoundedContainer ? Theme.containerCornerRadius : 0
        return UnevenRoundedRectangle(
            topLeadingRadius: radius,
            bottomLeadingRadius: 0,
            bottomTrailingRadius: 0,
            topTrailingRadius: radius,
            style: .continuous
        )
    }

    public var body: some View {
        let heightOption = session.heightOption
        let showsBar = !session.isEmojiMode
            && !session.isEmojiSearchActive
            && !session.hostKeyboardContext.isDigitPad
            && session.mode.showsSuggestionBar

        VStack(spacing: 0) {
            if showsBar {
                CandidateBar(
                    session: session,
                    palette: palette,
                    onTap: onCommitCandidate
                )
                .frame(height: heightOption.suggestionBarHeight)
            }

            if session.isEmojiMode {
                EmojiPickerView(
                    session: session,
                    palette: palette,
                    onInsert: { text in onAction(.insertText(text)) },
                    onDelete: { onAction(.backspace(word: false)) },
                    onDismiss: { onAction(.emoji) }
                )
                .transition(.opacity)
            } else {
                if session.isEmojiSearchActive {
                    EmojiSearchHeaderView(
                        session: session,
                        palette: palette,
                        onInsert: { text in onAction(.insertText(text)) },
                        onCancel: {
                            session.clearEmojiSearch()
                            onAction(.emoji)
                        }
                    )
                }

                KeyboardGrid(
                    session: session,
                    palette: palette,
                    headroomAboveGrid: (showsBar ? heightOption.suggestionBarHeight : 0)
                        + heightOption.topPadding,
                    onAction: onAction,
                    onSwipeLanguage: onSwipeLanguage
                )
                .padding(.horizontal, Theme.sideInset)
                .padding(.top, heightOption.topPadding)
                .padding(.bottom, heightOption.bottomPadding)
                .transition(.opacity)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(plateShape.fill(session.plateUsesSystemContainer ? Color.clear : palette.backgroundPlate))
        // Keep the candidate highlight and anything else near the top edge
        // inside the rounded corners too.
        .clipShape(plateShape)
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 0.18), value: session.isEmojiMode)
        .animation(.easeInOut(duration: 0.18), value: session.isEmojiSearchActive)
    }
}

/// Wrapper that observes only the candidate-related state, so a keystroke
/// invalidates the bar and nothing else.
private struct CandidateBar: View {
    @Bindable var session: InputSession
    let palette: KeyboardColorPalette
    let onTap: (Int) -> Void

    var body: some View {
        let showingPinned = session.isShowingPinnedKeywords
        SuggestionBarView(
            candidates: showingPinned ? session.pinnedKeywords : session.candidates,
            rawBuffer: showingPinned ? "" : session.buffer,
            selectedIndex: showingPinned ? -1 : session.selectedIndex,
            palette: palette,
            onTap: onTap
        )
    }
}

/// The four mechanical QWERTY / Number / Symbol rows.
private struct KeyboardGrid: View {

    @Bindable var session: InputSession
    let palette: KeyboardColorPalette
    /// Space between the top of the keyboard view and the first key row.
    let headroomAboveGrid: CGFloat
    let onAction: (KeyAction) -> Void
    let onSwipeLanguage: ((Bool) -> Void)?

    var body: some View {
        // Everything read here is layout state that only changes when the
        // keyboard itself changes — never per keystroke.
        let layoutMode = session.layoutMode
        let isShifted = session.isShifted
        let isCapsLocked = session.isCapsLocked
        let layout = session.layout
        let heightOption = session.heightOption
        let showsGlobeKey = session.showsGlobeKey

        let rows: [KeyRow] = {
            let host = session.hostKeyboardContext
            if host.isDigitPad {
                return KeyboardLayoutFactory.digitPad(
                    style: host,
                    layout: layout,
                    showsGlobeKey: showsGlobeKey
                )
            }
            switch layoutMode {
            case .letters:
                return KeyboardLayoutFactory.letters(
                    isShifted: isShifted || isCapsLocked,
                    layout: layout,
                    showsGlobeKey: showsGlobeKey,
                    hostContext: host
                )
            case .numbers:
                return KeyboardLayoutFactory.numbers(
                    showsGlobeKey: showsGlobeKey,
                    layout: layout
                )
            case .symbols:
                return KeyboardLayoutFactory.symbols(showsGlobeKey: showsGlobeKey)
            }
        }()

        return GeometryReader { proxy in
            let totalWidth = proxy.size.width
            // Ten letter caps plus nine gaps fill the plate exactly; every
            // other row's weights are expressed in those same units.
            let unitWidth = (totalWidth - (9 * Theme.keySpacing)) / 10.0

            VStack(spacing: heightOption.rowSpacing) {
                ForEach(Array(rows.enumerated()), id: \.element.id) { rowIndex, row in
                    rowView(
                        for: row,
                        headroom: headroomAboveGrid
                            + CGFloat(rowIndex) * (heightOption.keyBodyHeight + heightOption.rowSpacing),
                        totalWidth: totalWidth,
                        unitWidth: unitWidth,
                        heightOption: heightOption,
                        isShifted: isShifted,
                        isCapsLocked: isCapsLocked,
                        layout: layout
                    )
                }
            }
            .frame(maxWidth: .infinity)
        }
        .frame(height: heightOption.gridHeight)
    }

    private func rowView(
        for row: KeyRow,
        headroom: CGFloat,
        totalWidth: CGFloat,
        unitWidth: CGFloat,
        heightOption: KeyboardHeightOption,
        isShifted: Bool,
        isCapsLocked: Bool,
        layout: Layout
    ) -> some View {
        let count = CGFloat(row.keys.count)
        let totalSpacing = (count - 1) * Theme.keySpacing
        let fixedKeys = row.keys.filter { !$0.isFlexible }
        let flexibleCount = CGFloat(row.keys.count - fixedKeys.count)
        let fixedWidth = fixedKeys.reduce(CGFloat(0)) { $0 + ($1.widthWeight * unitWidth) }
        // Whatever is left after the fixed keys goes to the spacebar. Clamped
        // so a wide row can never push keys past the edge of a narrow screen.
        let flexibleWidth = flexibleCount > 0
            ? max((totalWidth - fixedWidth - totalSpacing) / flexibleCount, unitWidth)
            : 0
        let overflowScale = min(1, totalWidth / max(fixedWidth + totalSpacing + (flexibleWidth * flexibleCount), 1))

        return HStack(spacing: Theme.keySpacing) {
            ForEach(Array(row.keys.enumerated()), id: \.element.id) { index, key in
                let rawWidth = key.isFlexible ? flexibleWidth : key.widthWeight * unitWidth

                KeyboardKey(
                    descriptor: key,
                    palette: palette,
                    isShifted: isShifted,
                    isCapsLocked: isCapsLocked,
                    spacebarLabel: key.kind.isSpace ? layout.spacebarLabel : nil,
                    keyHeight: heightOption.keyHeight,
                    skirtHeight: heightOption.keySkirt,
                    showsCharacterPreview: session.showCharacterPreview,
                    spacebarSwipeEnabled: session.spacebarSwipeEnabled && session.canSwitchLayouts,
                    showsKeyHints: session.showKeyHints,
                    isFirstInRow: index == 0,
                    isLastInRow: index == (row.keys.count - 1),
                    popupHeadroom: headroom,
                    onSwipeLanguage: key.kind.isSpace ? { forward in
                        if let onSwipeLanguage {
                            onSwipeLanguage(forward)
                        } else {
                            session.cycleLanguage(forward: forward)
                        }
                    } : nil
                ) {
                    onAction(key.action)
                }
                .frame(width: rawWidth * overflowScale)
            }
        }
    }
}
