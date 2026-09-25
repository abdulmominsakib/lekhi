//
//  RitiEngine.swift
//  SharedKit
//
//  Safe Swift wrapper around the OpenBangla/riti engine used by Lekhi.
//

import Foundation
import RitiFFI

public final class RitiEngine: LekhiEngine {

    private var context: OpaquePointer?
    private var config: OpaquePointer?

    /// Maps each visible keyboard candidate back to riti's source index.
    private var visibleCandidateIndices: [Int] = []
    private var sourceCandidateCount = 0

    private let mode: TypingMode

    /// Typing shortcuts (qq, TH, hs, consonant+z) are phonetic conventions, so
    /// they only apply to Avro — Probhat is a fixed layout.
    private let appliesShortcuts: Bool

    /// The Latin buffer exactly as the user typed it.
    private var typed = ""

    /// What riti's own buffer currently holds: `typed` with its shortcuts
    /// rewritten into Avro. The two diverge whenever a shortcut is in play
    /// (`caqq` is fed to riti as `ca^`), and a later key can change how an
    /// earlier part rewrites (`allahhs` ends in hasanta, `allahhsa` does not),
    /// so riti is resynchronised on every edit rather than fed one key.
    private var fed = ""

    public init?(layout: Layout, mode: TypingMode) {
        self.mode = mode
        self.appliesShortcuts = layout == .avroPhonetic

        // The engine's data files live in this target's own bundle. Nothing
        // is copied anywhere: see `DataPaths.databaseDirectory()`.
        guard let databaseDir = DataPaths.databaseDirectory()?.path else {
            EngineDiagnostics.record(.missingDataFiles)
            return nil
        }

        guard let userDir = DataPaths.userDirectory()?.path else {
            EngineDiagnostics.record(.noWritableUserDirectory)
            return nil
        }

        guard let handle = Self.makeContext(
            layout: layout,
            databaseDir: databaseDir,
            userDir: userDir,
            phoneticSuggestion: mode != .phoneticOnly
        ) else {
            EngineDiagnostics.record(.contextCreationFailed)
            return nil
        }

        config = handle.config
        context = handle.context
        EngineDiagnostics.record(.ready)
    }

    deinit {
        teardown()
    }

    public var hasActiveSession: Bool {
        guard let context else { return false }
        return riti_context_ongoing_input_session(context)
    }

    public func handleKey(_ character: Character) -> Suggestion {
        guard context != nil,
              let scalar = character.unicodeScalars.first,
              scalar.value < 0x80,
              avro_keycode_for_char(scalar.value) != 0 else {
            return .empty
        }
        typed.append(character)
        return synchronise()
    }

    public func backspace(word: Bool) -> Suggestion {
        guard context != nil, !typed.isEmpty else { return .empty }
        if word {
            typed = ""
        } else {
            typed.removeLast()
        }
        return synchronise()
    }

    /// Bring riti's buffer in line with `typed`, touching as little as
    /// possible: back up to the longest shared prefix, then feed the rest.
    /// Usually that is a single new key.
    private func synchronise() -> Suggestion {
        guard let context else { return .empty }

        // riti ends its session on its own when its buffer empties.
        if !riti_context_ongoing_input_session(context) {
            fed = ""
        }

        let target = rewritten(typed)
        let fedChars = Array(fed)
        let targetChars = Array(target)
        var shared = 0
        while shared < fedChars.count, shared < targetChars.count,
              fedChars[shared] == targetChars[shared] {
            shared += 1
        }

        var last: OpaquePointer?
        defer { if let last { riti_suggestion_free(last) } }

        func replace(with next: OpaquePointer?) {
            if let last { riti_suggestion_free(last) }
            last = next
        }

        for _ in shared..<fedChars.count {
            replace(with: riti_context_backspace_event(context, false))
        }
        fed = String(fedChars[0..<shared])

        for character in targetChars[shared...] {
            guard let scalar = character.unicodeScalars.first else { continue }
            let keycode = avro_keycode_for_char(scalar.value)
            guard keycode != 0 else {
                // Can't happen for the rewrites above, but never leave riti
                // and `fed` disagreeing about what riti holds.
                finishSession()
                return .empty
            }
            replace(with: riti_get_suggestion_for_key(context, keycode, 0, 0))
            fed.append(character)
        }

        // Nothing changed riti's buffer (a rewrite absorbed the edit), so ask
        // for the current suggestion by stepping back and forward one key.
        if last == nil, let final = fed.last, let scalar = final.unicodeScalars.first {
            replace(with: riti_context_backspace_event(context, false))
            replace(with: riti_get_suggestion_for_key(context, avro_keycode_for_char(scalar.value), 0, 0))
        }

        guard let raw = last else {
            clearCandidateState()
            return .empty
        }
        return suggestion(from: raw)
    }

