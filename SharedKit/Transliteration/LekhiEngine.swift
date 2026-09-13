//
//  LekhiEngine.swift
//  SharedKit
//
//  Abstraction over the transliteration engine. The keyboard
//  extension depends only on this protocol; the FFI-backed
//  implementation lives in `RitiEngine.swift`.
//

import Foundation

public protocol LekhiEngine: AnyObject {
    /// Process a single character key press and return the new
    /// candidate list / pre-edit text.
    func handleKey(_ character: Character) -> Suggestion

    /// Backspace event. If `ctrl` is true the whole word is
    /// removed and the input session ends.
    func backspace(word: Bool) -> Suggestion

    /// The user tapped the candidate at `index` in the suggestion
    /// bar. Subsequent key events will continue from the committed
    /// candidate.
    func commitCandidate(at index: Int) -> Suggestion

    /// Finish the current input session without committing. Called
    /// when the user moves the cursor away or deletes everything.
    func finishSession()

    /// Whether there is an active transliteration session.
    var hasActiveSession: Bool { get }

    /// Clean up engine resources.
    func teardown()
}

public extension LekhiEngine {

    func backspace() -> Suggestion { backspace(word: false) }
}

/// Factory for the default engine implementation.
public enum LekhiEngineFactory {

    /// Create the OpenBangla/riti engine used by Lekhi.
    public static func make(layout: Layout, mode: TypingMode) -> LekhiEngine? {
        guard layout != .english else { return nil }
        return RitiEngine(layout: layout, mode: mode)
    }
}

// MARK: - Diagnostics

/// Why the transliteration engine is (or isn't) running.
///
/// When engine construction fails the keyboard stays usable but inserts
/// plain Latin letters, which looks exactly like "phonetic stopped
/// working". Recording the reason in the shared suite lets the host app's
/// Engine Specifications screen say what actually went wrong instead of
/// leaving the user to guess.
public enum EngineState: String, Sendable {
    case unknown
    case ready
    case missingDataFiles
    case noWritableUserDirectory
    case contextCreationFailed

    public var displayName: String {
        switch self {
        case .unknown:                  return "Not started yet"
        case .ready:                    return "Loaded"
        case .missingDataFiles:         return "Failed — dictionary data missing"
        case .noWritableUserDirectory:  return "Failed — no writable storage"
        case .contextCreationFailed:    return "Failed — engine could not start"
        }
    }

    public var isHealthy: Bool { self == .ready }

    public var recoveryHint: String? {
        switch self {
        case .unknown:
            return "Open the keyboard once from any text field to start the engine."
        case .ready:
            return nil
        case .missingDataFiles, .contextCreationFailed:
            return "Reinstall Lekhi to restore the transliteration data files."
        case .noWritableUserDirectory:
            return "Free up some storage on your device, then try again."
        }
    }
}

public enum EngineDiagnostics {
    private static let stateKey = "LekhiEngineState"
    private static let timestampKey = "LekhiEngineStateTimestamp"

    public static func record(_ state: EngineState) {
        let defaults = AppGroup.defaults
        defaults.set(state.rawValue, forKey: stateKey)
        defaults.set(Date().timeIntervalSince1970, forKey: timestampKey)
    }

    public static func current() -> EngineState {
        guard let raw = AppGroup.defaults.string(forKey: stateKey),
              let state = EngineState(rawValue: raw) else {
            return .unknown
        }
        return state
    }

    public static func lastUpdated() -> Date? {
        let stamp = AppGroup.defaults.double(forKey: timestampKey)
        guard stamp > 0 else { return nil }
        return Date(timeIntervalSince1970: stamp)
    }
}
