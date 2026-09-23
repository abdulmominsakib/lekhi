//
//  RidmikConformanceTests.swift
//  LekhiTests
//
//  Ridmik Keyboard is how most people in Bangladesh learned phonetic typing,
//  so its published rule table is what Lekhi's users actually type. Every rule
//  here is one row of that table; a failure means someone typing what Ridmik
//  taught them gets something else from Lekhi.
//

import XCTest
@testable import Lekhi

final class RidmikConformanceTests: XCTestCase {

    struct Rule {
        let latin: String
        let bangla: String
        let group: String
    }

    static let letters: [Rule] = [
        ("o", "অ"), ("a", "আ"), ("i", "ই"), ("I", "ঈ"), ("u", "উ"), ("U", "ঊ"),
        ("rri", "ঋ"), ("e", "এ"), ("OI", "ঐ"), ("O", "ও"), ("OU", "ঔ"),
        ("k", "ক"), ("kh", "খ"), ("g", "গ"), ("gh", "ঘ"), ("Ng", "ঙ"),
        ("c", "চ"), ("ch", "ছ"), ("j", "জ"), ("jh", "ঝ"), ("NG", "ঞ"),
        ("T", "ট"), ("Th", "ঠ"), ("D", "ড"), ("Dh", "ঢ"), ("N", "ণ"),
        ("t", "ত"), ("th", "থ"), ("d", "দ"), ("dh", "ধ"), ("n", "ন"),
        ("p", "প"), ("f", "ফ"), ("ph", "ফ"), ("b", "ব"), ("v", "ভ"), ("bh", "ভ"),
        ("m", "ম"), ("z", "য"), ("r", "র"), ("l", "ল"),
        ("S", "শ"), ("sh", "শ"), ("Sh", "ষ"), ("s", "স"), ("h", "হ"),
        ("R", "ড়"), ("Rh", "ঢ়"), ("y", "য়"), ("TH", "ৎ"), ("ng", "ং")
    ].map { Rule(latin: $0.0, bangla: $0.1, group: "letter") }

    static let kars: [Rule] = [
        ("ka", "কা"), ("ki", "কি"), ("kI", "কী"), ("ku", "কু"), ("kU", "কূ"),
        ("krri", "কৃ"), ("ke", "কে"), ("kOI", "কৈ"), ("kO", "কো"), ("kOU", "কৌ")
    ].map { Rule(latin: $0.0, bangla: $0.1, group: "kar") }

    static let signs: [Rule] = [
        ("caqqd", "চাঁদ"), ("hoTaTH", "হটাৎ"), ("du:kho", "দুঃখ"),
        ("korrmo", "কর্ম"), ("allahhs", "আল্লাহ্\u{200C}"), ("promaN", "প্রমাণ"),
        ("shwashwoto", "শ্বাশ্বত"),
        ("bybohar", "ব্যবহার"), ("bzbohar", "ব্যবহার"), ("bZbohar", "ব্যবহার"),
        ("oZanimeshon", "অ্যানিমেশন"),
        ("swami", "স্বামি"), ("swamI", "স্বামী"), ("shsbamI", "স্বামী")
    ].map { Rule(latin: $0.0, bangla: $0.1, group: "sign") }

