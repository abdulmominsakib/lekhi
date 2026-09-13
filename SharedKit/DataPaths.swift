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

    /// Legacy directory inside the App Group container where the bundled
    /// JSON files used to be copied on first launch. Older builds pointed
    /// the engine at this copy; we now read straight from the bundle.
    public static var sharedDataDir: URL? {
        AppGroup.containerURL?.appendingPathComponent(
            "LekhiData", isDirectory: true
        )
    }

    /// Directory the riti engine should use as its `database_dir`.
    ///
    /// Both the host app and the keyboard extension embed the four data
    /// files, so each target reads them from its own bundle. That matters:
    /// the previous implementation copied 4 MB into the App Group with a
    /// non-atomic `copyItem` on the main thread during keyboard start-up.
    /// A keyboard extension is terminated aggressively (jetsam, dismissal),
    /// and a copy interrupted half-way left a truncated `dictionary.json`
    /// behind. The "already copied?" check was a plain `fileExists`, so the
    /// broken file was never repaired, riti failed to parse it, context
    /// creation returned NULL, and the keyboard silently fell back to
    /// inserting raw Latin letters — permanently, on that device only.
    ///
    /// Returns `nil` when the bundle is incomplete, which the engine
    /// surfaces as a diagnosable failure instead of a silent one.
    public static func databaseDirectory() -> URL? {
        guard let dictionary = findBundledResource("dictionary.json") else {
            return nil
        }
        let directory = dictionary.deletingLastPathComponent()
        // The engine expects to find its whole data set in one directory.
        let complete = shippedResources.allSatisfy { name in
            FileManager.default.fileExists(
                atPath: directory.appendingPathComponent(name).path
            )
        }
        return complete ? directory : nil
    }

    /// Writable directory handed to riti for its user data (remembered
    /// candidate selections). Falls back to the target's own caches
    /// directory when the App Group is unavailable — for example when the
    /// build is signed with a provisioning profile that lacks the group.
    public static func userDirectory() -> URL? {
        let base = AppGroup.containerURL
            ?? FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
        guard let base else { return nil }
        let directory = base.appendingPathComponent("RitiUser", isDirectory: true)
        do {
            try FileManager.default.createDirectory(
                at: directory,
                withIntermediateDirectories: true
            )
        } catch {
            return nil
        }
        return directory
    }

    /// Resolve the on-disk URL for a shipped data file, from the bundle.
    public static func url(for resource: String) -> URL? {
        findBundledResource(resource)
    }

    /// Remove the legacy App Group copy of the bundled data files.
    ///
    /// These are our own duplicates of read-only bundle resources — never
    /// user data — so reclaiming them is safe, and it also clears any
    /// half-written `dictionary.json` left by an older build. Only the
    /// filenames we shipped are removed, and the directory only if it ends
    /// up empty.
    public static func removeLegacyAppGroupCopy() {
        guard let dataDir = sharedDataDir else { return }
        let fm = FileManager.default
        guard fm.fileExists(atPath: dataDir.path) else { return }

        for name in shippedResources {
            let file = dataDir.appendingPathComponent(name)
            if fm.fileExists(atPath: file.path) {
                try? fm.removeItem(at: file)
            }
        }
        if let remaining = try? fm.contentsOfDirectory(atPath: dataDir.path),
           remaining.isEmpty {
            try? fm.removeItem(at: dataDir)
        }
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
