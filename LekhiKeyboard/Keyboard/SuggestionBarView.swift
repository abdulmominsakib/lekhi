//
//  SuggestionBarView.swift
//  LekhiKeyboard
//
//  The three-slot candidate bar above the key grid.
//
//  Matches the reference design: three equal cells across the full plate
//  width, centred 17 pt text, and a pair of short hairline dividers on the
//  thirds. The dividers are hidden while there is nothing to suggest — in
//  the old build they hung in an otherwise empty bar and read as a glitch.
//

import SwiftUI

public struct SuggestionBarView: View {

    /// Up to 3 candidates to display.
    public let candidates: [String]

    /// Raw input buffer for displaying the phonetic quote (e.g. "ami").
    public let rawBuffer: String

    /// Index of the currently highlighted candidate.
    public let selectedIndex: Int

    /// Color palette from the active theme.
    public let palette: KeyboardColorPalette

    /// Callback when the user taps the candidate at `index`.
    public let onTap: (Int) -> Void

    public init(
        candidates: [String],
        rawBuffer: String = "",
        selectedIndex: Int = 0,
        palette: KeyboardColorPalette = Theme.palette,
        onTap: @escaping (Int) -> Void
    ) {
        self.candidates = candidates
        self.rawBuffer = rawBuffer
        self.selectedIndex = selectedIndex
        self.palette = palette
        self.onTap = onTap
    }

    private var hasAnyCandidate: Bool {
        candidates.contains { !$0.isEmpty }
    }

    public var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<3, id: \.self) { i in
                candidateCell(at: i)

                if i < 2 {
                    Rectangle()
                        .fill(palette.candidateDivider)
                        .frame(width: 0.75)
                        .frame(maxHeight: .infinity)
                        .padding(.vertical, 11)
                        .opacity(hasAnyCandidate ? 1 : 0)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(palette.candidateBarBackground)
        .animation(.easeOut(duration: 0.12), value: hasAnyCandidate)
    }

    @ViewBuilder
    private func candidateCell(at index: Int) -> some View {
        let hasItem = index < candidates.count && !candidates[index].isEmpty
        let text = hasItem ? candidates[index] : ""
        let isSelected = index == selectedIndex && hasItem

        // The literal phonetic reading is quoted, matching the design's “The”.
        let displayText: String = {
            guard hasItem else { return "" }
            if index == 0, !rawBuffer.isEmpty, text.lowercased() == rawBuffer.lowercased() {
                return "\u{201C}\(text)\u{201D}"
            }
            return text
        }()

        Button {
            guard hasItem else { return }
            onTap(index)
        } label: {
            ZStack {
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
                    .minimumScaleFactor(0.65)
                    .padding(.horizontal, 10)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!hasItem)
        .accessibilityLabel(hasItem ? "Suggestion \(text)" : "Empty suggestion")
        .accessibilityHidden(!hasItem)
    }
}
