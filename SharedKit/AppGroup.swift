//
//  AppGroup.swift
//  SharedKit
//
//  Shared constants for the host app and keyboard extension.
//

import Foundation

public enum AppGroup {
    /// Identifier shared between the host app and the keyboard extension.
    /// Must match the value configured in both `.entitlements` files.
    public static let identifier = "group.com.lekhi.ios"

    /// Shared `UserDefaults` suite. Falls back to `.standard` if the
    /// app group is not available (e.g. during early development
    /// before entitlements are wired up).
    public static var defaults: UserDefaults {
        UserDefaults(suiteName: identifier) ?? .standard
    }

    /// Root of the App Group container on disk, where bundled data
    /// files are copied once on first launch.
    public static var containerURL: URL? {
        if let url = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: identifier
        ) {
            return url
        }
        // Fallback for simulator / local development
        if let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            let fallbackDir = appSupport.appendingPathComponent("LekhiGroup", isDirectory: true)
            try? FileManager.default.createDirectory(at: fallbackDir, withIntermediateDirectories: true)
            return fallbackDir
        }
        return nil
    }
}

public enum DarwinNotification {
    public static let settingsChanged =
        "com.lekhi.ios.settingsChanged" as CFString
}

/// Posted via the Darwin notify center whenever the user changes
/// settings in the host app. The extension listens for this and
/// rebuilds its engine.
public func postSettingsChanged() {
    CFNotificationCenterPostNotification(
        CFNotificationCenterGetDarwinNotifyCenter(),
        CFNotificationName(DarwinNotification.settingsChanged),
        nil, nil, true
    )
}
