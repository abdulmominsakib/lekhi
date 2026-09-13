//
//  TypingMode.swift
//  SharedKit
//
//  The three typing behaviours supported by Lekho, matching the
//  macOS upstream's TypingMode enum.
//

import Foundation

public enum TypingMode: String, CaseIterable, Identifiable, Sendable {
    /// Dictionary, autocorrect, and emoji suggestions; the engine's
    /// top-ranked candidate is selected/committed by default.
    case smart

    /// The full suggestion list is shown, but the literal phonetic
    /// transliteration is selected/committed by default unless the
    /// user has a remembered selection. This is the recommended
    /// default — predictable output, dictionary on tap.
    case phoneticFirst

    /// A single phonetic transliteration committed inline — no
    /// candidate popup, no autocorrect, no emoji.
    case phoneticOnly

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .smart:         return "Smart"
        case .phoneticFirst: return "Phonetic First"
        case .phoneticOnly:  return "Phonetic Only"
        }
    }

    public var subtitle: String {
        switch self {
        case .smart:
            return "Dictionary wins. Top suggestion is committed automatically."
        case .phoneticFirst:
            return "Phonetic output by default; tap a suggestion to use a dictionary word."
        case .phoneticOnly:
            return "Pure phonetic typing. No suggestions, no autocorrect."
        }
    }

    /// Whether this mode shows the candidate suggestion bar.
    public var showsSuggestionBar: Bool {
        self != .phoneticOnly
    }
}

// MARK: - Persistence

public enum TypingModeStore {
    private static let key = "LekhiTypingMode"
    private static let legacyKey = "LekhiPhoneticOnlyMode"

    public static func current() -> TypingMode {
        let d = AppGroup.defaults
        if let raw = d.string(forKey: key),
           let mode = TypingMode(rawValue: raw) {
            return mode
        }
        // Legacy migration: phonetic-only users keep their setting.
        if d.bool(forKey: legacyKey) { return .phoneticOnly }
        return .phoneticFirst
    }

    public static func set(_ mode: TypingMode) {
        AppGroup.defaults.set(mode.rawValue, forKey: key)
        postSettingsChanged()
    }
}

public enum LayoutStore {
    private static let key = "LekhiLayout"
    private static let enabledKey = "LekhiEnabledLayouts"

    /// The active layout. Always one of `enabled()`: if the stored choice has
    /// since been turned off, the first layout still on takes its place.
    public static func current() -> Layout {
        let raw = AppGroup.defaults.string(forKey: key) ?? Layout.avroPhonetic.rawValue
        let stored = Layout(rawValue: raw) ?? .avroPhonetic
        let enabled = enabled()
        return enabled.contains(stored) ? stored : enabled[0]
    }

    public static func set(_ layout: Layout) {
        AppGroup.defaults.set(layout.rawValue, forKey: key)
        postSettingsChanged()
    }

    /// Layouts the user keeps in the spacebar switcher, in switcher order.
    /// Never empty — all three are on until the user turns one off.
    public static func enabled() -> [Layout] {
        guard let raw = AppGroup.defaults.stringArray(forKey: enabledKey) else {
            return Layout.allCases
        }
        let list = Layout.allCases.filter { raw.contains($0.rawValue) }
        return list.isEmpty ? Layout.allCases : list
    }

    /// Turn a layout on or off. The last remaining layout can't be turned off.
    /// Turning off the active layout moves the keyboard to the next one on.
    public static func setEnabled(_ layout: Layout, _ isOn: Bool) {
        let previous = enabled()
        var list = previous
        if isOn {
            guard !list.contains(layout) else { return }
            list.append(layout)
        } else {
            guard list.count > 1, list.contains(layout) else { return }
            list.removeAll { $0 == layout }
        }
        let ordered = Layout.allCases.filter { list.contains($0) }
        AppGroup.defaults.set(ordered.map(\.rawValue), forKey: enabledKey)

        let raw = AppGroup.defaults.string(forKey: key) ?? Layout.avroPhonetic.rawValue
        let active = Layout(rawValue: raw) ?? .avroPhonetic
        if !ordered.contains(active) {
            AppGroup.defaults.set(neighbour(of: active, forward: true, in: previous, within: ordered).rawValue,
                                  forKey: key)
        }
        postSettingsChanged()
    }

    /// The layout a spacebar swipe moves to, skipping layouts that are off.
    /// Returns `layout` itself when it is the only one on.
    public static func neighbour(of layout: Layout, forward: Bool) -> Layout {
        let list = enabled()
        return neighbour(of: layout, forward: forward, in: Layout.allCases, within: list)
    }

    private static func neighbour(
        of layout: Layout,
        forward: Bool,
        in order: [Layout],
        within allowed: [Layout]
    ) -> Layout {
        guard let start = order.firstIndex(of: layout), !allowed.isEmpty else {
            return allowed.first ?? layout
        }
        let count = order.count
        for step in 1...count {
            let index = (start + (forward ? step : -step) % count + count) % count
            if allowed.contains(order[index]) {
                return order[index]
            }
        }
        return layout
    }
}
