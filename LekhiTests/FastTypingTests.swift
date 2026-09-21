//
//  FastTypingTests.swift
//  LekhiTests
//
//  Typing fast is not typing more — it is keys overlapping. A finger is still
//  on one key when the next one lands, and the host app answers slower than
//  the keys arrive. These tests drive the input path with no pause at all
//  between strikes, which is the condition every bug here needed.
//

import XCTest
@testable import Lekhi

final class FastTypingTests: XCTestCase {

    // MARK: - A word arrives exactly once

    /// The composing word is re-rendered into the document on every keystroke,
    /// so the edit that does it has to delete precisely what it replaces. When
    /// it counted grapheme clusters instead of Unicode scalars, every re-render
    /// left the previous stem behind and `bangla` came out as "বববাবাবাংলা".
    func testWordTypedAtSpeedLandsInTheDocumentExactlyOnce() {
        let rig = TypingRig()

        rig.type("bangla")

        XCTAssertEqual(rig.text, "বাংলা")
    }

    /// `bang` is the interesting keystroke: it reshapes "বান" into "বাং", so
    /// the keyboard has to delete back to the shared prefix rather than append.
    func testReshapingKeystrokeReplacesRatherThanAppends() {
        let rig = TypingRig()

        rig.type("ban")
        XCTAssertEqual(rig.text, "বান")

        rig.type("g")
        XCTAssertEqual(rig.text, "বাং")
    }

    func testSentenceTypedAtSpeedKeepsEveryWordIntact() {
        let rig = TypingRig()

        rig.type("ami bangla likhi")

        XCTAssertEqual(rig.text, "আমি বাংলা লিখি")
    }

    // MARK: - Rollover: the spacebar against the next letter
    //
    // Typing fast means the space finger has not lifted when the next letter
    // lands. Every key emits on touch-down, so the router sees the keys in the
    // order they were struck — space first. The two tests below are the two
    // possible orders, and they are why that matters.

    func testSpaceStruckBeforeTheNextLetterSeparatesTheWords() {
        let rig = TypingRig()

        rig.type("ami")
        rig.strike(.space)
        rig.type("bangla")

        XCTAssertEqual(rig.text, "আমি বাংলা")
    }

    /// The old spacebar emitted on touch-*up*, so a rolled-over space arrived
    /// after the letter that was struck later. The damage is not a misplaced
    /// space: the stray `b` joins the previous word's still-open composition,
    /// so `ami bangla` becomes a different word entirely and the space lands
    /// behind it. Pinned here so the ordering cannot quietly regress.
    func testSpaceStruckAfterTheNextLetterCorruptsBothWords() {
        let rig = TypingRig()

        rig.type("ami")
        rig.strike(.character("b"))   // next key down before space came up
        rig.strike(.space)            // …space arrives late
        rig.type("angla")

        XCTAssertEqual(rig.text, "আমিব আংলা")
        XCTAssertNotEqual(rig.text, "আমি বাংলা")
    }

    // MARK: - Caps lock
    //
    // Caps lock latches on a double tap of shift. These tests need no sleeps:
    // consecutive strikes land microseconds apart, which is well inside the
    // 0.35 s window and therefore exactly the fast-typing case.

    /// Shift, a letter, shift again is ordinary fast typing in Avro, where
    /// case picks a different letter (`s` -> স but `S` -> শ). It used to latch
    /// caps lock, which silently changed every letter after it.
    func testCapsLockDoesNotLatchWhenALetterIsStruckBetweenShifts() {
        let rig = TypingRig()

        rig.strike(.shift)
        rig.strike(.character("S"))
        rig.strike(.shift)

        XCTAssertFalse(rig.session.isCapsLocked)
        XCTAssertTrue(rig.session.isShifted)
    }

    func testCapsLockDoesNotLatchAcrossAFastWord() {
        let rig = TypingRig()

        rig.strike(.shift)
        rig.type("ompurno")
        rig.strike(.shift)

        XCTAssertFalse(rig.session.isCapsLocked)
    }

    /// The behaviour that has to survive the fix: two shift taps with nothing
    /// in between still latch, the same as the system keyboard.
    func testCapsLockStillLatchesOnTwoConsecutiveShifts() {
        let rig = TypingRig()

        rig.strike(.shift)
        rig.strike(.shift)

        XCTAssertTrue(rig.session.isCapsLocked)
    }

    func testCapsLockUnlatchesOnTheNextShift() {
        let rig = TypingRig()

        rig.strike(.shift)
        rig.strike(.shift)
        XCTAssertTrue(rig.session.isCapsLocked)

        rig.strike(.shift)
        XCTAssertFalse(rig.session.isCapsLocked)
        XCTAssertFalse(rig.session.isShifted)
    }

