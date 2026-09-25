//
//  EnglishSuggestionService.swift
//  SharedKit
//
//  Provides autocomplete, word completion, and spelling suggestions
//  for English keyboard input using UIKit's UITextChecker.
//

import UIKit

public enum EnglishSuggestionService {

    private static let checker = UITextChecker()

    /// Generate up to `limit` English word candidates for a given typed buffer.
    public static func suggestions(for rawBuffer: String, limit: Int = Suggestion.maxBarCount) -> [String] {
        let buffer = rawBuffer.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !buffer.isEmpty else { return [] }

        let nsBuffer = buffer as NSString
        let range = NSRange(location: 0, length: nsBuffer.length)

        var results: [String] = []

        // 1. Exact typed input is always a candidate option
        results.append(buffer)

        // 2. Fetch completions for partial word range
        if let completions = checker.completions(forPartialWordRange: range, in: buffer, language: "en_US") {
            for word in completions {
                let match = matchCasing(source: buffer, target: word)
                if !results.contains(where: { $0.lowercased() == match.lowercased() }) {
                    results.append(match)
                    if results.count >= limit { break }
                }
            }
        }

        // 3. If we still need more candidates, fetch spelling guesses
        if results.count < limit {
            if let guesses = checker.guesses(forWordRange: range, in: buffer, language: "en_US") {
                for word in guesses {
                    let match = matchCasing(source: buffer, target: word)
                    if !results.contains(where: { $0.lowercased() == match.lowercased() }) {
                        results.append(match)
                        if results.count >= limit { break }
                    }
                }
            }
        }

        // 4. Common words fallback if offline or no completions
        if results.count < limit {
            for word in commonEnglishWords where word.lowercased().hasPrefix(buffer.lowercased()) {
                let match = matchCasing(source: buffer, target: word)
                if !results.contains(where: { $0.lowercased() == match.lowercased() }) {
                    results.append(match)
                    if results.count >= limit { break }
                }
            }
        }

        return Array(results.prefix(limit))
    }

    private static func matchCasing(source: String, target: String) -> String {
        guard let first = source.first else { return target }
        if source.allSatisfy({ $0.isUppercase }) && source.count > 1 {
            return target.uppercased()
        } else if first.isUppercase {
            return target.prefix(1).uppercased() + target.dropFirst().lowercased()
        }
        return target.lowercased()
    }

    /// Words the suggestion bar offers while idle on the English layout, until
    /// the user has saved enough English favourites of their own to fill it.
    public static let idleWords: [String] = ["I", "you", "thanks"]

    private static let commonEnglishWords: [String] = [
        "the", "be", "to", "of", "and", "a", "in", "that", "have", "I",
        "it", "for", "not", "on", "with", "he", "as", "you", "do", "at",
        "this", "but", "his", "by", "from", "they", "we", "say", "her", "she",
        "or", "an", "will", "my", "one", "all", "would", "there", "their", "what",
        "so", "up", "out", "if", "about", "who", "get", "which", "go", "me",
        "when", "make", "can", "like", "time", "no", "just", "him", "know", "take",
        "people", "into", "year", "your", "good", "some", "could", "them", "see", "other",
        "than", "then", "now", "look", "only", "come", "its", "over", "think", "also",
        "back", "after", "use", "two", "how", "our", "work", "first", "well", "way",
        "even", "new", "want", "because", "any", "these", "give", "day", "most", "us",
        "love", "happy", "thank", "thanks", "please", "great", "awesome", "hello", "hi", "good",
        "night", "morning", "today", "tomorrow", "tonight", "friend", "family", "bangla", "bangladesh",
        "dhaka", "beautiful", "really", "very", "much", "more", "help", "need", "feel", "look"
    ]
}
