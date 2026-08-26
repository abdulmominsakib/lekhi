# Lekhi (লেখী) — 3D Mechanical Avro Phonetic Bangla Keyboard for iOS

<div align="center">

<img src="../app_logo.png" width="128" height="128" alt="Lekhi App Logo" style="border-radius: 28px; box-shadow: 0 8px 24px rgba(0,0,0,0.15);" />

<br/><br/>

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Platform: iOS 17+](https://img.shields.io/badge/Platform-iOS%2017.0+-orange.svg)](https://apple.com/ios)
[![Swift: 5.10+](https://img.shields.io/badge/Swift-5.10+-red.svg)](https://swift.org)
[![Engine: OpenBangla/riti](https://img.shields.io/badge/Engine-OpenBangla%2Friti%20(MPL--2.0)-success.svg)](https://github.com/OpenBangla/riti)
[![Privacy: 100% Offline](https://img.shields.io/badge/Privacy-100%25%20Offline%20%26%20Zero%20Telemetry-brightgreen.svg)](https://momin.pro/lekhi-privacy-policy)

**An open-source, privacy-first, tactile 3D mechanical Avro Phonetic Bangla keyboard built natively for iPhone.**

[GitHub Repository](https://github.com/abdulmominsakib/lekhi) • [Privacy Policy](https://momin.pro/lekhi-privacy-policy) • [Developer Website](https://momin.pro)

</div>

---

## ✨ Features

- **⌨️ Avro Phonetic Typing**: Write natural Bengali using intuitive phonetic English syntax (e.g., `ami` → **আমি**, `bangla` → **বাংলা**).
- **🔊 Tactile 3D Mechanical Keycaps & Audio**: Authentic mechanical switch sound profiles (**Blue Switch (Clicky)**, **Brown Switch (Tactile)**, **Red Switch (Linear)**, **Black Switch**, and **Cream Switch**).
- **📳 Haptic Touch Engine**: Responsive, finely-tuned physical vibration for every keystroke with adjustable intensity (**Light**, **Medium**, **Strong**) that works reliably even without "Full Access".
- **🔍 Apple-Style Keypress Highlight & Popups**: Native elevated character preview magnification balloons and active keypress depression on touch-down.
- **📐 Adjustable Keyboard Height**: 5 calibrated ergonomic height options (**Compact**, **Standard**, **Medium Tall**, **Tall**, and **Extra Tall**) to fit any screen size or thumb reach.
- **📚 150,000+ Word Dictionary & Smart Autocorrect**: On-device candidate suggestions with a three-card suggestion bar.
- **🔄 Multi-Layout & Spacebar Swipe**: Instant switching between **Avro Phonetic**, **Probhat Layout**, and **English** with a simple swipe on the spacebar.
- **🔢 Bengali Numerals (১, ২, ৩)**: Toggleable auto-conversion for numbers to native Bengali digits.
- **📖 Integrated Avro Cheat Sheet**: Searchable reference guide for Vowels (স্বরবর্ণ), Consonants (ব্যঞ্জনবর্ণ), Kar (কার), and Conjuncts (যুক্তবর্ণ).
- **⚡ Bangla Typing Speed Test**: Built-in speed typing practice game with live Words-Per-Minute (WPM), accuracy tracking, and time metrics.
- **🎨 Premium Theme Collection**: Classic Mechanical (Light), Onyx Mechanical (Dark), Pure AMOLED Black, Retro 80s Beige, and automatic iOS system appearance.
- **🛡️ 100% Offline & Private**: Zero network requests, zero telemetry, and **no "Allow Full Access" permissions required**.

---

## 📱 Screenshots

| Interactive Typing | Home Dashboard | Avro Cheat Sheet |
| :---: | :---: | :---: |
| ![Typing Playground](../screenshots/01_hero_typing_playground.png) | ![Home Dashboard](../screenshots/02_home_dashboard.png) | ![Cheat Sheet](../screenshots/03_avro_cheatsheet.png) |

| Typing Speed Test | Customization Settings | Engine & Privacy |
| :---: | :---: | :---: |
| ![Typing Speed Test](../screenshots/04_typing_speed_test.png) | ![Settings](../screenshots/05_settings_customization.png) | ![Privacy Specs](../screenshots/06_privacy_and_engine.png) |

---

## 🏛️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│ iOS Device (iPhone running iOS 17.0+)                       │
│                                                             │
│  Lekhi Host App (SwiftUI)                                   │
│  ├─ Dashboard (HomeView)                                    │
│  ├─ Mechanical Playground (KeyboardPreviewScreen)           │
│  ├─ Avro Cheat Sheet (CheatSheetView)                       │
│  ├─ Typing Speed Practice Game (TypingSpeedGameView)        │
│  └─ Settings & Diagnostics (SettingsView / EngineInfoView)  │
│                                                             │
│  Lekhi Keyboard Extension (PlugIns/LekhiKeyboard.appex)     │
│  ├─ KeyboardViewController (UIInputViewController)          │
│  ├─ KeyboardRootView (SwiftUI 3D Keycaps & Grid)            │
│  ├─ SuggestionBarView (3-Card Candidate Selection)         │
│  ├─ InputSession & MechanicalSoundManager / HapticManager   │
│  ├─ RitiEngine (Swift FFI bridge)                           │
│  └─ RitiFFI.xcframework (Rust Transliteration Engine)       │
│                                                             │
│  App Group Shared Container (group.com.lekhi.ios)           │
│  └─ dictionary.json • autocorrect.json • suffix.json        │
└─────────────────────────────────────────────────────────────┘
```

Both the host application and keyboard extension operate securely within iOS app sandboxing and share dictionary data through the App Group container (`group.com.lekhi.ios`).

---

## 🚀 Getting Started & Build Instructions

### Prerequisites
- macOS Sonoma or macOS Sequoia
- Xcode 15.0+ or Xcode 16.0+ (iOS 17.0+ SDK)
- *(Optional for Rust builds)* Rust toolchain: `rustup target add aarch64-apple-ios aarch64-apple-ios-sim`

### Step 1: Clone the Repository
```bash
git clone https://github.com/abdulmominsakib/lekhi.git
cd lekhi/Lekhi
```

### Step 2: Build the Transliteration Engine XCFramework

**Option A: Using the fast C stub (ideal for quick compilation without Rust):**
```bash
bash scripts/build_stub_xcframework.sh
```

**Option B: Compiling the full Rust engine from source:**
```bash
bash scripts/build_xcframework.sh
```

### Step 3: Open and Run in Xcode
```bash
open Lekhi.xcodeproj
```

Select the **Lekhi** scheme and choose your target simulator or connected iOS device, then press **Cmd + R** to build and run.

---

## 🛠️ Enabling the Keyboard on iOS

1. Launch the **Lekhi** app once to initialize dictionary resources.
2. Open iOS **Settings** → **General** → **Keyboard** → **Keyboards**.
3. Tap **Add New Keyboard...** and choose **Lekhi** under Third-Party Keyboards.
4. Open any app (Notes, Messages, WhatsApp, Safari), tap the text field, and tap/hold the **🌐 globe key** to select **Lekhi**.
5. Start typing in phonetic English (e.g. `ami banglay gan gai` → **আমি বাংলায় গান গাই**)!

---

## 🔒 Privacy Guarantee

Lekhi is built with strict privacy principles:
- **No Network Permissions**: Lekhi has zero internet access capabilities.
- **No Open Access Required**: `RequestsOpenAccess` is set to `false`.
- **Zero Keystroke Logging**: Your keystrokes never leave your phone's memory.
- **Zero Analytics / Telemetry**: No third-party SDKs or tracking pixels.

Read the full [Privacy Policy](https://momin.pro/lekhi-privacy-policy).

---

## 📄 License & Open-Source Credits

- **Lekhi App & iOS Keyboard UI**: Licensed under the **[MIT License](LICENSE)**. © 2026 [Abdul Momin Sakib](https://github.com/abdulmominsakib).
- **OpenBangla/riti**: Transliteration engine licensed under the **[Mozilla Public License 2.0 (MPL-2.0)](https://github.com/OpenBangla/riti)**.
- **Lekho (macOS)**: Original macOS reference keyboard by Abdur Rahim ([ARahim3/Lekho](https://github.com/ARahim3/Lekho)).

---

## 🤝 Contributing

Contributions, feature suggestions, and bug reports are welcome!
1. Fork the repository on [GitHub](https://github.com/abdulmominsakib/lekhi).
2. Create your feature branch (`git checkout -b feature/AmazingFeature`).
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`).
4. Push to the branch (`git push origin feature/AmazingFeature`).
5. Open a Pull Request.

---

<div align="center">
Made with ❤️ by <a href="https://momin.pro">Abdul Momin Sakib</a>
</div>