    static let conjuncts: [Rule] = [
        ("kt", "ক্ত"), ("kSh", "ক্ষ"), ("kShN", "ক্ষ্ণ"), ("kShm", "ক্ষ্ম"), ("hm", "হ্ম"),
        ("jNG", "জ্ঞ"), ("NGj", "ঞ্জ"), ("NGc", "ঞ্চ"), ("bb", "ব্ব"), ("tt", "ত্ত"),
        ("tr", "ত্র"), ("hrri", "হৃ"), ("kr", "ক্র"), ("ntr", "ন্ত্র"), ("ddh", "দ্ধ"),
        ("dv", "দ্ভ"), ("ks", "ক্স"), ("km", "ক্ম"), ("kl", "ক্ল"), ("Ngg", "ঙ্গ"),
        ("cch", "চ্ছ"), ("kk", "ক্ক"), ("gdh", "গ্ধ"), ("gm", "গ্ম"), ("gr", "গ্র"),
        ("gl", "গ্ল"), ("Ngk", "ঙ্ক"), ("Ngkh", "ঙ্খ"), ("jj", "জ্জ"), ("dm", "দ্ম"),
        ("jjw", "জ্জ্ব"), ("TT", "ট্ট"), ("nTh", "ন্ঠ"), ("tth", "ত্থ"), ("tm", "ত্ম"),
        ("ttw", "ত্ত্ব"), ("nth", "ন্থ"), ("nw", "ন্ব"), ("nm", "ন্ম"), ("ndr", "ন্দ্র"),
        ("ndh", "ন্ধ"), ("bdh", "ব্ধ"), ("vr", "ভ্র"), ("mn", "ম্ন"), ("shm", "শ্ম"),
        ("Shk", "ষ্ক"), ("ShTh", "ষ্ঠ"), ("Shp", "ষ্প"), ("Shf", "ষ্ফ"), ("ShTr", "ষ্ট্র"),
        ("ShN", "ষ্ণ"), ("Shm", "ষ্ম"), ("sth", "স্থ"), ("str", "স্ত্র"), ("skr", "স্ক্র"),
        ("spl", "স্প্ল"), ("hn", "হ্ন"), ("sf", "স্ফ"), ("cchw", "চ্ছ্ব"), ("hw", "হ্ব"),
        ("sw", "স্ব"), ("shw", "শ্ব")
    ].map { Rule(latin: $0.0, bangla: $0.1, group: "conjunct") }

    static var all: [Rule] { letters + kars + signs + conjuncts }

    private func compose(_ latin: String, with engine: LekhiEngine) -> Suggestion {
        engine.finishSession()
        var last = Suggestion.empty
        for character in latin {
            last = engine.handleKey(character)
        }
        return last
    }

    /// Rows where Lekhi knowingly differs from Ridmik's table.
    ///
    /// - `y` on its own: Ridmik gives য়. Lekhi (riti) reads a lone `y` as ইয়
    ///   and offers য় second; after a vowel `y` is য় exactly as in Ridmik
    ///   (bhoy -> ভয়), which is the case that occurs in real words.
    /// - `km`: Ridmik joins it (rukmini -> রুক্মিণী); riti keeps কম, which is
    ///   also what `km` the abbreviation needs.
    static let knownDifferences: Set<String> = ["y", "km"]

    func testLekhiTypesWhatRidmikTaught() throws {
        guard let engine = LekhiEngineFactory.make(layout: .avroPhonetic, mode: .phoneticFirst) else {
            throw XCTSkip("Transliteration engine unavailable in this test host")
        }
        defer { engine.teardown() }

        for rule in Self.all where !Self.knownDifferences.contains(rule.latin) {
            let result = compose(rule.latin, with: engine)
            XCTAssertEqual(
                result.top, rule.bangla,
                "Ridmik [\(rule.group)] \(rule.latin) -> \(rule.bangla); Lekhi gave \(result.top) \(result.candidates.prefix(3))"
            )
        }
    }

    /// Keeps the list of differences honest: if one stops being a difference,
    /// this fails so it can be moved back into the checked table.
    func testKnownDifferencesAreStillDifferent() throws {
        guard let engine = LekhiEngineFactory.make(layout: .avroPhonetic, mode: .phoneticFirst) else {
            throw XCTSkip("Transliteration engine unavailable in this test host")
        }
        defer { engine.teardown() }

        for rule in Self.all where Self.knownDifferences.contains(rule.latin) {
            XCTAssertNotEqual(compose(rule.latin, with: engine).top, rule.bangla,
                              "\(rule.latin) now matches Ridmik — remove it from knownDifferences")
        }
    }
}
