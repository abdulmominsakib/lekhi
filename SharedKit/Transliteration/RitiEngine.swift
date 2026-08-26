//
//  RitiEngine.swift
//  SharedKit
//
//  Swift wrapper around the `avrobangla_engine` Rust static library
//  (OpenBangla's `riti` transliteration engine). Mirrors the
//  lifecycle used by the macOS Lekho InputController.
//

import Foundation
import RitiFFI

/// Riti-backed transliteration engine.
///
/// Behaviour by mode:
/// * `.smart`         — single context with `phoneticSuggestion = true`.
/// * `.phoneticFirst` — primary context plus a phonetic-only shadow
///                       context whose lonely output is used to pick
///                       the default candidate.
/// * `.phoneticOnly`  — single context with `phoneticSuggestion = false`;
///                       results are committed inline as soon as they
///                       arrive.
public final class RitiEngine: LekhiEngine {

    // MARK: - Stored state

    private var primaryCtx: OpaquePointer?
    private var primaryCfg: OpaquePointer?
    private var shadowCtx: OpaquePointer?
    private var shadowCfg: OpaquePointer?
    private var currentPhonetic: String?

    private let layout: Layout
    private let mode: TypingMode

    // MARK: - Init / teardown

    public init?(layout: Layout, mode: TypingMode) {
        self.layout = layout
        self.mode = mode

        // Copy the data files into the App Group on first launch.
        try? DataPaths.ensureDataFilesCopied()

        let databaseDir: String = {
            if let dir = DataPaths.sharedDataDir?.path, FileManager.default.fileExists(atPath: dir) {
                return dir
            }
            if let bundleResource = Bundle.main.resourcePath {
                return bundleResource
            }
            return NSTemporaryDirectory()
        }()

        let userDir: String = {
            if let userPath = AppGroup.containerURL?.appendingPathComponent("RitiUser").path {
                return userPath
            }
            return NSTemporaryDirectory() + "/RitiUser"
        }()

        // Make sure the user directory exists; riti writes its
        // remembered-selection cache there.
        try? FileManager.default.createDirectory(
            atPath: userDir,
            withIntermediateDirectories: true
        )

        guard
            let primary = Self.makeContext(
                layout: layout,
                databaseDir: databaseDir,
                userDir: userDir,
                phoneticSuggestion: mode != .phoneticOnly
            )
        else {
            return nil
        }
        self.primaryCfg = primary.config
        self.primaryCtx = primary.context

        // Phonetic-first runs a second context to get the literal
        // phonetic output for default-selection logic.
        if mode == .phoneticFirst,
           let shadow = Self.makeContext(
                layout: layout,
                databaseDir: databaseDir,
                userDir: userDir,
                phoneticSuggestion: false
           )
        {
            self.shadowCfg = shadow.config
            self.shadowCtx = shadow.context
        }
    }

    deinit { teardown() }

    public func teardown() {
        if let ctx = primaryCtx   { riti_context_free(ctx);  primaryCtx = nil }
        if let cfg = primaryCfg   { riti_config_free(cfg);   primaryCfg = nil }
        if let ctx = shadowCtx    { riti_context_free(ctx);  shadowCtx = nil }
        if let cfg = shadowCfg    { riti_config_free(cfg);   shadowCfg = nil }
    }

    // MARK: - LekhiEngine

    public var hasActiveSession: Bool {
        guard let ctx = primaryCtx else { return false }
        return riti_context_ongoing_input_session(ctx)
    }

    public func handleKey(_ character: Character) -> Suggestion {
        guard let ctx = primaryCtx else { return .empty }

        // Map the Swift Character to the riti virtual keycode.
        guard
            let scalar = character.unicodeScalars.first,
            scalar.value < 0x80
        else {
            return .empty
        }

        let keycode = avro_keycode_for_char(scalar.value)
        guard keycode != 0 else { return .empty }

        let selection = UInt8(0)
        guard let raw = riti_get_suggestion_for_key(ctx, keycode, 0, selection) else {
            return .empty
        }
        defer { riti_suggestion_free(raw) }

        if let shadow = shadowCtx,
           let shadowRaw = riti_get_suggestion_for_key(shadow, keycode, 0, 0) {
            currentPhonetic = extractLonely(shadowRaw)
            riti_suggestion_free(shadowRaw)
        }

        return assemble(raw: raw, fallback: nil)
    }

    public func backspace(word: Bool) -> Suggestion {
        guard let ctx = primaryCtx else { return .empty }
        guard let raw = riti_context_backspace_event(ctx, word) else {
            return .empty
        }
        defer { riti_suggestion_free(raw) }

        if let shadow = shadowCtx,
           let shadowRaw = riti_context_backspace_event(shadow, word) {
            currentPhonetic = extractLonely(shadowRaw)
            riti_suggestion_free(shadowRaw)
        }

        return assemble(raw: raw, fallback: nil)
    }