    // MARK: - The composition surviving a lagging host
    //
    // `documentContextBeforeInput` trails the keyboard's own edits by an
    // amount the host app decides. The keyboard has to tell "you are reading
    // my last keystroke, not my current one" apart from "the host rewrote the
    // text", or it tears the word down mid-composition.

    func testLaggingContextFromAnEarlierKeystrokeIsRecognisedAsOurs() {
        let rig = TypingRig()

        rig.type("bang")

        // The host is still reporting the document as it stood two keystrokes
        // ago. That is our own edit in flight, not an external change.
        XCTAssertTrue(rig.history.recognises("বা"))
        XCTAssertTrue(rig.history.recognises("বান"))
        XCTAssertTrue(rig.history.recognises("বাং"))
    }

    func testContextTheHostRewroteIsNotRecognised() {
        let rig = TypingRig()

        rig.type("bang")

        XCTAssertFalse(rig.history.recognises("Hello world"))
        XCTAssertFalse(rig.history.recognises(""))
    }

    func testHistoryIsForgottenOnceTheWordEnds() {
        let rig = TypingRig()

        rig.type("bangla")
        XCTAssertTrue(rig.history.recognises("বাংলা"))

        rig.strike(.space)

        XCTAssertFalse(rig.history.recognises("বাংলা"))
    }

    /// Sustained typing must not let the record grow without bound.
    func testHistoryStaysBoundedUnderSustainedTyping() {
        var history = ComposingHistory()

        for index in 0..<500 {
            history.record("chunk-\(index)")
        }

        XCTAssertEqual(history.chunks.count, ComposingHistory.limit)
        XCTAssertTrue(history.recognises("chunk-499"))
    }

    func testRepeatedIdenticalChunksAreRecordedOnce() {
        var history = ComposingHistory()

        history.record("বা")
        history.record("বা")
        history.record("বা")

        XCTAssertEqual(history.chunks, ["বা"])
    }

    // MARK: - Deleting at speed

    func testBackspacingAWordAtSpeedEmptiesTheDocument() {
        let rig = TypingRig()

        rig.type("bangla")
        rig.backspace(times: 6)

        XCTAssertEqual(rig.text, "")
        XCTAssertFalse(rig.session.hasActiveSession)
    }

    func testRetypingAfterAFastBackspaceStartsACleanWord() {
        let rig = TypingRig()

        rig.type("bangla")
        rig.backspace(times: 6)
        rig.type("ami")

        XCTAssertEqual(rig.text, "আমি")
    }

    // MARK: - Volume

    /// A long burst with no pause anywhere: the document must match what the
    /// same words produce one at a time, with no drift, doubling or loss.
    func testLongBurstMatchesWordByWordTyping() {
        let words = ["ami", "bangla", "likhi", "ebong", "sundor", "hoy", "bangla"]

        let burst = TypingRig()
        burst.type(words.joined(separator: " "))

        let expected = words
            .map { word -> String in
                let single = TypingRig()
                single.type(word)
                return single.text
            }
            .joined(separator: " ")

        XCTAssertEqual(burst.text, expected)
    }

    func testCompositionStateIsCleanAfterEveryWordBoundary() {
        let rig = TypingRig()

        for _ in 0..<50 {
            rig.type("bangla")
            XCTAssertTrue(rig.session.hasActiveSession)
            rig.strike(.space)
            XCTAssertFalse(rig.session.hasActiveSession)
            XCTAssertEqual(rig.session.buffer, "")
            XCTAssertEqual(rig.session.committedBengali, "")
        }

        XCTAssertEqual(rig.text.filter { $0 == " " }.count, 50)
    }

    // MARK: - The real engine

    /// The fake engine keeps the tests above deterministic. This one checks
    /// the property that matters most against riti itself: one composition
    /// stays open for the whole word, so conjuncts and candidates survive a
    /// burst of keystrokes.
    func testRealEngineKeepsOneCompositionOpenAcrossAWholeWord() throws {
        guard let engine = LekhiEngineFactory.make(layout: .avroPhonetic, mode: .phoneticFirst) else {
            throw XCTSkip("Transliteration engine unavailable in this test host")
        }
        defer { engine.teardown() }

        let rig = TypingRig(engine: engine)
        rig.type("bangla")

        XCTAssertTrue(rig.session.hasActiveSession, "composition was torn down mid-word")
        XCTAssertEqual(rig.session.buffer, "bangla")
        XCTAssertFalse(rig.text.isEmpty)
        XCTAssertFalse(
            rig.text.contains(where: { $0.isASCII && $0.isLetter }),
            "latin leaked into the document: \(rig.text)"
        )
    }
}
