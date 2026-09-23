//
//  CheatSheetTests.swift
//  LekhiTests
//
//  The cheat sheet is a promise: type this, get that. These tests hold it to
//  the engine, so an entry cannot drift away from what Lekhi actually types.
//

import XCTest
@testable import Lekhi

final class CheatSheetTests: XCTestCase {

    /// Spellings that only take their documented shape after a consonant —
    /// the folas and the reph. On their own they mean something else, so each
    /// is checked through the worked example its own tip gives.
    private static let contextualSpellings: Set<String> = ["w", "y", "z", "rr", "rri"]

    private static let workedExamples: [(latin: String, expected: String)] = [
        ("SaSwoto", "শাশ্বত"),      // w — bo-fola
        ("bzbohar", "ব্যবহার"),     // z — jo-fola
        ("korrmo", "কর্ম"),         // rr — reph
        ("rriN", "ঋণ"),
        ("brritto", "বৃত্ত"),
        ("oNggo", "অঙ্গ"),
        ("bOIShNb", "বৈষ্ণব"),
        ("lokkhNOU", "লক্ষ্ণৌ"),
        ("swamee", "স্বামী")
    ]

    private func makeEngine() throws -> LekhiEngine {
        guard let engine = LekhiEngineFactory.make(layout: .avroPhonetic, mode: .phoneticFirst) else {
            throw XCTSkip("Transliteration engine unavailable in this test host")
        }
        return engine
    }

    private func compose(_ latin: String, with engine: LekhiEngine) -> Suggestion {
        engine.finishSession()
        var last = Suggestion.empty
        for character in latin {
            last = engine.handleKey(character)
        }
        return last
    }

    /// Every conjunct the sheet documents standalone must actually come out of
    /// the engine — as the default reading, or at least offered in the bar.
    func testDocumentedConjunctsMatchTheEngine() throws {
        let engine = try makeEngine()
        defer { engine.teardown() }

        for entry in CheatSheetView.entries where entry.category.hasPrefix("Conjuncts") {
            let spellings = entry.latin
                .split(separator: "/")
                .map { $0.trimmingCharacters(in: .whitespaces) }

            for spelling in spellings where !Self.contextualSpellings.contains(spelling) {
                let result = compose(spelling, with: engine)
                XCTAssertTrue(
                    result.top == entry.bangla || result.candidates.contains(entry.bangla),
                    "cheat sheet says \(spelling) -> \(entry.bangla), engine gave \(result.top) \(result.candidates.prefix(3))"
                )
            }
        }
    }

    /// The worked examples in the tips, including the ones the contextual
    /// entries rely on to make sense.
    func testWorkedExamplesProduceWhatTheyDocument() throws {
        let engine = try makeEngine()
        defer { engine.teardown() }

        for example in Self.workedExamples {
            XCTAssertEqual(
                compose(example.latin, with: engine).top,
                example.expected,
                "cheat sheet example \(example.latin)"
            )
        }
    }

    func testEveryEntryHasACategoryTheFilterOffers() {
        let offered = Set(CheatSheetView.categories)
        for entry in CheatSheetView.entries {
            XCTAssertTrue(offered.contains(entry.category), "orphan category: \(entry.category)")
        }
    }
}
