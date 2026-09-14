//
//  EmojiRecentsStore.swift
//  SharedKit
//
//  Recently used emoji, shared between the host app and keyboard extension.
//

import Foundation

public enum EmojiRecentsStore {
    private static let key = "LekhiEmojiRecents"
    private static let maxCount = 32

    public static func current() -> [String] {
        AppGroup.defaults.stringArray(forKey: key) ?? []
    }

    public static func record(_ emoji: String) {
        let trimmed = emoji.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        var items = current().filter { $0 != trimmed }
        items.insert(trimmed, at: 0)
        if items.count > maxCount {
            items = Array(items.prefix(maxCount))
        }
        AppGroup.defaults.set(items, forKey: key)
    }

    public static func items() -> [EmojiItem] {
        current().map { EmojiItem($0, "Recent", ["recent"], .smileys) }
    }
}