    private func rewritten(_ term: String) -> String {
        guard appliesShortcuts, !term.isEmpty,
              let pointer = avro_apply_shortcuts(term) else {
            return term
        }
        defer { riti_string_free(pointer) }
        return String(cString: pointer)
    }

    public func commitCandidate(at index: Int) -> Suggestion {
        defer { finishSession() }

        guard let context,
              riti_context_ongoing_input_session(context),
              visibleCandidateIndices.indices.contains(index) else {
            return .empty
        }

        let sourceIndex = visibleCandidateIndices[index]
        guard sourceIndex >= 0, sourceIndex < sourceCandidateCount else {
            return .empty
        }

        // riti indexes directly into its last suggestion here. Passing a stale
        // or UI-truncated index would panic across the FFI boundary.
        riti_context_candidate_committed(context, UInt(sourceIndex))
        return .empty
    }

    public func finishSession() {
        if let context, riti_context_ongoing_input_session(context) {
            riti_context_finish_input_session(context)
        }
        typed = ""
        fed = ""
        clearCandidateState()
    }

    public func teardown() {
        finishSession()
        if let context {
            riti_context_free(context)
            self.context = nil
        }
        if let config {
            riti_config_free(config)
            self.config = nil
        }
    }

    // MARK: - Hand-typed hasanta

    /// Ridmik teaches `hs` as the way to join two consonants by hand:
    /// s + hs + b is স্ব. The shortcut layer hands that to riti as Avro's `,,`,
    /// which always carries a zero-width non-joiner and so keeps the letters
    /// apart (স্‌ব). Drop the non-joiner again wherever a consonant follows the
    /// hasanta, and the pair forms its conjunct.
    ///
    /// Left alone when the user typed `,,` themselves — asking for the
    /// non-joiner explicitly is exactly what that spelling is for — and at the
    /// end of a word, where `allahhs` should keep showing আল্লাহ্‌.
    private func joiningHandTypedHasanta(_ text: String) -> String {
        guard appliesShortcuts, typed.contains("hs"), !typed.contains(",,") else { return text }

        let scalars = Array(text.unicodeScalars)
        var output = String.UnicodeScalarView()
        for (index, scalar) in scalars.enumerated() {
            if scalar.value == 0x200C,
               index > 0, scalars[index - 1].value == 0x09CD,
               index + 1 < scalars.count, Self.isBengaliConsonant(scalars[index + 1]) {
                continue
            }
            output.append(scalar)
        }
        return String(output)
    }

    /// What the bar shows for a candidate. riti offers its own buffer back as
    /// the Latin fallback, and that buffer holds the shortcut rewrite — so
    /// typing `shsbamI` offered `s,,bamI`, and tapping it put the internal
    /// spelling in the document. Show what the user typed instead.
    private func displayed(_ candidate: String) -> String {
        if !fed.isEmpty, candidate == fed { return typed }
        return joiningHandTypedHasanta(candidate)
    }

    private static func isBengaliConsonant(_ scalar: Unicode.Scalar) -> Bool {
        switch scalar.value {
        case 0x0995...0x09B9, 0x09CE, 0x09DC...0x09DF: return true
        default: return false
        }
    }

    // MARK: - Suggestion extraction

