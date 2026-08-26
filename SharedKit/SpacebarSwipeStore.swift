//
//  SpacebarSwipeStore.swift
//  SharedKit
//
//  Shared store for toggling spacebar swipe language switching.
//

import Foundation

public enum SpacebarSwipeStore {
    private static let key = "LekhiSpacebarSwipeEnabled"

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
