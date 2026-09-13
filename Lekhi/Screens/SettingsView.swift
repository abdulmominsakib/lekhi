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
    @State private var enabledLayouts: [Layout] = LayoutStore.enabled()
    @State private var bengaliDigits: Bool = BengaliDigitStore.current()
    @State private var spacebarSwipe: Bool = SpacebarSwipeStore.current()
    @State private var keyHints: Bool = KeyHintStore.current()
    @State private var soundEnabled: Bool = SoundStore.current() != .off
    @State private var hapticsEnabled: Bool = HapticStore.current() != .off

    @State private var fullAccess: FullAccessStatus = FullAccessReporter.current()
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        NavigationStack {
            Form {
                if !fullAccess.isGranted {
                    Section {
                        FullAccessCallout()
                    }
                }

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

                    Toggle("Bangla Hints on Keycaps", isOn: $keyHints)
                        .onChange(of: keyHints) { _, newValue in
                            KeyHintStore.set(newValue)
                        }
                } header: {
                    Text("Feedback & Touch")
                } footer: {
                    Text("Customize key click sounds, tactile Taptic vibrations, and Apple-style character magnification popups. Turn off keycap hints for bare white keys.")
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

                // Keyboard Layouts
                Section {
                    ForEach(Layout.allCases) { item in
                        let isOn = enabledLayouts.contains(item)
                        let isLast = isOn && enabledLayouts.count == 1
                        Toggle(isOn: Binding(
                            get: { enabledLayouts.contains(item) },
                            set: { newValue in
                                LayoutStore.setEnabled(item, newValue)
                                enabledLayouts = LayoutStore.enabled()
                                layout = LayoutStore.current()
                            }
                        )) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.displayName)
                                    .font(.system(size: 15, weight: .medium))
                                Text(isLast ? "At least one layout has to stay on." : item.subtitle)
                                    .font(.system(size: 12))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .disabled(isLast)
                    }
                } header: {
                    Text("Keyboard layouts")
                } footer: {
                    Text("Swipe the spacebar to move between the layouts you turn on.")
                }

                if enabledLayouts.count > 1 {
                    Section {
                        Picker("Layout", selection: $layout) {
                            ForEach(enabledLayouts) { layoutOption in
                                Text(layoutOption.displayName).tag(layoutOption)
                            }
                        }
                        .pickerStyle(.inline)
                        .labelsHidden()
                    } header: {
                        Text("Current layout")
                    } footer: {
                        Text("Avro Phonetic is recommended.")
                    }
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
                    EngineStatusRow()

                    LabeledContent {
                        HStack(spacing: 6) {
                            Image(systemName: fullAccess.isGranted
                                  ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                .foregroundStyle(fullAccess.isGranted ? Color.green : Color.orange)
                            Text(fullAccess.displayName)
                                .foregroundStyle(.secondary)
                        }
                    } label: {
                        Label("Full Access", systemImage: "hand.raised")
                    }

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
            .onChange(of: layout) { _, newValue in
                if newValue != LayoutStore.current() { LayoutStore.set(newValue) }
            }
            .onAppear(perform: refreshFromStores)
            // Returning from iOS Settings (e.g. after allowing Full Access)
            // doesn't re-run `onAppear`.
            .onChange(of: scenePhase) { _, phase in
                if phase == .active { refreshFromStores() }
            }
        }
    }

    /// Re-read every store when the screen comes back.
    ///
    /// These `@State` values are seeded once, but the keyboard can change
    /// settings on its own — a spacebar swipe switches the layout — which left
    /// the pickers showing a stale selection until the app was relaunched.
    private func refreshFromStores() {
        theme = ThemeStore.current()
        switchSound = SoundStore.current()
        haptics = HapticStore.current()
        keyboardHeight = KeyboardHeightStore.current()
        characterPreview = CharacterPreviewStore.current()
        typingMode = TypingModeStore.current()
        layout = LayoutStore.current()
        enabledLayouts = LayoutStore.enabled()
        bengaliDigits = BengaliDigitStore.current()
        spacebarSwipe = SpacebarSwipeStore.current()
        keyHints = KeyHintStore.current()
        soundEnabled = switchSound != .off
        hapticsEnabled = haptics != .off
        fullAccess = FullAccessReporter.current()
    }
}

/// Explains why Lekhi asks for Full Access and how to grant it.
struct FullAccessCallout: View {

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Allow Full Access for key vibrations", systemImage: "hand.raised.circle.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.orange)

            Text("iOS doesn't let a custom keyboard use the Taptic Engine without Full Access. Typing, suggestions and every setting on this screen work either way — only the vibrations need it.")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)

            Text("Settings → General → Keyboard → Keyboards → Lekhi → Allow Full Access")
                .font(.system(size: 12, design: .rounded))
                .foregroundStyle(.secondary)

            Text("Lekhi still makes no network requests and collects nothing — it has no networking code at all.")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)

            if let url = URL(string: UIApplication.openSettingsURLString) {
                Link(destination: url) {
                    Label("Open Settings", systemImage: "arrow.up.right.square")
                        .font(.system(size: 14, weight: .semibold))
                }
            }
        }
        .padding(.vertical, 4)
    }
}

/// Surfaces whether the transliteration engine actually started.
///
/// When engine construction fails the keyboard stays usable but inserts plain
/// Latin letters, which users report as "phonetic stopped working". Showing
/// the recorded reason turns a silent, device-specific failure into something
/// that can be diagnosed.
struct EngineStatusRow: View {

    @State private var state: EngineState = EngineDiagnostics.current()

    var body: some View {
        LabeledContent {
            HStack(spacing: 6) {
                Image(systemName: state.isHealthy ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .foregroundStyle(state.isHealthy ? Color.green : Color.orange)
                Text(state.displayName)
                    .foregroundStyle(.secondary)
            }
        } label: {
            Label("Engine Status", systemImage: "waveform.badge.magnifyingglass")
        }
        .onAppear { state = EngineDiagnostics.current() }

        if let hint = state.recoveryHint, !state.isHealthy {
            Text(hint)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
        }
    }
}

struct EngineInfoView: View {

    @State private var engineState: EngineState = EngineDiagnostics.current()

    var body: some View {
        Form {
            Section {
                EngineStatusRow()
                if let updated = EngineDiagnostics.lastUpdated() {
                    LabeledContent("Last Checked") {
                        Text(updated, style: .relative) + Text(" ago")
                    }
                }
            } header: {
                Text("Diagnostics")
            } footer: {
                Text("Updated each time the Lekhi keyboard starts up.")
            }

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
