//
//  HapticManager.swift
//  SharedKit
//
//  Manages tactile haptic feedback for mechanical keyboard interactions.
//

import UIKit
import AudioToolbox

public enum HapticIntensity: String, CaseIterable, Identifiable, Sendable {
    case off = "off"
    case subtle = "subtle"
    case light = "light"
    case medium = "medium"
    case strong = "strong"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .off:    return "Off"
        case .subtle: return "Ultra Subtle (Feather Soft)"
        case .light:  return "Light (Gentle Click)"
        case .medium: return "Medium (Mechanical Click)"
        case .strong: return "Strong (Tactile Thock)"
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
        return .subtle
    }

    public static func set(_ intensity: HapticIntensity) {
        AppGroup.defaults.set(intensity.rawValue, forKey: key)
        postSettingsChanged()
    }
}

public final class HapticManager: @unchecked Sendable {
    public static let shared = HapticManager()

    private let softGenerator = UIImpactFeedbackGenerator(style: .soft)
    private let lightGenerator = UIImpactFeedbackGenerator(style: .light)
    private let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let rigidGenerator = UIImpactFeedbackGenerator(style: .rigid)
    private let heavyGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private let selectionGenerator = UISelectionFeedbackGenerator()

    private init() {
        prepare()
    }

    public func prepare() {
        softGenerator.prepare()
        lightGenerator.prepare()
        mediumGenerator.prepare()
        rigidGenerator.prepare()
        heavyGenerator.prepare()
        selectionGenerator.prepare()
    }

    /// Triggers a finely tuned haptic impulse matching the user's intensity preference.
    ///
    /// Each generator fires first and is re-armed afterwards. Calling
    /// `prepare()` immediately before firing gave the Taptic Engine no time to
    /// spin up, so it only added work on touch-down; preparing after the tap
    /// readies it for the next keystroke instead.
    public func keyPress(isAction: Bool = false) {
        let intensity = HapticStore.current()
        guard intensity != .off else { return }

        switch intensity {
        case .off:
            break

        case .subtle:
            // The system selection tick — the faint click a picker wheel makes.
            // This used to be the `.soft` impact at 18% intensity, which is
            // below what the Taptic Engine will actually actuate: `.soft` is
            // already the weakest, most damped waveform, so scaling it that far
            // produced nothing. The selection tick has a fixed, always-felt
            // strength and still sits clearly below "Light".
            selectionGenerator.selectionChanged()
            selectionGenerator.prepare()

        case .light:
            // Subtle, crisp light keystroke tap
            if isAction {
                lightGenerator.impactOccurred(intensity: 0.55)
                lightGenerator.prepare()
            } else {
                softGenerator.impactOccurred(intensity: 0.48)
                softGenerator.prepare()
            }

        case .medium:
            if isAction {
                mediumGenerator.impactOccurred(intensity: 0.75)
                mediumGenerator.prepare()
            } else {
                rigidGenerator.impactOccurred(intensity: 0.65)
                rigidGenerator.prepare()
            }

        case .strong:
            if isAction {
                heavyGenerator.impactOccurred(intensity: 1.0)
                heavyGenerator.prepare()
            } else {
                heavyGenerator.impactOccurred(intensity: 0.9)
                heavyGenerator.prepare()
            }
        }
    }

    /// Haptic feedback when a candidate or suggestion is selected from the bar or language switched.
    public func candidateSelected() {
        let intensity = HapticStore.current()
        guard intensity != .off else { return }
        selectionGenerator.selectionChanged()
        selectionGenerator.prepare()
    }
}
