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

// MARK: - Full Access

/// Whether the keyboard extension has been granted "Allow Full Access".
///
/// Lekhi asks for it for one reason: iOS does not let a custom keyboard drive
/// the Taptic Engine without it, so `UIFeedbackGenerator` silently does
/// nothing. Only the extension can answer the question, so it records the
/// answer here for the host app's settings screen to read.
public enum FullAccessStatus: String, Sendable {
    /// The keyboard has not run since install, so it has not reported yet.
    case unknown
    case granted
    case denied

    public var displayName: String {
        switch self {
        case .unknown: return "Not reported yet"
        case .granted: return "Enabled"
        case .denied:  return "Not enabled"
        }
    }

    public var isGranted: Bool { self == .granted }
}

public enum FullAccessReporter {
    private static let key = "LekhiKeyboardFullAccess"

    /// Called by the keyboard extension each time it appears.
    public static func record(_ granted: Bool) {
        AppGroup.defaults.set(granted ? FullAccessStatus.granted.rawValue
                                      : FullAccessStatus.denied.rawValue,
                              forKey: key)
    }

    /// Read by the host app. `.unknown` until the keyboard has been opened
    /// once; the host treats it like `.denied` and offers the same advice.
    public static func current() -> FullAccessStatus {
        guard let raw = AppGroup.defaults.string(forKey: key),
              let status = FullAccessStatus(rawValue: raw) else {
            return .unknown
        }
        return status
    }
}
