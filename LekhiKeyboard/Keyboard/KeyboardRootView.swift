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
    public let onLongPressCandidate: ((Int) -> Void)?
    public let onSwipeLanguage: ((Bool) -> Void)?

    public init(
        session: InputSession,
        onAction: @escaping (KeyAction) -> Void,
        onCommitCandidate: @escaping (Int) -> Void,
        onLongPressCandidate: ((Int) -> Void)? = nil,
        onSwipeLanguage: ((Bool) -> Void)? = nil
    ) {
        self.session = session
        self.onAction = onAction
        self.onCommitCandidate = onCommitCandidate
        self.onLongPressCandidate = onLongPressCandidate
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
                    onTap: onCommitCandidate,
                    onLongPress: onLongPressCandidate
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
    let onLongPress: ((Int) -> Void)?

    var body: some View {
        let showingPinned = session.isShowingPinnedKeywords
        // Saved-word completions sit ahead of the engine's candidates, so the
        // engine's selection has to shift by however many are showing.
        let matchCount = showingPinned ? 0 : session.savedWordMatches.count
        SuggestionBarView(
            candidates: showingPinned ? session.idleCandidates : session.barCandidates,
            rawBuffer: showingPinned ? "" : session.buffer,
            selectedIndex: showingPinned || session.selectedIndex < 0
                ? -1
                : session.selectedIndex + matchCount,
            palette: palette,
            notice: session.favouriteNotice,
            onTap: onTap,
            // Favourites are already saved; long press only applies to live
            // candidates.
            onLongPress: showingPinned ? nil : onLongPress
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

    /// One press state per key, kept across re-renders.
    @State private var visuals = KeyPressVisuals()

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
            let placed = placeKeys(rows, totalWidth: proxy.size.width, heightOption: heightOption)

            VStack(spacing: heightOption.rowSpacing) {
                ForEach(Array(rows.enumerated()), id: \.element.id) { rowIndex, row in
                    HStack(spacing: Theme.keySpacing) {
                        ForEach(Array(row.keys.enumerated()), id: \.element.id) { index, key in
                            keyView(
                                key,
                                index: index,
                                rowCount: row.keys.count,
                                headroom: headroomAboveGrid
                                    + CGFloat(rowIndex) * (heightOption.keyBodyHeight + heightOption.rowSpacing),
                                heightOption: heightOption,
                                isShifted: isShifted,
                                isCapsLocked: isCapsLocked,
                                layout: layout
                            )
                            .frame(width: placed[rowIndex][index].frame.width)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            // Laid over the grid *and* the plate margins around it, which
            // belong to the outer keys: a tap at the edge of the screen still
            // lands.
            .overlay(alignment: .topLeading) {
                KeyTouchSurface(
                    targets: placed.flatMap { $0 }.map { $0.offsetBy(Theme.sideInset, heightOption.topPadding) },
                    visuals: visuals,
                    onPress: onAction,
                    onSwipeLanguage: { forward in
                        if let onSwipeLanguage {
                            onSwipeLanguage(forward)
                        } else {
                            session.cycleLanguage(forward: forward)
                        }
                    }
                )
                .padding(EdgeInsets(
                    top: -heightOption.topPadding,
                    leading: -Theme.sideInset,
                    bottom: -heightOption.bottomPadding,
                    trailing: -Theme.sideInset
                ))
            }
        }
        .frame(height: heightOption.gridHeight)
    }

    private func keyView(
        _ key: KeyDescriptor,
        index: Int,
        rowCount: Int,
        headroom: CGFloat,
        heightOption: KeyboardHeightOption,
        isShifted: Bool,
        isCapsLocked: Bool,
        layout: Layout
    ) -> KeyboardKey {
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
            isLastInRow: index == rowCount - 1,
            popupHeadroom: headroom,
            visual: visuals.visual(for: key.id)
        ) {
            onAction(key.action)
        }
    }

    /// Where every key is drawn and which part of the plate its touches come
    /// from, in the grid's own space, row by row.
    private func placeKeys(
        _ rows: [KeyRow],
        totalWidth: CGFloat,
        heightOption: KeyboardHeightOption
    ) -> [[KeyTouchTarget]] {
        // Ten letter caps plus nine gaps fill the plate exactly; every other
        // row's weights are expressed in those same units.
        let unitWidth = (totalWidth - (9 * Theme.keySpacing)) / 10.0
        let swipes = session.spacebarSwipeEnabled && session.canSwitchLayouts

        return rows.enumerated().map { rowIndex, row in
            let count = CGFloat(row.keys.count)
            let totalSpacing = (count - 1) * Theme.keySpacing
            let fixedKeys = row.keys.filter { !$0.isFlexible }
            let flexibleCount = CGFloat(row.keys.count - fixedKeys.count)
            let fixedWidth = fixedKeys.reduce(CGFloat(0)) { $0 + ($1.widthWeight * unitWidth) }
            // Whatever is left after the fixed keys goes to the spacebar.
            // Clamped so a wide row can never push keys past the edge of a
            // narrow screen.
            let flexibleWidth = flexibleCount > 0
                ? max((totalWidth - fixedWidth - totalSpacing) / flexibleCount, unitWidth)
                : 0
            let usedWidth = fixedWidth + totalSpacing + (flexibleWidth * flexibleCount)
            let overflowScale = min(1, totalWidth / max(usedWidth, 1))

            let widths = row.keys.map { ($0.isFlexible ? flexibleWidth : $0.widthWeight * unitWidth) * overflowScale }
            let rowWidth = widths.reduce(0, +) + totalSpacing
            // Rows are centred. An inset row (Ridmik's home row) leaves a
            // margin at each end, which belongs to its outer keys, as on the
            // system keyboard.
            let rowMinX = (totalWidth - rowWidth) / 2
            let rowMinY = CGFloat(rowIndex) * (heightOption.keyBodyHeight + heightOption.rowSpacing)

            // Each key's touches come from its share of the gaps around it:
            // half the spacing to each neighbour, and at the outer edges all
            // of the margin up to the edge of the plate.
            let outerReach = rowMinX + Theme.sideInset
            let topReach = rowIndex == 0 ? heightOption.topPadding : heightOption.rowSpacing / 2
            let bottomReach = rowIndex == rows.count - 1 ? heightOption.bottomPadding : heightOption.rowSpacing / 2

            var x = rowMinX
            return row.keys.enumerated().map { index, key in
                let frame = CGRect(x: x, y: rowMinY, width: widths[index], height: heightOption.keyBodyHeight)
                x += widths[index] + Theme.keySpacing
                let leading = Theme.touchSlop + (index == 0 ? outerReach : 0)
                let trailing = Theme.touchSlop + (index == row.keys.count - 1 ? outerReach : 0)
                return KeyTouchTarget(
                    id: key.id,
                    action: key.action,
                    kind: key.kind,
                    frame: frame,
                    hitRect: CGRect(
                        x: frame.minX - leading,
                        y: frame.minY - topReach,
                        width: frame.width + leading + trailing,
                        height: frame.height + topReach + bottomReach
                    ),
                    swipesLanguage: key.kind.isSpace && swipes
                )
            }
        }
    }
}

private extension KeyTouchTarget {
    /// The same target in a space whose origin sits `dx`, `dy` up and to the
    /// left of the grid's.
    func offsetBy(_ dx: CGFloat, _ dy: CGFloat) -> KeyTouchTarget {
        KeyTouchTarget(
            id: id,
            action: action,
            kind: kind,
            frame: frame.offsetBy(dx: dx, dy: dy),
            hitRect: hitRect.offsetBy(dx: dx, dy: dy),
            swipesLanguage: swipesLanguage
        )
    }
}
