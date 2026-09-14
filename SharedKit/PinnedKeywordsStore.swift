//
//  PinnedKeywordsStore.swift
//  SharedKit
//
//  Favourite / pinned keywords shown in the suggestion bar while idle
//  (before the user starts typing a word). Shared between the host app
//  and the keyboard extension via the App Group.
//
//  The list is ordered: the first three fill the bar, the rest are a swipe
//  away. New favourites go to the front so the one just saved is visible the
//  next time the bar is idle.
//

import Foundation

public enum PinnedKeywordsStore {
    private static let key = "LekhiPinnedKeywords"

    /// Upper bound on the whole list. Generous for hand-curated words while
    /// keeping a bulk import from bloating the shared defaults the keyboard
    /// reads on every appearance.
    public static let maxCount = 500

    /// Longest keyword accepted, in characters.
    public static let maxKeywordLength = 100

    /// Sensible Bangla defaults for a fresh install.
    public static let defaults: [String] = ["আমি", "আপনি", "ধন্যবাদ"]

    public enum AddResult: Equatable, Sendable {
        case added
        case alreadySaved
        case full
        case invalid
    }

    /// Every favourite, in bar order.
    public static func current() -> [String] {
        let stored = AppGroup.defaults.stringArray(forKey: key)
        let raw = stored ?? defaults
        return compacted(raw)
    }

    public static func set(_ keywords: [String]) {
        AppGroup.defaults.set(compacted(keywords), forKey: key)
        postSettingsChanged()
    }

    public static func contains(_ keyword: String) -> Bool {
        guard let normalized = normalized(keyword) else { return false }
        return current().contains(normalized)
    }

    /// Save a keyword at the front of the list.
    @discardableResult
    public static func add(_ keyword: String) -> AddResult {
        guard let normalized = normalized(keyword) else { return .invalid }
        var list = current()
        guard !list.contains(normalized) else { return .alreadySaved }
        guard list.count < maxCount else { return .full }
        list.insert(normalized, at: 0)
        set(list)
        return .added
    }

    public static func resetToDefaults() {
        set(defaults)
    }

    /// Trimmed keyword, or `nil` when it is empty or too long to be a keyword.
    public static func normalized(_ keyword: String) -> String? {
        let trimmed = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed.count <= maxKeywordLength else { return nil }
        return trimmed
    }

    private static func compacted(_ keywords: [String]) -> [String] {
        var seen = Set<String>()
        var result: [String] = []
        for keyword in keywords {
            guard let trimmed = normalized(keyword), !seen.contains(trimmed) else { continue }
            seen.insert(trimmed)
            result.append(trimmed)
            if result.count == maxCount { break }
        }
        return result
    }
}

// MARK: - JSON import / export

public extension PinnedKeywordsStore {

    /// On-disk shape written by export. Import also accepts a bare
    /// `["আমি", "আপনি"]` array, which is easier to write by hand.
    struct ExportFile: Codable, Sendable {
        public var app: String
        public var version: Int
        public var exportedAt: Date
        public var keywords: [String]
    }

    enum ImportError: LocalizedError, Equatable {
        case notJSON
        case unsupportedShape
        case noKeywords

        public var errorDescription: String? {
            switch self {
            case .notJSON:
                return "The file isn't valid JSON."
            case .unsupportedShape:
                return "Expected a list of words, like [\"আমি\", \"আপনি\"], or an object with a \"keywords\" list."
            case .noKeywords:
                return "The file doesn't contain any keywords."
            }
        }
    }

    struct ImportSummary: Equatable, Sendable {
        /// The list to store after merging or replacing.
        public let keywords: [String]
        public let added: Int
        public let duplicates: Int
        /// Entries that were not strings, empty, or too long.
        public let invalid: Int
        /// Valid new keywords dropped because the list hit `maxCount`.
        public let overLimit: Int
    }

    static func exportData(_ keywords: [String], date: Date = Date()) throws -> Data {
        let file = ExportFile(app: "Lekhi", version: 1, exportedAt: date, keywords: compacted(keywords))
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(file)
    }

    /// Raw entries from an import file, before validation. Non-string entries
    /// come back as `nil` so they can be counted as invalid.
    static func decodeImport(_ data: Data) throws -> [String?] {
        let object: Any
        do {
            object = try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
        } catch {
            throw ImportError.notJSON
        }

        let entries: [Any]
        if let array = object as? [Any] {
            entries = array
        } else if let dict = object as? [String: Any],
                  let array = (dict["keywords"] ?? dict["favourites"] ?? dict["favorites"]) as? [Any] {
            entries = array
        } else {
            throw ImportError.unsupportedShape
        }

        guard !entries.isEmpty else { throw ImportError.noKeywords }
        return entries.map { $0 as? String }
    }

    /// Fold imported entries into `existing`. Merging keeps the current order
    /// and appends new words; replacing uses the file's order.
    static func importing(_ entries: [String?], into existing: [String], replace: Bool) throws -> ImportSummary {
        var list = replace ? [] : compacted(existing)
        var seen = Set(list)
        var added = 0, duplicates = 0, invalid = 0, overLimit = 0

        for entry in entries {
            guard let entry, let keyword = normalized(entry) else {
                invalid += 1
                continue
            }
            guard !seen.contains(keyword) else {
                duplicates += 1
                continue
            }
            guard list.count < maxCount else {
                overLimit += 1
                continue
            }
            seen.insert(keyword)
            list.append(keyword)
            added += 1
        }

        guard added > 0 || !replace else { throw ImportError.noKeywords }
        return ImportSummary(keywords: list, added: added, duplicates: duplicates, invalid: invalid, overLimit: overLimit)
    }
}
