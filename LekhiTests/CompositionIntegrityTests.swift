//
//  CompositionIntegrityTests.swift
//  LekhiTests
//
//  riti builds a word out of the keys it sees inside one input session. These
//  tests pin what happens when that session is broken part-way through, which
//  is the damage a spurious reconcile does and the reason it must not fire
//  while the keyboard's own edits are still in flight.
//

import XCTest
@testable import Lekhi

final class CompositionIntegrityTests: XCTestCase {

    private func makeEngine() throws -> LekhiEngine {
        guard let engine = LekhiEngineFactory.make(layout: .avroPhonetic, mode: .phoneticFirst) else {
            throw XCTSkip("Transliteration engine unavailable in this test host")
        }
        return engine
    }

    /// Feed `latin` in one session.
    private func compose(_ latin: String, with engine: LekhiEngine) -> Suggestion {
        engine.finishSession()
        var last = Suggestion.empty
        for character in latin {
            last = engine.handleKey(character)
        }
        return last
    }

    /// Feed `latin`, ending the session after `breakAfter` keys — what a
    /// mid-word teardown does to the word.
    private func composeBroken(_ latin: String, breakAfter: Int, with engine: LekhiEngine) -> String {
        engine.finishSession()
        var pieces: [String] = []
        var current = Suggestion.empty
        for (offset, character) in latin.enumerated() {
            if offset == breakAfter {
                pieces.append(current.top)
                engine.finishSession()
            }
            current = engine.handleKey(character)
        }
        pieces.append(current.top)
        return pieces.joined()
    }

    // MARK: - One session per word

    func testWordComposedInOneSessionIsCorrect() throws {
        let engine = try makeEngine()
        defer { engine.teardown() }

        XCTAssertEqual(compose("bangla", with: engine).top, "বাংলা")
        XCTAssertEqual(compose("swamee", with: engine).top, "স্বামী")
    }

    /// The exact corruption the user sees: the vowel sign that should have
    /// joined the previous consonant becomes a standalone vowel instead.
    func testSessionBrokenMidWordCorruptsTheWord() throws {
        let engine = try makeEngine()
        defer { engine.teardown() }

        XCTAssertEqual(composeBroken("bangla", breakAfter: 1, with: engine), "বআংলা")
        XCTAssertNotEqual(composeBroken("bangla", breakAfter: 1, with: engine), "বাংলা")
    }

    /// A conjunct is built from consonants seen inside one session, so a break
    /// anywhere before it is finished loses the ligature for good.
    func testConjunctNeedsASingleSession() throws {
        let engine = try makeEngine()
        defer { engine.teardown() }

        // Checked in scalars, not characters: the hasanta is a combining mark
        // and lives *inside* a grapheme cluster, so `contains` would never
        // find it as a Character of its own.
        let whole = compose("swamee", with: engine).top
        XCTAssertTrue(whole.hasHasanta, "expected a hasanta-joined conjunct in \(whole)")

        let broken = composeBroken("swamee", breakAfter: 1, with: engine)
        XCTAssertFalse(broken.hasHasanta, "conjunct survived a broken session: \(broken)")
    }

    // MARK: - Hasanta (Ridmik's `hs`)

    /// Between two consonants `hs` is Ridmik's hand-made conjunct: the
    /// hasanta must *join* them, so s + hs + b is স্ব — not স্‌ব, which is
    /// what Avro's `,,` gives on its own.
    func testHasantaBetweenConsonantsJoinsThem() throws {
        let engine = try makeEngine()
        defer { engine.teardown() }

        let result = compose("shsbamI", with: engine)
        XCTAssertEqual(result.top, "স্বামী")
        XCTAssertFalse(result.top.unicodeScalars.contains { $0.value == 0x200C },
                       "a zero-width non-joiner is keeping the conjunct apart")
        XCTAssertEqual(result.candidates.filter { $0 == "স্বামী" }.count, 1,
                       "joining should not leave the same word in the bar twice")
    }

    /// The Latin fallback in the bar must be what the user typed, not the
    /// shortcut-rewritten buffer riti holds — tapping it inserts that text.
    func testLatinFallbackShowsWhatWasTyped() throws {
        let engine = try makeEngine()
        defer { engine.teardown() }

        for latin in ["shsbamI", "allahhs", "caqqd"] {
            let candidates = compose(latin, with: engine).candidates
            XCTAssertFalse(candidates.contains { $0.contains(",,") || $0.contains("^") },
                           "\(latin): rewrite leaked into the bar \(candidates)")
        }
    }

    /// At the end of a word `hs` shows the sign, exactly as before.
    func testHasantaAtTheEndOfAWordShowsTheSign() throws {
        let engine = try makeEngine()
        defer { engine.teardown() }

        XCTAssertEqual(compose("hs", with: engine).top, "\u{09CD}\u{200C}")
        XCTAssertEqual(compose("allahhs", with: engine).top, "আল্লাহ্\u{200C}")
    }

    /// After a vowel `hs` is just h and s — names like আহসান depend on it.
    func testHSAfterAVowelIsLeftAlone() throws {
        let engine = try makeEngine()
        defer { engine.teardown() }

        XCTAssertFalse(compose("ahsan", with: engine).top.hasHasanta)
    }

    /// Typing `,,` asks for the non-joiner on purpose, so it is kept.
    func testExplicitAvroHasantaKeepsItsNonJoiner() throws {
        let engine = try makeEngine()
        defer { engine.teardown() }

        XCTAssertEqual(compose("s,,bamee", with: engine).top, "স্\u{200C}বামী")
    }

    /// The same hand-made conjunct typed at speed through the keyboard.
    func testHandJoinedConjunctThroughTheKeyboard() throws {
        let engine = try makeEngine()
        defer { engine.teardown() }

        let rig = TypingRig(engine: engine)
        rig.type("shsbamI")

        XCTAssertEqual(rig.text, "স্বামী")
        XCTAssertTrue(rig.session.hasActiveSession)
    }

    // MARK: - Visarga

    /// The ঃ key used to end the composition like punctuation, so দুঃখ came
    /// out as দুঃ plus a separate word খো.
    func testWordKeepsComposingThroughTheVisargaKey() throws {
        let engine = try makeEngine()
        defer { engine.teardown() }

        let rig = TypingRig(engine: engine)
        rig.type("du")
        rig.strike(.character("ঃ"))
        rig.type("kho")

        XCTAssertEqual(rig.text, "দুঃখ")
        XCTAssertTrue(rig.session.hasActiveSession, "the visarga ended the word")
        XCTAssertEqual(rig.session.buffer, "du:kho")
    }
}

private extension String {
    /// Whether any scalar is the Bengali hasanta that joins a conjunct.
    var hasHasanta: Bool {
        unicodeScalars.contains { $0.value == 0x09CD }
    }
}