    public func commitCandidate(at index: Int) -> Suggestion {
        guard let ctx = primaryCtx else { return .empty }
        if riti_context_ongoing_input_session(ctx) {
            riti_context_candidate_committed(ctx, UInt(index))
        }
        finishSession()
        return .empty
    }

    public func finishSession() {
        if let ctx = primaryCtx, riti_context_ongoing_input_session(ctx) {
            riti_context_finish_input_session(ctx)
        }
        if let shadow = shadowCtx, riti_context_ongoing_input_session(shadow) {
            riti_context_finish_input_session(shadow)
        }
        currentPhonetic = nil
    }

    // MARK: - Suggestion assembly

    private func extractLonely(_ raw: OpaquePointer) -> String? {
        guard !riti_suggestion_is_empty(raw),
              riti_suggestion_is_lonely(raw),
              let ptr = riti_suggestion_get_lonely_suggestion(raw) else {
            return nil
        }
        defer { riti_string_free(ptr) }
        return String(cString: ptr)
    }

    private func assemble(
        raw: OpaquePointer,
        fallback: Suggestion?
    ) -> Suggestion {
        let isLonely = riti_suggestion_is_lonely(raw)

        // Lonely / single suggestion is the phonetic inline commit.
        if isLonely {
            if let lonely = riti_suggestion_get_lonely_suggestion(raw) {
                defer { riti_string_free(lonely) }
                let text = String(cString: lonely)
                return Suggestion(
                    candidates: text.isEmpty ? [] : [text],
                    preEditText: text,
                    defaultIndex: 0,
                    isLonely: true
                )
            }
            return Suggestion(
                candidates: [],
                preEditText: "",
                defaultIndex: 0,
                isLonely: true
            )
        }

        let count = Int(riti_suggestion_get_length(raw))
        var candidates: [String] = []
        candidates.reserveCapacity(count)
        for i in 0..<count {
            if let c = riti_suggestion_get_suggestion(raw, UInt(i)) {
                defer { riti_string_free(c) }
                candidates.append(String(cString: c))
            }
        }

        let defaultIdx = defaultIndexIn(raw: raw, candidates: candidates)

        let preEdit: String = {
            if !candidates.isEmpty {
                let safeIdx = UInt(min(defaultIdx, candidates.count - 1))
                if let p = riti_suggestion_get_pre_edit_text(raw, safeIdx) {
                    defer { riti_string_free(p) }
                    return String(cString: p)
                }
                if candidates.indices.contains(defaultIdx) {
                    return candidates[defaultIdx]
                }
                return candidates.first ?? ""
            }
            if let p = riti_suggestion_get_pre_edit_text(raw, 0) {
                defer { riti_string_free(p) }
                return String(cString: p)
            }
            return ""
        }()

        return Suggestion(
            candidates: candidates,
            preEditText: preEdit,
            defaultIndex: defaultIdx,
            isLonely: false
        )
    }

    /// Determine which candidate should be highlighted by default.
    /// In `.phoneticFirst` we look up the shadow context's lonely
    /// output in the candidate list and prefer that index. In other
    /// modes we fall back to the index that riti remembers from
    /// previous selections, defaulting to 0.
    private func defaultIndexIn(
        raw: OpaquePointer,
        candidates: [String]
    ) -> Int {
        if mode == .phoneticFirst, let phonetic = currentPhonetic {
            if let idx = candidates.firstIndex(of: phonetic) {
                return idx
            }
        }

        let remembered = Int(riti_suggestion_previously_selected_index(raw))
        if remembered >= 0 && remembered < candidates.count {
            return remembered
        }
        return 0
    }

    // MARK: - Config helpers

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
        guard let cfg = riti_config_new() else { return nil }

        guard riti_config_set_layout_file(cfg, layout.ritiLayoutName) else {
            riti_config_free(cfg)
            return nil
        }

        // riti expects the database directory to contain the
        // dictionary / autocorrect / suffix files.
        riti_config_set_database_dir(cfg, databaseDir)
        riti_config_set_user_dir(cfg, userDir)
        riti_config_set_phonetic_suggestion(cfg, phoneticSuggestion)
        riti_config_set_suggestion_include_english(cfg, true)

        guard let ctx = riti_context_new_with_config(cfg) else {
            riti_config_free(cfg)
            return nil
        }

        return EngineHandle(config: cfg, context: ctx)
    }
}
