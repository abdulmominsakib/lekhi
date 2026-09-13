//
//  MechanicalSoundManager.swift
//  SharedKit
//
//  Synthesizes / triggers zero-latency mechanical switch sounds
//  (Blue, Brown, Red switches and classic iOS clicks).
//

import AudioToolbox
import AVFoundation
#if canImport(UIKit)
import UIKit

/// Opting the input view into `playInputClick()`.
///
/// `AudioServicesPlaySystemSound` is the engine behind the mechanical switch
/// profiles, but a keyboard extension without Full Access cannot always reach
/// the system sound server — which is why key clicks could come out silent on
/// some devices. `UIDevice.playInputClick()` is the one click that is always
/// available to a keyboard, and it only works if the input view declares it.
extension UIInputView: @retroactive UIInputViewAudioFeedback {
    public var enableInputClicksWhenVisible: Bool { true }
}
#endif

public enum MechanicalSwitchProfile: String, CaseIterable, Identifiable, Sendable {
    case blue = "blue"       // Crisp clicky switch
    case brown = "brown"     // Tactile thock
    case red = "red"         // Smooth linear
    case classic = "classic" // iOS standard
    case off = "off"         // Mute

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .blue:    return "Blue Switch (Clicky)"
        case .brown:   return "Brown Switch (Tactile Thock)"
        case .red:     return "Red Switch (Smooth Linear)"
        case .classic: return "Classic Apple Click"
        case .off:     return "Mute (Silent)"
        }
    }

    public var description: String {
        switch self {
        case .blue:    return "High-pitched crisp click with distinct tactile bump"
        case .brown:   return "Warm, medium-pitched deeper mechanical thock"
        case .red:     return "Soft, lightweight acoustic linear keypress"
        case .classic: return "Default iOS keyboard click sound"
        case .off:     return "No audio on key presses"
        }
    }
}

public enum SoundStore {
    private static let key = "LekhiSwitchSoundProfile"
    private static let volumeKey = "LekhiSwitchVolume"

    public static func current() -> MechanicalSwitchProfile {
        let d = AppGroup.defaults
        if let raw = d.string(forKey: key),
           let profile = MechanicalSwitchProfile(rawValue: raw) {
            return profile
        }
        return .blue
    }

    public static func set(_ profile: MechanicalSwitchProfile) {
        AppGroup.defaults.set(profile.rawValue, forKey: key)
        postSettingsChanged()
    }

    public static func volume() -> Float {
        let d = AppGroup.defaults
        if d.object(forKey: volumeKey) != nil {
            return d.float(forKey: volumeKey)
        }
        return 0.8
    }

    public static func setVolume(_ volume: Float) {
        AppGroup.defaults.set(volume, forKey: volumeKey)
        postSettingsChanged()
    }
}

public final class MechanicalSoundManager: @unchecked Sendable {
    public static let shared = MechanicalSoundManager()

    private init() {}

    /// Play the sound corresponding to the current switch profile.
    public func playKeyPress(isReturn: Bool = false, isSpace: Bool = false, isModifier: Bool = false) {
        let profile = SoundStore.current()
        guard profile != .off else { return }

        if profile == .classic {
            // The guaranteed path inside a keyboard extension. Must run on the
            // main thread, and needs `enableInputClicksWhenVisible` above.
            #if canImport(UIKit)
            UIDevice.current.playInputClick()
            return
            #endif
        }

        DispatchQueue.global(qos: .userInitiated).async {
            switch profile {
            case .off:
                break

            case .classic:
                if isModifier {
                    AudioServicesPlaySystemSound(1156) // Modifier click
                } else if isReturn {
                    AudioServicesPlaySystemSound(1105) // Return click
                } else {
                    AudioServicesPlaySystemSound(1104) // Standard keyboard tap
                }

            case .blue:
                // High clicky system sound mapping
                if isReturn {
                    AudioServicesPlaySystemSound(1105)
                } else if isSpace {
                    AudioServicesPlaySystemSound(1104)
                } else if isModifier {
                    AudioServicesPlaySystemSound(1156)
                } else {
                    AudioServicesPlaySystemSound(1104)
                }

            case .brown:
                // Deeper tactile thock
                if isReturn {
                    AudioServicesPlaySystemSound(1105)
                } else if isModifier {
                    AudioServicesPlaySystemSound(1155)
                } else {
                    AudioServicesPlaySystemSound(1104)
                }

            case .red:
                // Smooth linear softer tap
                if isModifier {
                    AudioServicesPlaySystemSound(1156)
                } else {
                    AudioServicesPlaySystemSound(1104)
                }
            }
        }
    }
}
