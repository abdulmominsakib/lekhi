//
//  CharacterPreviewStore.swift
//  SharedKit
//
//  Shared store for toggling Apple-style keypress popups / character previews.
//

import Foundation

public enum CharacterPreviewStore {
    private static let key = "LekhiCharacterPreviewEnabled"

    public static func current() -> Bool {
        let d = AppGroup.defaults
        if d.object(forKey: key) != nil {
            return d.bool(forKey: key)
        }
        return true // Default: Enabled (matching iOS native keyboard behavior)
    }

    public static func set(_ enabled: Bool) {
        AppGroup.defaults.set(enabled, forKey: key)
        postSettingsChanged()
    }
}

/// Whether the small Bangla hint glyphs are drawn in the corner of each
/// keycap. The reference design has bare caps; the hints are a Lekhi
/// feature, so they stay on by default and can be switched off for the
/// design's clean look.
public enum KeyHintStore {
    private static let key = "LekhiKeyHintsEnabled"

    public static func current() -> Bool {
        let d = AppGroup.defaults
        if d.object(forKey: key) != nil {
            return d.bool(forKey: key)
        }
        return true
    }

    public static func set(_ enabled: Bool) {
        AppGroup.defaults.set(enabled, forKey: key)
        postSettingsChanged()
    }
}
