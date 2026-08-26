//
//  SettingsView.swift
//  Lekhi
//
//  Comprehensive settings: Theme, Switch Sounds, Haptics, Typing Modes, Layouts, Engine info.
//

import SwiftUI

struct SettingsView: View {

    @State private var theme: KeyboardThemeID = ThemeStore.current()
    @State private var switchSound: MechanicalSwitchProfile = SoundStore.current()
    @State private var haptics: HapticIntensity = HapticStore.current()
    @State private var keyboardHeight: KeyboardHeightOption = KeyboardHeightStore.current()
    @State private var characterPreview: Bool = CharacterPreviewStore.current()
    @State private var typingMode: TypingMode = TypingModeStore.current()
    @State private var layout: Layout = LayoutStore.current()
    @State private var bengaliDigits: Bool = BengaliDigitStore.current()
    @State private var spacebarSwipe: Bool = SpacebarSwipeStore.current()
    @State private var soundEnabled: Bool = SoundStore.current() != .off
    @State private var hapticsEnabled: Bool = HapticStore.current() != .off

    var body: some View {
        NavigationStack {
            Form {
                // Feedback & Interaction
                Section {
                    Toggle("Key Click Sounds", isOn: $soundEnabled)
                        .onChange(of: soundEnabled) { _, on in
                            let newProfile: MechanicalSwitchProfile = on ? (switchSound == .off ? .blue : switchSound) : .off
                            switchSound = newProfile
                            SoundStore.set(newProfile)
                        }

                    if soundEnabled {
                        Picker("Switch Profile", selection: $switchSound) {
                            ForEach(MechanicalSwitchProfile.allCases.filter { $0 != .off }) { profile in
                                Text(profile.displayName).tag(profile)
                            }
                        }
                        .onChange(of: switchSound) { _, newValue in
                            SoundStore.set(newValue)
                            MechanicalSoundManager.shared.playKeyPress()
                        }
                    }

                    Toggle("Haptic Feedback", isOn: $hapticsEnabled)
                        .onChange(of: hapticsEnabled) { _, on in
                            let newIntensity: HapticIntensity = on ? (haptics == .off ? .subtle : haptics) : .off
                            haptics = newIntensity
                            HapticStore.set(newIntensity)
                            if on { HapticManager.shared.keyPress(isAction: true) }
                        }

                    if hapticsEnabled {
                        Picker("Haptic Intensity", selection: $haptics) {
                            ForEach(HapticIntensity.allCases.filter { $0 != .off }) { intensity in
                                Text(intensity.displayName).tag(intensity)
                            }
                        }
                        .onChange(of: haptics) { _, newValue in
                            HapticStore.set(newValue)
                            HapticManager.shared.keyPress(isAction: true)
                        }
                    }

                    Toggle("Key Popups (Character Preview)", isOn: $characterPreview)
                        .onChange(of: characterPreview) { _, newValue in
                            CharacterPreviewStore.set(newValue)
                        }
                } header: {
                    Text("Feedback & Touch")
                } footer: {
                    Text("Customize key click sounds, tactile Taptic vibrations, and Apple-style character magnification popups.")
                }

                // Keyboard Height Adjustment
                Section {
                    Picker("Keyboard Height", selection: $keyboardHeight) {
                        ForEach(KeyboardHeightOption.allCases) { item in
                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text(item.displayName)
                                        .font(.system(size: 15, weight: .medium))
                                    Spacer()
                                    Text("\(Int(item.scaleFactor * 100))%")
                                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                                        .foregroundStyle(item == keyboardHeight ? Color.blue : .secondary)
                                }
                                Text(item.subtitle)
                                    .font(.system(size: 12))
                                    .foregroundStyle(.secondary)
                            }
                            .tag(item)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                } header: {
                    Text("Keyboard Height")
                } footer: {
                    Text("Adjust keycap size and keyboard height to fit your typing ergonomics.")
                }
                .onChange(of: keyboardHeight) { _, newValue in
                    KeyboardHeightStore.set(newValue)
                }

                // Keyboard Theme
                Section {
                    Picker("Theme", selection: $theme) {
                        ForEach(KeyboardThemeID.allCases) { item in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.displayName)
                                    .font(.system(size: 15, weight: .medium))
                                Text(item.subtitle)
                                    .font(.system(size: 12))
                                    .foregroundStyle(.secondary)
                            }
                            .tag(item)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                } header: {
                    Text("Keyboard Theme")
                } footer: {
                    Text("Select your mechanical keyboard styling. System Automatic dynamically switches between Light and Dark mode.")
                }
                .onChange(of: theme) { _, newValue in
                    ThemeStore.set(newValue)
                }

                // Typing Mode
                Section {
                    Picker("Typing mode", selection: $typingMode) {
                        ForEach(TypingMode.allCases) { mode in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(mode.displayName)
                                    .font(.system(size: 15, weight: .medium))
                                Text(mode.subtitle)
                                    .font(.system(size: 12))
                                    .foregroundStyle(.secondary)
                            }
                            .tag(mode)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                } header: {
                    Text("Typing mode")
                } footer: {
                    Text("Phonetic First commits your exact spelling by default while keeping suggestions one tap away.")
                }
                .onChange(of: typingMode) { _, newValue in
                    TypingModeStore.set(newValue)
                }

                // Phonetic Layout
                Section {
                    Picker("Layout", selection: $layout) {
                        ForEach(Layout.allCases) { layoutOption in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(layoutOption.displayName)
                                    .font(.system(size: 15, weight: .medium))
                                Text(layoutOption.subtitle)
                                    .font(.system(size: 12))
                                    .foregroundStyle(.secondary)
                            }
                            .tag(layoutOption)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                } header: {
                    Text("Phonetic layout")
                } footer: {
                    Text("Avro Phonetic is recommended.")
                }
                .onChange(of: layout) { _, newValue in
                    LayoutStore.set(newValue)
                }

                // Numbers & Digits
                Section {
                    Toggle("Bengali Numerals (১, ২, ৩)", isOn: $bengaliDigits)
                        .onChange(of: bengaliDigits) { _, newValue in
                            BengaliDigitStore.set(newValue)
                        }
                } header: {
                    Text("Numbers")
                } footer: {
                    Text("Convert number key presses to Bengali digits (১, ২, ৩...) automatically.")
                }

                // Spacebar Language Switcher
                Section {
                    Toggle("Spacebar Swipe Language Switcher", isOn: $spacebarSwipe)
                        .onChange(of: spacebarSwipe) { _, newValue in
                            SpacebarSwipeStore.set(newValue)
                        }
                } header: {
                    Text("Spacebar")
                } footer: {
                    Text("Swipe left or right on the spacebar to switch between English, Avro Phonetic, and Probhat layouts.")
                }

                // Open Source & Community
                Section {
                    if let url = URL(string: "https://github.com/abdulmominsakib/lekhi") {
                        Link(destination: url) {
                            HStack {
                                Label("GitHub Repository", systemImage: "chevron.left.forwardslash.chevron.right")
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    LabeledContent("License") {
                        Text("MIT License")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Open Source")
                } footer: {
                    Text("Lekhi is free and open-source software hosted at github.com/abdulmominsakib/lekhi under the MIT License.")
                }

                // About & Diagnostics
                Section {
                    NavigationLink {
                        EngineInfoView()
                    } label: {
                        Label("Transliteration Engine", systemImage: "cpu")
                    }

                    NavigationLink {
                        AboutView()
                    } label: {
                        Label("About Lekhi", systemImage: "info.circle")
                    }
                } header: {
                    Text("System & Diagnostics")
                }
            }
            .navigationTitle("Settings")
        }
    }
}

struct EngineInfoView: View {

    var body: some View {
        Form {
            Section {
                LabeledContent("App Name") { Text("Lekhi (লেখী)") }
                LabeledContent("Transliteration Engine") { Text("Riti (Avro Phonetic)") }
                LabeledContent("Open Source Base") { Text("OpenBangla / Lekho") }
                LabeledContent("Dictionary Words") { Text("150,000+") }
                LabeledContent("Security & Privacy") { Text("100% Offline, Zero Telemetry") }
                LabeledContent("App License") { Text("MIT License") }
                LabeledContent("Engine License") { Text("MPL-2.0") }
            } header: {
                Text("Engine Specifications")
            }

            Section {
                if let url = URL(string: "https://github.com/abdulmominsakib/lekhi") {
                    Link(destination: url) {
                        HStack {
                            Text("Source Code (GitHub)")
                            Spacer()
                            Text("abdulmominsakib/lekhi")
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                if let url = URL(string: "https://momin.pro/lekhi-privacy-policy") {
                    Link(destination: url) {
                        HStack {
                            Text("Privacy Policy")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } header: {
                Text("Open Source & Privacy Links")
            }

            Section {
                Text("Lekhi is a standalone, privacy-first mechanical Bangla keyboard for iOS. All transliteration, dictionary lookups, and autocorrect operations execute entirely on your device with zero data transmission.")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            } header: {
                Text("About the Engine")
            }
        }
        .navigationTitle("Engine Specifications")
    }
}
