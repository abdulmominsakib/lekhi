//
//  SuggestionBarTests.swift
//  LekhiTests
//
//  What the suggestion bar offers, and in what order: favourites first, the
//  engine's readings next, built-in everyday phrases last — and more than
//  three of them, since the bar scrolls.
//

import XCTest
@testable import Lekhi

final class SuggestionBarTests: XCTestCase {

    private func session(layout: Layout = .avroPhonetic, pinned: [String] = []) -> InputSession {
        InputSession(layout: layout, mode: .phoneticFirst, pinnedKeywords: pinned)
    }

    // MARK: - More than three

    /// The bar scrolls now, so the engine is no longer cut to three readings.
    func testEngineOffersMoreThanThreeReadings() throws {
        guard let engine = LekhiEngineFactory.make(layout: .avroPhonetic, mode: .phoneticFirst) else {
            throw XCTSkip("Transliteration engine unavailable in this test host")
        }
        defer { engine.teardown() }

        let rig = TypingRig(engine: engine)
        rig.type("ami")

        XCTAssertGreaterThan(rig.session.candidates.count, 3, "\(rig.session.candidates)")
        XCTAssertLessThanOrEqual(rig.session.candidates.count, Suggestion.maxBarCount)
    }

    func testEnglishOffersMoreThanThree() {
        let words = EnglishSuggestionService.suggestions(for: "th")
        XCTAssertGreaterThan(words.count, 3, "\(words)")
        XCTAssertLessThanOrEqual(words.count, Suggestion.maxBarCount)
    }

    // MARK: - Idle bar

    /// With nothing typed, nothing built in is relevant — only favourites.
    func testIdleBarShowsOnlyFavourites() {
        XCTAssertEqual(session(pinned: ["আমার নাম", "ধন্যবাদ"]).idleCandidates, ["আমার নাম", "ধন্যবাদ"])
        XCTAssertEqual(session().idleCandidates, [])
        XCTAssertEqual(session(layout: .english, pinned: ["hello"]).idleCandidates, ["hello"])
    }

    func testEnglishIdleBarGetsNoBanglaPhrases() {
        let idle = session(layout: .english).idleCandidates
        XCTAssertFalse(idle.contains { $0.unicodeScalars.contains { (0x0980...0x09FF).contains($0.value) } })
    }

    // MARK: - Completions while typing

    /// Built-in phrases come after the engine's readings, so the reading in the
    /// document keeps its place at the front of the bar.
    func testPhraseCompletionsFollowTheEngine() {
        let s = session()
        s.committedBengali = "আলহাম"
        s.candidates = ["আলহাম", "আলহামদ"]
        s.hasActiveSession = true

        XCTAssertEqual(Array(s.barCandidates.prefix(2)), ["আলহাম", "আলহামদ"])
        XCTAssertEqual(s.barCandidates.last, "আলহামদুলিল্লাহ")
    }

    func testTappingAPhraseReplacesTheWordLikeAFavourite() {
        let s = session()
        s.committedBengali = "আলহাম"
        s.candidates = ["আলহাম"]
        s.hasActiveSession = true

        XCTAssertEqual(s.barChoice(at: 0), .engineCandidate(0))
        XCTAssertEqual(s.barChoice(at: 1), .savedWord("আলহামদুলিল্লাহ"))
        XCTAssertNil(s.barChoice(at: s.barCandidates.count))
    }

    func testFavouritesStillLeadAndEngineIndexStillMaps() {
        let s = session(pinned: ["আলহামদুলিল্লাহ ভাই"])
        s.committedBengali = "আলহাম"
        s.candidates = ["আলহাম"]
        s.hasActiveSession = true

        XCTAssertEqual(s.barChoice(at: 0), .savedWord("আলহামদুলিল্লাহ ভাই"))
        XCTAssertEqual(s.barChoice(at: 1), .engineCandidate(0))
        XCTAssertEqual(s.barChoice(at: 2), .savedWord("আলহামদুলিল্লাহ"))
    }

    /// A phrase the engine already offers isn't listed a second time.
    func testPhraseAlreadyOfferedByTheEngineIsNotRepeated() {
        let s = session()
        s.committedBengali = "আলহাম"
        s.candidates = ["আলহাম", "আলহামদুলিল্লাহ"]
        s.hasActiveSession = true

        XCTAssertEqual(s.barCandidates.filter { $0 == "আলহামদুলিল্লাহ" }.count, 1)
    }

    func testShortPrefixDoesNotFloodTheBar() {
        let s = session()
        s.committedBengali = "আ"
        s.candidates = ["আ"]
        s.hasActiveSession = true

        XCTAssertLessThanOrEqual(s.commonPhraseMatches.count, CommonPhrases.maxCompletions)
    }

    /// A phrase is only offered once a fair share of it is typed: আ alone is
    /// not a reason to suggest আসসালামু আলাইকুম.
    func testPhrasesNeedAQuarterTypedBeforeTheyAreOffered() {
        let s = session(pinned: ["আসসালামু আলাইকুম ভাই"])
        s.committedBengali = "আ"
        s.candidates = ["আ"]
        s.hasActiveSession = true
        XCTAssertFalse(s.commonPhraseMatches.contains("আসসালামু আলাইকুম"), "\(s.commonPhraseMatches)")
        XCTAssertTrue(s.savedWordMatches.isEmpty, "\(s.savedWordMatches)")

        s.committedBengali = "আসসালা"
        s.candidates = ["আসসালা"]
        XCTAssertTrue(s.commonPhraseMatches.contains("আসসালামু আলাইকুম"), "\(s.commonPhraseMatches)")
        XCTAssertEqual(s.savedWordMatches, ["আসসালামু আলাইকুম ভাই"])
    }

    func testEnglishGetsNoPhraseCompletions() {
        let s = session(layout: .english)
        s.buffer = "a"
        s.candidates = ["a"]
        XCTAssertTrue(s.commonPhraseMatches.isEmpty)
    }

    /// `ami` is written অমি in phonetic-first mode, but the engine also offers
    /// আমি — and phrases that start with it should follow.
    func testPhrasesMatchTheEnginesReadingsNotJustTheLiteral() {
        let s = session()
        s.committedBengali = "অমি"
        s.candidates = ["অমি", "আমি", "আমই"]
        s.hasActiveSession = true

        XCTAssertTrue(s.commonPhraseMatches.contains("আমি ভালো আছি"), "\(s.commonPhraseMatches)")
        XCTAssertFalse(s.commonPhraseMatches.contains("আমি তোমাকে ভালোবাসি"), "too little of it typed yet")
        XCTAssertFalse(s.commonPhraseMatches.contains("আমি"), "a reading already in the bar was repeated")
    }

    // MARK: - The list itself

    func testPhraseListIsClean() {
        let list = CommonPhrases.bangla
        XCTAssertEqual(list.count, Set(list).count, "duplicate built-in phrase")
        for phrase in list {
            XCTAssertEqual(phrase, phrase.trimmingCharacters(in: .whitespacesAndNewlines))
            XCTAssertFalse(phrase.isEmpty)
            XCTAssertTrue(phrase.unicodeScalars.contains { (0x0980...0x09FF).contains($0.value) }, phrase)
        }
    }
}