    private func suggestion(from raw: OpaquePointer) -> Suggestion {
        if riti_suggestion_is_empty(raw) {
            clearCandidateState()
            return .empty
        }

        // Suggestion::Single is a distinct Rust enum variant. Calling list-only
        // accessors such as get_length on it panics, so this branch comes first.
        if riti_suggestion_is_lonely(raw) {
            clearCandidateState()
            guard let pointer = riti_suggestion_get_lonely_suggestion(raw) else {
                return .empty
            }
            defer { riti_string_free(pointer) }
            let text = joiningHandTypedHasanta(String(cString: pointer))
            return Suggestion(
                candidates: text.isEmpty ? [] : [text],
                preEditText: text,
                defaultIndex: 0,
                isLonely: true
            )
        }

        let count = Int(riti_suggestion_get_length(raw))
        guard count > 0 else {
            clearCandidateState()
            return .empty
        }

        var allCandidates: [String] = []
        allCandidates.reserveCapacity(count)
        for index in 0..<count {
            guard let pointer = riti_suggestion_get_suggestion(raw, UInt(index)) else {
                clearCandidateState()
                return .empty
            }
            allCandidates.append(String(cString: pointer))
            riti_string_free(pointer)
        }

        guard !allCandidates.isEmpty else {
            clearCandidateState()
            return .empty
        }

        sourceCandidateCount = allCandidates.count
        let sourceDefaultIndex = defaultIndex(in: raw, candidates: allCandidates)
        visibleCandidateIndices = visibleIndices(
            candidateCount: allCandidates.count,
            requiredIndex: sourceDefaultIndex
        )

        // Joining a hand-typed hasanta can turn the literal reading into the
        // same word the dictionary already offers (স্‌বামী becomes স্বামী), so
        // keep the first of any pair that now reads the same — along with the
        // riti index it maps to, which `commitCandidate` relies on.
        var seen = Set<String>()
        var keptIndices: [Int] = []
        for sourceIndex in visibleCandidateIndices {
            let text = displayed(allCandidates[sourceIndex])
            if seen.insert(text).inserted {
                keptIndices.append(sourceIndex)
            } else if sourceIndex == sourceDefaultIndex,
                      let twin = keptIndices.firstIndex(where: { displayed(allCandidates[$0]) == text }) {
                // The default must stay visible; let it stand in for its twin.
                keptIndices[twin] = sourceIndex
            }
        }
        visibleCandidateIndices = keptIndices

        let visibleCandidates = visibleCandidateIndices.map { displayed(allCandidates[$0]) }
        let visibleDefaultIndex = visibleCandidateIndices.firstIndex(of: sourceDefaultIndex) ?? 0
        let preEdit = joiningHandTypedHasanta(preEditText(
            from: raw,
            sourceIndex: sourceDefaultIndex,
            fallback: allCandidates[sourceDefaultIndex]
        ))

        return Suggestion(
            candidates: visibleCandidates,
            preEditText: preEdit,
            defaultIndex: visibleDefaultIndex,
            isLonely: false
        )
    }

    /// Which candidate the keyboard writes into the document while composing.
    ///
    /// riti sorts its list as autocorrect -> emoji -> dictionary -> literal
    /// phonetic -> typed English, and its own default is the remembered pick
    /// or index 0. A desktop IME only commits that on space; Lekhi writes the
    /// selection into the document on every keystroke, so taking index 0
    /// typed an emoji mid-word whenever the Latin buffer spelled an emoji name
    /// (`on` -> 🔛, `one` -> 1️⃣). Continuing the word then replaced that emoji
    /// and, because of how the host deletes emoji, ate the text before it.
    ///
    /// - An emoji is never the default. It stays one tap away in the bar.
    /// - `.phoneticFirst` defaults to the literal transliteration, as the mode
    ///   promises, unless the user previously picked something for this word.
    /// - `.smart` keeps riti's ranking, minus the emoji.
    private func defaultIndex(in raw: OpaquePointer, candidates: [String]) -> Int {
        // riti reports 0 both for "nothing remembered" and for a remembered
        // pick that happens to rank first, so only a non-zero index is
        // evidence of an earlier choice.
        let remembered = Int(riti_suggestion_previously_selected_index(raw))
        let rememberedPick = candidates.indices.contains(remembered)
            && !Self.isEmoji(candidates[remembered])
            ? remembered : nil

        let firstNonEmoji = candidates.firstIndex { !Self.isEmoji($0) } ?? 0

        switch mode {
        case .phoneticFirst:
            if let rememberedPick, rememberedPick > 0 {
                return rememberedPick
            }
            if let literal = literalReading(of: raw),
               let index = candidates.firstIndex(of: literal) {
                return index
            }
            return firstNonEmoji
        case .smart, .phoneticOnly:
            return rememberedPick ?? firstNonEmoji
        }
    }

