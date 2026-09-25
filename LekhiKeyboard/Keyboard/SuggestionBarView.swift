//
//  SuggestionBarView.swift
//  LekhiKeyboard
//
//  The candidate bar above the key grid.
//
//  Matches the reference design: three equal cells across the full plate
//  width, centred 17 pt text, and a pair of short hairline dividers on the
//  thirds. The dividers are hidden while there is nothing to suggest — in
//  the old build they hung in an otherwise empty bar and read as a glitch.
//
//  With more than three items — the idle favourites and everyday phrases, or
//  the many readings the engine offers for one word — the cells become a
//  horizontal strip, narrowed just enough that the fourth peeks in from the
//  trailing edge to show there is more to swipe to.
//

import SwiftUI

public struct SuggestionBarView: View {

    /// Candidates to display. Three or fewer fill fixed thirds; more scroll.
    public let candidates: [String]

    /// Raw input buffer for displaying the phonetic quote (e.g. "ami").
    public let rawBuffer: String

    /// Index of the currently highlighted candidate.
    public let selectedIndex: Int

    /// Color palette from the active theme.
    public let palette: KeyboardColorPalette

    /// Confirmation to show in place of the candidates, if any.
    public let notice: InputSession.FavouriteNotice?

    /// Callback when the user taps the candidate at `index`.
    public let onTap: (Int) -> Void

    /// Callback when the user long-presses the candidate at `index`.
    /// `nil` turns long press off.
    public let onLongPress: ((Int) -> Void)?

    public init(
        candidates: [String],
        rawBuffer: String = "",
        selectedIndex: Int = 0,
        palette: KeyboardColorPalette = Theme.palette,
        notice: InputSession.FavouriteNotice? = nil,
        onTap: @escaping (Int) -> Void,
        onLongPress: ((Int) -> Void)? = nil
    ) {
        self.candidates = candidates
        self.rawBuffer = rawBuffer
        self.selectedIndex = selectedIndex
        self.palette = palette
        self.notice = notice
        self.onTap = onTap
        self.onLongPress = onLongPress
    }

    /// How much of the fourth cell shows when the bar scrolls.
    private static let scrollPeek: CGFloat = 28

    private var hasAnyCandidate: Bool {
        candidates.contains { !$0.isEmpty }
    }

