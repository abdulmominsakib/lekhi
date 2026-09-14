//
//  EmojiPickerView.swift
//  LekhiKeyboard
//
//  Apple-style emoji keyboard: search, 4-row viewport, bottom category strip.
//

import SwiftUI

/// Tab strip selection: Recents plus the standard emoji categories.
private enum EmojiPickerTab: Hashable {
    case recents
    case category(EmojiCategory)

    var icon: String {
        switch self {
        case .recents: return "🕐"
        case .category(let cat): return cat.icon
        }
    }
}

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

    @State private var searchText: String = ""
    @State private var selectedTab: EmojiPickerTab
    @FocusState private var isSearchFocused: Bool

    private var height: KeyboardHeightOption { session.heightOption }

    private var columns: [GridItem] {
        Array(
            repeating: GridItem(.flexible(), spacing: 0),
            count: height.emojiColumnCount
        )
    }

    private var tabs: [EmojiPickerTab] {
        [.recents] + EmojiCategory.allCases.map { .category($0) }
    }

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
        let recents = EmojiRecentsStore.current()
        _selectedTab = State(initialValue: recents.isEmpty ? .category(.smileys) : .recents)
    }

    private var displayedEmojis: [EmojiItem] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !query.isEmpty {
            return EmojiCatalog.search(query: query)
        }
        switch selectedTab {
        case .recents:
            return EmojiRecentsStore.items()
        case .category(let cat):
            return EmojiCatalog.items(for: cat)
        }
    }

    private var isSearching: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    public var body: some View {
        VStack(spacing: 6) {
            searchBar
            emojiScrollView
            categoryBar
        }
        .padding(.horizontal, 4)
        .padding(.top, 4)
        .padding(.bottom, max(Theme.bottomInset, 2))
        .onChange(of: isSearchFocused) { _, focused in
            guard focused else { return }
            // Typing into the search field needs letter keys; leave emoji chrome
            // and keep a live query on the session for KeyRouter.
            session.emojiSearchQuery = searchText
            session.isEmojiSearchActive = true
            onDismiss()
        }
    }

    private func feedback(isAction: Bool) {
        MechanicalSoundManager.shared.playKeyPress(isSpace: false, isModifier: isAction)
        HapticManager.shared.keyPress(isAction: isAction)
    }

    private func insertEmoji(_ emoji: String) {
        feedback(isAction: false)
        EmojiRecentsStore.record(emoji)
        onInsert(emoji)
    }

    // MARK: - Search

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(palette.candidateText.opacity(0.55))

            TextField("Search Emoji", text: $searchText)
                .font(.system(size: 16))
                .foregroundStyle(palette.keyForeground)
                .focused($isSearchFocused)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(palette.candidateText.opacity(0.45))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .frame(height: height.emojiSearchBarHeight)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(palette.keyPressedFace.opacity(0.65))
        )
    }

    // MARK: - Grid (exactly 4 rows visible, Apple-sized glyphs)

    private var emojiScrollView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            if displayedEmojis.isEmpty {
                VStack(spacing: 6) {
                    Text(isSearching ? "No emojis found" : "No Recent Emoji")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(palette.candidateText.opacity(0.55))
                        .padding(.top, 28)
                }
                .frame(maxWidth: .infinity)
                .frame(height: height.emojiGridViewportHeight)
            } else {
                LazyVGrid(columns: columns, spacing: height.emojiRowSpacing) {
                    ForEach(displayedEmojis) { item in
                        Button {
                            insertEmoji(item.emoji)
                        } label: {
                            Text(item.emoji)
                                .font(.system(size: height.emojiFontSize))
                                .frame(maxWidth: .infinity)
                                .frame(height: height.emojiRowHeight)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .frame(height: height.emojiGridViewportHeight)
    }

    // MARK: - Bottom category strip (Apple-style)

    private var categoryBar: some View {
        HStack(spacing: 0) {
            Button {
                feedback(isAction: true)
                onDismiss()
            } label: {
                Text("ABC")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(palette.actionKeyForeground)
                    .frame(width: 44, height: 34)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(palette.actionKeyFaceTop)
                    )
            }
            .buttonStyle(.plain)
            .padding(.trailing, 4)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 2) {
                    ForEach(tabs, id: \.self) { tab in
                        let isSelected = !isSearching && selectedTab == tab
                        Button {
                            searchText = ""
                            selectedTab = tab
                            HapticManager.shared.candidateSelected()
                            MechanicalSoundManager.shared.playKeyPress(isModifier: true)
                        } label: {
                            Text(tab.icon)
                                .font(.system(size: 20))
                                .frame(width: 34, height: 34)
                                .background(
                                    Circle()
                                        .fill(isSelected ? palette.candidateSelectedFill : Color.clear)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Button {
                feedback(isAction: true)
                onDelete()
            } label: {
                Image(systemName: "delete.backward")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(palette.actionKeyForeground)
                    .frame(width: 40, height: 34)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(palette.actionKeyFaceTop)
                    )
            }
            .buttonStyle(.plain)
            .padding(.leading, 4)
        }
        .frame(height: height.emojiCategoryBarHeight)
    }
}

// MARK: - Emoji search overlay (letter keys below)

/// Shown when the user taps Search Emoji: filtered results above the letter grid.
public struct EmojiSearchHeaderView: View {
    @Bindable public var session: InputSession
    public let palette: KeyboardColorPalette
    public let onInsert: (String) -> Void
    public let onCancel: () -> Void

    private var height: KeyboardHeightOption { session.heightOption }

    private var columns: [GridItem] {
        Array(
            repeating: GridItem(.flexible(), spacing: 0),
            count: height.emojiColumnCount
        )
    }

    public init(
        session: InputSession,
        palette: KeyboardColorPalette,
        onInsert: @escaping (String) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.session = session
        self.palette = palette
        self.onInsert = onInsert
        self.onCancel = onCancel
    }

    private var results: [EmojiItem] {
        EmojiCatalog.search(query: session.emojiSearchQuery)
    }

    public var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(palette.candidateText.opacity(0.55))

                Text(session.emojiSearchQuery.isEmpty ? "Search Emoji" : session.emojiSearchQuery)
                    .font(.system(size: 16))
                    .foregroundStyle(
                        session.emojiSearchQuery.isEmpty
                        ? palette.candidateText.opacity(0.45)
                        : palette.keyForeground
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)

                Button {
                    onCancel()
                } label: {
                    Text("Cancel")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(palette.keyForeground)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .frame(height: height.emojiSearchBarHeight)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(palette.keyPressedFace.opacity(0.65))
            )

            ScrollView(.vertical, showsIndicators: false) {
                if results.isEmpty {
                    Text(session.emojiSearchQuery.isEmpty ? "Type to search" : "No emojis found")
                        .font(.system(size: 13))
                        .foregroundStyle(palette.candidateText.opacity(0.5))
                        .frame(maxWidth: .infinity)
                        .padding(.top, 12)
                } else {
                    LazyVGrid(columns: columns, spacing: height.emojiRowSpacing) {
                        ForEach(results) { item in
                            Button {
                                MechanicalSoundManager.shared.playKeyPress(isModifier: false)
                                HapticManager.shared.keyPress(isAction: false)
                                EmojiRecentsStore.record(item.emoji)
                                onInsert(item.emoji)
                            } label: {
                                Text(item.emoji)
                                    .font(.system(size: height.emojiFontSize * 0.9))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: height.emojiRowHeight * 0.85)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .frame(height: height.emojiRowHeight * 2 + height.emojiRowSpacing)
        }
        .padding(.horizontal, 4)
        .padding(.top, 4)
    }
}
