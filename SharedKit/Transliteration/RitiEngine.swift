//
//  RitiEngine.swift
//  SharedKit
//
//  Safe, dual-context Swift wrapper around the OpenBangla/riti engine used
//  by Lekho. Runs a shadow phonetic context in lockstep when in phonetic-first
//  mode so the literal transliteration is accurately matched without corrupting
//  dictionary candidate ranking.
//

import Foundation
import RitiFFI

public final class RitiEngine: LekhiEngine {

    private var context: OpaquePointer?
    private var config: OpaquePointer?

    /// Shadow context running phonetic-only, used in `.phoneticFirst` to obtain the
    /// raw transliteration of the current buffer so it can be default-selected in
    /// the main suggestion list (mirroring Lekho). Nil in other modes.
    private var phoneticContext: OpaquePointer?
    private var phoneticConfig: OpaquePointer?

    /// Raw phonetic transliteration of the current buffer (from `phoneticContext`).
    private var currentPhonetic: String?

    /// Maps each visible keyboard candidate back to riti's source index.
    private var visibleCandidateIndices: [Int] = []
    private var sourceCandidateCount = 0

    private let mode: TypingMode

    public init?(layout: Layout, mode: TypingMode) {
        self.mode = mode

        // The extension can read its bundled resources directly. Copying them
        // into the App Group is best-effort and must never block initialization.
        try? DataPaths.ensureDataFilesCopied()

        let databaseDir: String = {
            if let shared = DataPaths.sharedDataDir?.path,
               FileManager.default.fileExists(atPath: shared) {
                return shared
            }
            return Bundle.main.resourcePath ?? NSTemporaryDirectory()
        }()

        let userDir: String = {
            if let shared = AppGroup.containerURL?.appendingPathComponent("RitiUser").path {
                return shared
            }
            return NSTemporaryDirectory() + "/LekhiRitiUser"
        }()

        try? FileManager.default.createDirectory(
            atPath: userDir,
            withIntermediateDirectories: true
        )

        guard let handle = Self.makeContext(
            layout: layout,
            databaseDir: databaseDir,
            userDir: userDir,
            phoneticSuggestion: mode != .phoneticOnly
        ) else {
            return nil
        }

        config = handle.config
        context = handle.context

        if mode == .phoneticFirst {
            if let shadowHandle = Self.makeContext(
                layout: layout,
                databaseDir: databaseDir,
                userDir: userDir,
                phoneticSuggestion: false
            ) {
                phoneticConfig = shadowHandle.config
                phoneticContext = shadowHandle.context
            }
        }
    }

    deinit {
        teardown()
    }

    public var hasActiveSession: Bool {
        guard let context else { return false }
        return riti_context_ongoing_input_session(context)
    }

    public func handleKey(_ character: Character) -> Suggestion {
        guard let context,
              let scalar = character.unicodeScalars.first,
              scalar.value < 0x80 else {
            return .empty
        }

        let keycode = avro_keycode_for_char(scalar.value)
        guard keycode != 0,
              let raw = riti_get_suggestion_for_key(context, keycode, 0, 0) else {
            return .empty
        }
        defer { riti_suggestion_free(raw) }

        feedPhoneticShadow(keycode: keycode)

        return suggestion(from: raw)
    }

    public func backspace(word: Bool) -> Suggestion {
        guard let context,
              let raw = riti_context_backspace_event(context, word) else {
            return .empty
        }
        defer { riti_suggestion_free(raw) }

        backspacePhoneticShadow(word: word)

        return suggestion(from: raw)
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
        finishPhoneticShadow()
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
        if let phoneticContext {
            riti_context_free(phoneticContext)
            self.phoneticContext = nil
        }
        if let phoneticConfig {
            riti_config_free(phoneticConfig)
            self.phoneticConfig = nil
        }
    }

    // MARK: - Phonetic shadow context (.phoneticFirst)

    private func feedPhoneticShadow(keycode: UInt16) {
        guard let phoneticContext else { return }
        let raw = riti_get_suggestion_for_key(phoneticContext, keycode, 0, 0)
        currentPhonetic = lonelyText(of: raw)
        if let raw { riti_suggestion_free(raw) }
    }

    private func backspacePhoneticShadow(word: Bool) {
        guard let phoneticContext else { return }
        let raw = riti_context_backspace_event(phoneticContext, word)
        currentPhonetic = lonelyText(of: raw)
        if let raw { riti_suggestion_free(raw) }
    }

    private func finishPhoneticShadow() {
        if let phoneticContext, riti_context_ongoing_input_session(phoneticContext) {
            riti_context_finish_input_session(phoneticContext)
        }
        currentPhonetic = nil
    }

    private func lonelyText(of raw: OpaquePointer?) -> String? {
        guard let raw,
              !riti_suggestion_is_empty(raw),
              riti_suggestion_is_lonely(raw),
              let pointer = riti_suggestion_get_lonely_suggestion(raw) else {
            return nil
        }
        defer { riti_string_free(pointer) }
        return String(cString: pointer)
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
            let text = String(cString: pointer)
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

        let visibleCandidates = visibleCandidateIndices.map { allCandidates[$0] }
        let visibleDefaultIndex = visibleCandidateIndices.firstIndex(of: sourceDefaultIndex) ?? 0
        let preEdit = preEditText(
            from: raw,
            sourceIndex: sourceDefaultIndex,
            fallback: allCandidates[sourceDefaultIndex]
        )

        return Suggestion(
            candidates: visibleCandidates,
            preEditText: preEdit,
            defaultIndex: visibleDefaultIndex,
            isLonely: false
        )
    }

    private func defaultIndex(in raw: OpaquePointer, candidates: [String]) -> Int {
        let remembered = Int(riti_suggestion_previously_selected_index(raw))
        if candidates.indices.contains(remembered) {
            return remembered
        }

        if mode == .phoneticFirst, let phonetic = currentPhonetic {
            if let index = candidates.firstIndex(of: phonetic) {
                return index
            }
        }

        return 0
    }

    private func visibleIndices(candidateCount: Int, requiredIndex: Int) -> [Int] {
        var indices = Array(0..<min(3, candidateCount))
        if !indices.contains(requiredIndex) {
            if indices.count == 3 {
                indices[2] = requiredIndex
            } else {
                indices.append(requiredIndex)
            }
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

        guard riti_config_set_layout_file(config, layout.ritiLayoutName) else {
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