    public var body: some View {
        Group {
            if candidates.count > 3 {
                scrollingCells
            } else {
                fixedCells
            }
        }
        .opacity(notice == nil ? 1 : 0)
        .allowsHitTesting(notice == nil)
        .overlay {
            if let notice {
                FavouriteNoticeView(notice: notice, palette: palette)
                    .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(palette.candidateBarBackground)
        .animation(.easeOut(duration: 0.12), value: hasAnyCandidate)
        .animation(.easeOut(duration: 0.15), value: notice)
    }

    private var fixedCells: some View {
        HStack(spacing: 0) {
            ForEach(0..<3, id: \.self) { i in
                candidateCell(at: i)

                if i < 2 {
                    divider
                        .opacity(hasAnyCandidate ? 1 : 0)
                }
            }
        }
    }

    private var scrollingCells: some View {
        GeometryReader { proxy in
            let cellWidth = max((proxy.size.width - Self.scrollPeek) / 3, 1)

            ScrollView(.horizontal, showsIndicators: false) {
                // Lazy: the idle list can run to hundreds of favourites.
                LazyHStack(spacing: 0) {
                    ForEach(candidates.indices, id: \.self) { i in
                        // A third of the bar at least, wider for a long
                        // phrase: the strip scrolls, so nothing needs cutting.
                        candidateCell(at: i, fitsText: true)
                            .frame(minWidth: cellWidth)
                            .overlay(alignment: .leading) {
                                if i > 0 { divider }
                            }
                    }
                }
            }
            // Free scrolling, not `.viewAligned`: that only stops where a
            // cell's leading edge meets the bar's, and with the peek the end
            // of the list is never such a stop — it snapped back one cell
            // short, leaving the last suggestion unreachable.
            // A new word is a new list: start it from the front, where the
            // reading already in the document sits, rather than wherever the
            // previous word's list was left scrolled to.
            .id(candidates)
        }
    }

    private var divider: some View {
        Rectangle()
            .fill(palette.candidateDivider)
            .frame(width: 0.75)
            .frame(maxHeight: .infinity)
            .padding(.vertical, 11)
    }

    @ViewBuilder
    private func candidateCell(at index: Int, fitsText: Bool = false) -> some View {
        let hasItem = index < candidates.count && !candidates[index].isEmpty
        let text = hasItem ? candidates[index] : ""

        // The literal phonetic reading is quoted, matching the design's “The”.
        let displayText: String = {
            guard hasItem else { return "" }
            if index == 0, !rawBuffer.isEmpty, text.lowercased() == rawBuffer.lowercased() {
                return "\u{201C}\(text)\u{201D}"
            }
            return text
        }()

        CandidateCell(
            text: text,
            displayText: displayText,
            hasItem: hasItem,
            isSelected: index == selectedIndex && hasItem,
            fitsText: fitsText,
            palette: palette,
            onTap: { onTap(index) },
            onLongPress: onLongPress.map { handler in { handler(index) } }
        )
    }
}

private struct CandidateCell: View {
    let text: String
    let displayText: String
    let hasItem: Bool
    let isSelected: Bool
    /// Size the cell to its text instead of shrinking or truncating it — for
    /// the scrolling strip, where a cell may be as wide as its phrase.
    var fitsText: Bool = false
    let palette: KeyboardColorPalette
    let onTap: () -> Void
    let onLongPress: (() -> Void)?

    var body: some View {
        let label = ZStack {
            if isSelected {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(palette.candidateSelectedFill)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 5)
            }

            Text(displayText)
                .font(Theme.candidateFont)
                .foregroundStyle(palette.candidateText)
                .lineLimit(1)
                .minimumScaleFactor(fitsText ? 1 : 0.65)
                .fixedSize(horizontal: fitsText, vertical: false)
                .padding(.horizontal, fitsText ? 14 : 10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())

        // Gestures instead of a `Button`: a long press on a Button still fires
        // its action when the finger lifts, which would insert the word the
        // user only meant to save.
        Group {
            if let onLongPress, hasItem {
                label
                    .onTapGesture(perform: onTap)
                    .onLongPressGesture(minimumDuration: 0.45, perform: onLongPress)
                    .accessibilityAction(named: "Add to favourites", onLongPress)
            } else {
                label
                    .onTapGesture {
                        guard hasItem else { return }
                        onTap()
                    }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(hasItem ? "Suggestion \(text)" : "Empty suggestion")
        .accessibilityAction { if hasItem { onTap() } }
        .accessibilityHidden(!hasItem)
    }
}

private struct FavouriteNoticeView: View {
    let notice: InputSession.FavouriteNotice
    let palette: KeyboardColorPalette

    private var symbol: String {
        switch notice.result {
        case .added, .alreadySaved: return "star.fill"
        case .full, .invalid: return "exclamationmark.circle"
        }
    }

    private var message: String {
        switch notice.result {
        case .added: return "Added “\(notice.keyword)” to favourites"
        case .alreadySaved: return "“\(notice.keyword)” is already a favourite"
        case .full: return "Favourites are full (\(PinnedKeywordsStore.maxCount))"
        case .invalid: return "Can't save this as a favourite"
        }
    }

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .semibold))
            Text(message)
                .font(.system(size: 15, weight: .medium))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .foregroundStyle(palette.candidateText)
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background(Capsule().fill(palette.candidateSelectedFill))
        .padding(.horizontal, 12)
        .accessibilityElement(children: .combine)
        .allowsHitTesting(false)
    }
}
