//
//  PinnedKeywordsStore.swift
//  SharedKit
//
//  Favourite / pinned keywords shown in the suggestion bar while idle
//  (before the user starts typing a word). Shared between the host app
//  and the keyboard extension via the App Group.
//

import Foundation

public enum PinnedKeywordsStore {
    private static let key = "LekhiPinnedKeywords"
    public static let maxCount = 3

    /// Sensible Bangla defaults for a fresh install.
    public static let defaults: [String] = ["আমি", "আপনি", "ধন্যবাদ"]

    /// Non-empty keywords for the idle suggestion bar (at most three).
    public static func current() -> [String] {
        let stored = AppGroup.defaults.stringArray(forKey: key)
        let raw = stored ?? defaults
        return compacted(raw)
    }

    /// Three edit slots for Settings — pads with empty strings so field
    /// positions stay stable while the user is typing.
    public static func editableSlots() -> [String] {
        padded(current())
    }

    public static func set(_ keywords: [String]) {
        AppGroup.defaults.set(compacted(keywords), forKey: key)
        postSettingsChanged()
    }

    public static func resetToDefaults() {
        set(defaults)
    }

    private static func compacted(_ keywords: [String]) -> [String] {
        var seen = Set<String>()
        var result: [String] = []
        for keyword in keywords {
            let trimmed = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty, !seen.contains(trimmed) else { continue }
            seen.insert(trimmed)
            result.append(trimmed)
            if result.count == maxCount { break }
        }
        return result
    }

    private static func padded(_ keywords: [String]) -> [String] {
        var result = Array(keywords.prefix(maxCount))
        while result.count < maxCount { result.append("") }
        return result
    }
}