    /// The plain transliteration of riti's current buffer, rebuilt with the
    /// same parser riti uses (`avro_phonetic_literal`). Only valid for a full
    /// suggestion list — riti panics if asked for auxiliary text otherwise.
    private func literalReading(of raw: OpaquePointer) -> String? {
        guard let buffer = riti_suggestion_get_auxiliary_text(raw) else { return nil }
        defer { riti_string_free(buffer) }
        guard let literal = avro_phonetic_literal(buffer) else { return nil }
        defer { riti_string_free(literal) }
        return String(cString: literal)
    }

    /// Whether a candidate is an emoji rather than text.
    static func isEmoji(_ candidate: String) -> Bool {
        candidate.unicodeScalars.contains { scalar in
            scalar.properties.isEmojiPresentation
                || scalar.value == 0xFE0F   // variation selector: emoji style
                || scalar.value == 0x20E3   // combining enclosing keycap
        }
    }

    /// Up to three candidates for the bar, default first.
    ///
    /// The literal reading usually ranks below riti's first few entries, so
    /// it used to be squeezed into the last slot behind an emoji. Leading with
    /// the candidate that is actually in the document matches the design's
    /// bar, which puts the typed reading in the first cell.
    private func visibleIndices(candidateCount: Int, requiredIndex: Int) -> [Int] {
        var indices = [requiredIndex]
        for index in 0..<candidateCount where index != requiredIndex {
            guard indices.count < Suggestion.maxBarCount else { break }
            indices.append(index)
        }
        return indices
    }

    private func preEditText(
        from raw: OpaquePointer,
        sourceIndex: Int,
        fallback: String
    ) -> String {
        guard sourceIndex >= 0,
              sourceIndex < sourceCandidateCount,
              let pointer = riti_suggestion_get_pre_edit_text(raw, UInt(sourceIndex)) else {
            return fallback
        }
        defer { riti_string_free(pointer) }
        return String(cString: pointer)
    }

    private func clearCandidateState() {
        visibleCandidateIndices = []
        sourceCandidateCount = 0
    }

    // MARK: - Context construction

    private struct EngineHandle {
        let config: OpaquePointer
        let context: OpaquePointer
    }

    private static func makeContext(
        layout: Layout,
        databaseDir: String,
        userDir: String,
        phoneticSuggestion: Bool
    ) -> EngineHandle? {
        guard let config = riti_config_new() else { return nil }

        let layoutPath: String = {
            if layout == .probhat {
                return DataPaths.url(for: "probhat.json")?.path
                    ?? ((databaseDir as NSString).appendingPathComponent("probhat.json"))
            }
            return layout.ritiLayoutName
        }()

        guard riti_config_set_layout_file(config, layoutPath) else {
            riti_config_free(config)
            return nil
        }

        guard riti_config_set_database_dir(config, databaseDir),
              riti_config_set_user_dir(config, userDir) else {
            riti_config_free(config)
            return nil
        }

        riti_config_set_phonetic_suggestion(config, phoneticSuggestion)
        riti_config_set_suggestion_include_english(config, true)

        guard let context = riti_context_new_with_config(config) else {
            riti_config_free(config)
            return nil
        }

        return EngineHandle(config: config, context: context)
    }
}
