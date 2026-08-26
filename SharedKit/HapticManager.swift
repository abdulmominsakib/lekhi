//
//  HapticManager.swift
//  SharedKit
//
//  Manages tactile haptic feedback for mechanical keyboard interactions.
//

import UIKit

public enum HapticIntensity: String, CaseIterable, Identifiable, Sendable {
    case off = "off"
    case light = "light"
    case medium = "medium"
    case strong = "strong"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .off:    return "Off"
        case .light:  return "Light (Subtle)"
        case .medium: return "Medium (Mechanical Click)"
        case .strong: return "Strong (Heavy Tactile)"
        }
    }
}

public enum HapticStore {
    private static let key = "LekhiHapticIntensity"

    public static func current() -> HapticIntensity {
        let d = AppGroup.defaults
        if let raw = d.string(forKey: key),
           let intensity = HapticIntensity(rawValue: raw) {
            return intensity
        }
        return .medium
    }

    public static func set(_ intensity: HapticIntensity) {
        AppGroup.defaults.set(intensity.rawValue, forKey: key)
        postSettingsChanged()
    }
}

public final class HapticManager: @unchecked Sendable {
    public static let shared = HapticManager()

    private let lightGenerator = UIImpactFeedbackGenerator(style: .light)
    private let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let rigidGenerator = UIImpactFeedbackGenerator(style: .rigid)
    private let selectionGenerator = UISelectionFeedbackGenerator()

    private init() {
        prepare()
    }

    public func prepare() {
        lightGenerator.prepare()
        mediumGenerator.prepare()
        rigidGenerator.prepare()
        selectionGenerator.prepare()
    }

    public func keyPress(isAction: Bool = false) {
        let intensity = HapticStore.current()
        guard intensity != .off else { return }

        switch intensity {
        case .off:
            break
        case .light:
            lightGenerator.impactOccurred(intensity: 0.6)
        case .medium:
            if isAction {
                mediumGenerator.impactOccurred(intensity: 0.8)
            } else {
                rigidGenerator.impactOccurred(intensity: 0.7)
            }
        case .strong:
            if isAction {
                rigidGenerator.impactOccurred(intensity: 1.0)
            } else {
                mediumGenerator.impactOccurred(intensity: 1.0)
            }
        }
    }

    public func candidateSelected() {
        let intensity = HapticStore.current()
        guard intensity != .off else { return }
        selectionGenerator.selectionChanged()
    }
}
