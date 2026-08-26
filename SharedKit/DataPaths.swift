//
//  DataPaths.swift
//  SharedKit
//
//  Resolves the on-disk locations of the dictionary / autocorrect /
//  suffix / layout JSON files consumed by the transliteration engine.
//

import Foundation

public enum DataPaths {

    /// Filenames we ship inside the app bundle, in target order.
    public static let shippedResources: [String] = [
        "dictionary.json",
        "autocorrect.json",
        "suffix.json",
        "probhat.json"
    ]

    /// Directory inside the App Group container where the bundled
    /// JSON files are copied on first launch so both targets can
    /// read them from a single location.
    public static var sharedDataDir: URL? {
        AppGroup.containerURL?.appendingPathComponent(
            "LekhiData", isDirectory: true
        )
    }

    /// Copy the bundled JSON files into the App Group container.
    /// Safe to call repeatedly: existing files are left untouched.
    public static func ensureDataFilesCopied() throws {
        guard let dataDir = sharedDataDir else {
            throw DataPathsError.appGroupUnavailable
        }
        let fm = FileManager.default
        try fm.createDirectory(
            at: dataDir,
            withIntermediateDirectories: true
        )

        for name in shippedResources {
            let destination = dataDir.appendingPathComponent(name)
            if fm.fileExists(atPath: destination.path) { continue }
            guard let source = findBundledResource(name) else {
                throw DataPathsError.missingResource(name)
            }
            try fm.copyItem(at: source, to: destination)
        }
    }

    /// Resolve the on-disk URL for a shipped data file. Prefers the
    /// App Group container copy, falls back to the bundle.
    public static func url(for resource: String) -> URL? {
        if let shared = sharedDataDir?.appendingPathComponent(resource),
           FileManager.default.fileExists(atPath: shared.path) {
            return shared
        }
        return findBundledResource(resource)
    }

    private static func findBundledResource(_ name: String) -> URL? {
        let baseName = (name as NSString).deletingPathExtension
        let ext = (name as NSString).pathExtension
        let extOrNil = ext.isEmpty ? nil : ext

        var candidateBundles: [Bundle] = [
            Bundle.main,
            Bundle(for: BundleAnchor.self)
        ]

        if let pluginsURL = Bundle.main.builtInPlugInsURL?.deletingLastPathComponent(),
           let parentBundle = Bundle(url: pluginsURL) {
            candidateBundles.append(parentBundle)
        }

        for b in candidateBundles {
            if let url = b.url(forResource: baseName, withExtension: extOrNil) {
                return url
            }
            if let url = b.url(forResource: name, withExtension: nil) {
                return url
            }
            if let url = b.url(forResource: baseName, withExtension: extOrNil, subdirectory: "data") {
                return url
            }
            if let url = b.url(forResource: baseName, withExtension: extOrNil, subdirectory: "Resources") {
                return url
            }
        }
        return nil
    }
}

public enum DataPathsError: Error, LocalizedError {
    case appGroupUnavailable
    case missingResource(String)

    public var errorDescription: String? {
        switch self {
        case .appGroupUnavailable:
            return "App Group container is not available. Check entitlements."
        case .missingResource(let name):
            return "Bundled data file '\(name)' is missing."
        }
    }
}

/// Internal anchor used by `Bundle(for:)` so callers don't have to
/// import the host app's target just to resolve a resource.
private final class BundleAnchor: NSObject {}
