//
//  EmojiPickerView.swift
//  LekhiKeyboard
//
//  Rich, native-styled searchable Emoji Keyboard for Lekhi.
//

import SwiftUI

public struct EmojiPickerView: View {

    @Bindable public var session: InputSession
    public let palette: KeyboardColorPalette
    public let onInsert: (String) -> Void
    public let onDelete: () -> Void
    /// Leaves emoji mode. Routed through the keyboard's action pipeline rather
    /// than flipping `session.isEmojiMode` here, so the view controller gets a
    /// chance to resize the input view — the candidate bar comes back with the
    /// letter keys, and the keyboard has to grow by its height again.
    public let onDismiss: () -> Void

    @State private var activeFilter: String = ""
    @State private var selectedCategory: EmojiCategory = .smileys

    private let quickFilters: [(label: String, query: String, icon: String)] = [
        ("Smileys", "", "😊"),
        ("Love", "love", "❤️"),
        ("Happy", "happy", "😁"),
        ("Laugh", "laugh", "😂"),
        ("Fire", "fire", "🔥"),
        ("Dua", "pray", "🤲"),
        ("Bangla", "bangla", "🇧🇩"),
        ("Food", "food", "🍕"),
        ("Sports", "sport", "⚽"),
        ("Animals", "animal", "🐱"),
        ("Party", "party", "🎉")
    ]

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)

    public init(
        session: InputSession,
        palette: KeyboardColorPalette = Theme.palette,
        onInsert: @escaping (String) -> Void,
        onDelete: @escaping () -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.session = session
        self.palette = palette
        self.onInsert = onInsert
        self.onDelete = onDelete
        self.onDismiss = onDismiss
    }

    private var displayedEmojis: [EmojiItem] {
        if !activeFilter.isEmpty {
            return EmojiCatalog.search(query: activeFilter)
        }
        return EmojiCatalog.items(for: selectedCategory)
    }

    public var body: some View {
        VStack(spacing: 5) {
            // Quick Filter Mood Chips
            quickFilterBar

            // Category Bar
            if activeFilter.isEmpty {
                categoryTabs
            }

            // Emoji Grid
            emojiScrollView

            // Bottom Navigation Bar
            bottomBar
        }
        .padding(.horizontal, 6)
        .padding(.top, 4)
        .padding(.bottom, Theme.bottomInset)
        // The root view paints the plate (or leaves it to the system
        // container); a square fill here would bring the edge back.
    }

    /// Emoji keys were silent — only the mechanical grid played a click.
    private func feedback(isAction: Bool, isSpace: Bool = false) {
        MechanicalSoundManager.shared.playKeyPress(isSpace: isSpace, isModifier: isAction)
        HapticManager.shared.keyPress(isAction: isAction)
    }

    // MARK: - Quick Filter Mood Chips

    private var quickFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(quickFilters, id: \.label) { filter in
                    let isSelected = activeFilter == filter.query && (filter.query.isEmpty ? activeFilter.isEmpty : true)

                    Button {
                        withAnimation(.easeInOut(duration: 0.12)) {
                            activeFilter = filter.query
                            if filter.query.isEmpty {
                                selectedCategory = .smileys
                            }
                        }
                        HapticManager.shared.candidateSelected()
                        MechanicalSoundManager.shared.playKeyPress(isModifier: true)
                    } label: {
                        HStack(spacing: 4) {
                            Text(filter.icon)
                                .font(.system(size: 13))
                            Text(filter.label)
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                        }
                        .foregroundStyle(isSelected ? palette.keyForeground : palette.candidateText.opacity(0.8))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(isSelected ? palette.candidateSelectedFill.opacity(1.5) : palette.keyPressedFace.opacity(0.5))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(isSelected ? palette.keyBorder.opacity(0.3) : Color.clear, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 4)
        }
    }

    // MARK: - Category Tabs

    private var categoryTabs: some View {
        HStack(spacing: 2) {
            ForEach(EmojiCategory.allCases) { cat in
                Button {
                    selectedCategory = cat
                    activeFilter = ""
                    HapticManager.shared.candidateSelected()
                    MechanicalSoundManager.shared.playKeyPress(isModifier: true)
                } label: {
                    Text(cat.icon)
                        .font(.system(size: 16))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                        .background(
                            selectedCategory == cat && activeFilter.isEmpty
                            ? RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(palette.candidateSelectedFill)
                            : nil
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 2)
    }

    // MARK: - Emoji Grid

    private var emojiScrollView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            if displayedEmojis.isEmpty {
                VStack(spacing: 6) {
                    Text("🔍")
                        .font(.system(size: 28))
                        .padding(.top, 16)
                    Text("No emojis found")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
            } else {
                LazyVGrid(columns: columns, spacing: 6) {
                    ForEach(displayedEmojis) { item in
                        Button {
                            feedback(isAction: false)
                            onInsert(item.emoji)
                        } label: {
                            Text(item.emoji)
                                .font(.system(size: 26))
                                .frame(maxWidth: .infinity, minHeight: 38)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .frame(maxHeight: 135 * session.heightOption.scaleFactor)
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        HStack(spacing: 8) {
            // ABC button to return to mechanical keyboard
            Button {
                feedback(isAction: true)
                onDismiss()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "keyboard")
                        .font(.system(size: 13))
                    Text("ABC")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundStyle(palette.actionKeyForeground)
                .frame(width: 75, height: 38)
                .background(
                    RoundedRectangle(cornerRadius: Theme.keyCornerRadius, style: .continuous)
                        .fill(palette.actionKeyFaceTop)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.keyCornerRadius, style: .continuous)
                        .stroke(palette.keyBorder, lineWidth: 0.5)
                )
            }
            .buttonStyle(.plain)

            // Spacebar in emoji mode
            Button {
                feedback(isAction: false, isSpace: true)
                onInsert(" ")
            } label: {
                Text("space")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(palette.keyForeground.opacity(0.6))
                    .frame(maxWidth: .infinity, maxHeight: 38)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.keyCornerRadius, style: .continuous)
                            .fill(palette.spacebarFace)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.keyCornerRadius, style: .continuous)
                            .stroke(palette.keyBorder, lineWidth: 0.5)
                    )
            }
            .buttonStyle(.plain)

            // Backspace in emoji mode
            Button {
                feedback(isAction: true)
                onDelete()
            } label: {
                Image(systemName: "delete.backward")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(palette.actionKeyForeground)
                    .frame(width: 55, height: 38)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.keyCornerRadius, style: .continuous)
                            .fill(palette.actionKeyFaceTop)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.keyCornerRadius, style: .continuous)
                            .stroke(palette.keyBorder, lineWidth: 0.5)
                    )
            }
            .buttonStyle(.plain)
        }
        .frame(height: 40)
    }
}
