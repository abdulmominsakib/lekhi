//
//  TypingRig.swift
//  LekhiTests
//
//  A keyboard without the keyboard: the same routing and the same document
//  edits `KeyboardViewController.dispatch` performs, driven one key strike at
//  a time so a test can express typing as the order fingers landed in.
//

import Foundation
@testable import Lekhi

// MARK: - Host document

/// Stands in for the host app's text field.
///
/// It applies exactly what `dispatch` applies to `UITextDocumentProxy`, in the
/// same unit: `deleteBackward()` removes one Unicode *scalar*, which is why a
/// Bengali letter carrying a vowel sign takes two calls to remove.
final class FakeDocument {

    private(set) var text = ""

    func apply(_ outcome: KeyOutcome) {
        switch outcome {
        case .replaceComposing(let deleteCount, let insert):
            deleteScalars(max(0, deleteCount))
            text += insert
        case .insert(let inserted):
            text += inserted
        case .deleteBackward:
            deleteScalars(1)
        case .advanceInputMode, .none:
            break
        }
    }

    private func deleteScalars(_ count: Int) {
        for _ in 0..<count {
            guard !text.isEmpty else { return }
            text.unicodeScalars.removeLast()
        }
    }
}

// MARK: - Engine

/// A deterministic stand-in for riti.
///
/// The real engine's answers come out of a 150 000-word dictionary, which
/// makes it a poor thing to assert exact strings against — a dictionary edit
/// would break tests that are really about key ordering. This one
/// transliterates from a fixed table plus two reshaping rules, which is
/// enough to exercise both shapes of document edit the keyboard performs: a
/// chunk that only grows, and a chunk whose middle changes and has to be
/// deleted back to the shared prefix.
final class FakePhoneticEngine: LekhiEngine {

    private var typed = ""
    private(set) var finishCount = 0

    var hasActiveSession: Bool { !typed.isEmpty }

    func handleKey(_ character: Character) -> Suggestion {
        typed.append(character)
        return currentSuggestion()
    }

    func backspace(word: Bool) -> Suggestion {
        if word {
            typed = ""
        } else if !typed.isEmpty {
            typed.removeLast()
        }
        return currentSuggestion()
    }

    func commitCandidate(at index: Int) -> Suggestion { currentSuggestion() }

    func finishSession() {
        typed = ""
        finishCount += 1
    }

    func teardown() {}

    private func currentSuggestion() -> Suggestion {
        guard !typed.isEmpty else { return .empty }
        let text = Self.transliterate(typed)
        return Suggestion(candidates: [text], preEditText: text)
    }

    /// The model transliteration.
    ///
    /// Deliberately not prefix-monotonic: `bang` reshapes `বান` into `বাং` and
    /// `likh` reshapes `লিক` into `লিখ`, so the keyboard has to delete back
    /// to the shared prefix rather than append.
    ///
    /// Digraphs are matched on the latin side with a lookahead rather than by
    /// rewriting the Bengali afterwards: `ং` is a combining mark, so it would
    /// fuse with whatever precedes it into one grapheme cluster and any later
    /// search through the result would miss.
    static func transliterate(_ latin: String) -> String {
        let characters = Array(latin)
        var output = ""
        var index = 0

        while index < characters.count {
            if index + 1 < characters.count,
               let reshaped = digraphs[String(characters[index ... index + 1])] {
                output += reshaped
                index += 2
                continue
            }
            output += glyph(for: characters[index], wordInitial: index == 0)
            index += 1
        }

        return output
    }

    private static let digraphs: [String: String] = [
        "ng": "ং", "kh": "খ"
    ]

    private static func glyph(for character: Character, wordInitial: Bool) -> String {
        if wordInitial, let vowel = independentVowels[character] { return vowel }
        return letters[character] ?? String(character)
    }

    /// A vowel opening a word is written in full rather than as a sign.
    private static let independentVowels: [Character: String] = [
        "a": "আ", "i": "ই", "u": "উ", "e": "এ", "o": "ও"
    ]

    private static let letters: [Character: String] = [
        "a": "\u{09BE}", "i": "\u{09BF}", "u": "\u{09C1}",
        "e": "\u{09C7}", "o": "\u{09CB}",
        "b": "ব", "c": "চ", "d": "দ", "f": "ফ", "g": "গ", "h": "হ",
        "j": "জ", "k": "ক", "l": "ল", "m": "ম", "n": "ন", "p": "প",
        "q": "ক", "r": "র", "s": "স", "t": "ত", "v": "ভ", "w": "ও",
        "x": "ক্স", "y": "য", "z": "য",
        "S": "শ", "N": "ণ", "T": "ট", "D": "ড"
    ]
}

// MARK: - Rig

/// Drives `KeyRouter` the way the keyboard's dispatch loop does: route the
/// action, apply the outcome to the document, then note what the composition
/// now has on screen.
///
/// One `strike` is one finger landing on one key. Because every key emits on
/// touch-down, the order strikes are made in *is* the order the keys were hit,
/// which is what lets these tests talk about rollover at all.
final class TypingRig {

    let session: InputSession
    let router: KeyRouter
    let engine: LekhiEngine
    let document = FakeDocument()

    /// The keyboard's own record of what this word has displayed, kept in step
    /// with the document exactly as `dispatch` keeps it.
    private(set) var history = ComposingHistory()

    init(
        engine: LekhiEngine = FakePhoneticEngine(),
        layout: Layout = .avroPhonetic,
        mode: TypingMode = .phoneticFirst
    ) {
        self.engine = engine
        self.session = InputSession(layout: layout, mode: mode, pinnedKeywords: [])
        self.router = KeyRouter(session: session, engine: engine)
    }

    var text: String { document.text }

    @discardableResult
    func strike(_ action: KeyAction) -> KeyOutcome {
        let outcome = router.route(action)
        document.apply(outcome)
        history.record(session.committedBengali)
        return outcome
    }

    /// Strike every character of `latin` in order, as fast as the machine
    /// will go. A space strikes the spacebar.
    func type(_ latin: String) {
        for character in latin {
            strike(character == " " ? .space : .character(character))
        }
    }

    func backspace(times: Int) {
        for _ in 0..<times {
            strike(.backspace(word: false))
        }
    }
}
