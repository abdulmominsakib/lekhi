//
//  SuggestionBarView.swift
//  LekhiKeyboard
//
//  The sleek three-slot candidate bar at the top of the mechanical keyboard.
//  Matches the design with thin vertical dividers, quote formatting for raw
//  phonetic text, and a soft highlight pill for the selected candidate.
//

import SwiftUI

public struct SuggestionBarView: View {

    /// Up to 3 candidates to display.
    public let candidates: [String]

    /// Raw input buffer for displaying phonetic quote (e.g. "ami").
    public let rawBuffer: String

    /// Index of the currently highlighted candidate.
    public let selectedIndex: Int

    /// Color palette from the active theme.
    public let palette: KeyboardColorPalette

    /// Callback when user taps candidate at `index`.
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

    public var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<3, id: \.self) { i in
                candidateCell(at: i)

                if i < 2 {
                    Rectangle()
                        .fill(palette.candidateDivider)
                        .frame(width: 0.75, height: 20)
                }
            }
        }
        .padding(.horizontal, 4)
        .frame(height: Theme.suggestionBarHeight)
        .frame(maxWidth: .infinity)
        .background(palette.candidateBarBackground)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(palette.candidateDivider.opacity(0.7))
                .frame(height: 0.5)
        }
    }

    @ViewBuilder
    private func candidateCell(at index: Int) -> some View {
        let hasItem = index < candidates.count && !candidates[index].isEmpty
        let text = hasItem ? candidates[index] : ""
        let isSelected = index == selectedIndex && hasItem

        // Format candidate text: if it's index 0 and matches raw phonetic input, wrap in quotes e.g. "The"
        let displayText: String = {
            guard hasItem else { return "" }
            if index == 0 && !rawBuffer.isEmpty && text.lowercased() == rawBuffer.lowercased() {
                return "“\(text)”"
            }
            return text
        }()

        Button {
            guard hasItem else { return }
            onTap(index)
        } label: {
            ZStack {
                if isSelected {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(palette.candidateSelectedFill)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                }

                VStack(spacing: 0) {
                    Text(displayText)
                        .font(index == 0 && displayText.hasPrefix("“") ? Theme.rawCandidateFont : Theme.candidateFont)
                        .foregroundStyle(hasItem ? palette.candidateText : Color.clear)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    if isSelected,
                       !rawBuffer.isEmpty,
                       text.caseInsensitiveCompare(rawBuffer) != .orderedSame {
                        Text(rawBuffer)
                            .font(.system(size: 8.5, weight: .medium, design: .rounded))
                            .foregroundStyle(palette.candidateText.opacity(0.52))
                            .lineLimit(1)
                    }
                }
                .padding(.horizontal, 8)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!hasItem)
        .accessibilityLabel(hasItem ? "Suggestion \(text)" : "Empty suggestion")
    }
}
