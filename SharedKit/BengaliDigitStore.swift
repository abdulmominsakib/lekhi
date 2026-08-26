//
//  BengaliDigitStore.swift
//  SharedKit
//
//  Shared store for toggling Bengali digits vs English digits.
//

import Foundation

public enum BengaliDigitStore {
    private static let key = "LekhiBengaliDigitsEnabled"

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
