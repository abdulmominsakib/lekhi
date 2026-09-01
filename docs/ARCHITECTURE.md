# Architecture

## Overview

Lekho iOS ships two Xcode targets sharing the same Swift source
files for the engine, the input session, the suggestion bar, and
all the data wiring. The keyboard extension embeds the host app
and runs inside iOS's input system via `UIInputViewController`.

## Targets

### `LekhoiOS` (host app, iOS app)

SwiftUI-based shell. Shows onboarding, settings, and a built-in
test field. Provides the user-facing identity of the product and
the App Store entry point. Hosts the keyboard extension via the
"Embed Foundation Extensions" build phase.

### `LekhoKeyboard` (custom keyboard extension)

Subclasses `UIInputViewController`. Hosts a SwiftUI tree built
from `KeyboardRootView`. On every key tap:

1. SwiftUI fires the `KeyAction` callback.
2. `KeyboardViewController.dispatch(action:)` forwards it to
   `KeyRouter.route(action:)`.
3. `KeyRouter` consults the engine (`RitiEngine`) and the
   `InputSession` (Observable model).
4. The router returns a `KeyOutcome` — either `.insert(text)`,
   `.deleteBackward`, `.advanceInputMode`, or `.none`.
5. The view controller applies the outcome to the text document
   proxy (`textDocumentProxy.insertText`, `deleteBackward`,
   `advanceToNextInputMode`).

## Modules

The codebase deliberately avoids formal Swift modules so that the
same files can be compiled into both targets without an explicit
framework dependency:

- **`SharedKit/`** — typed wrappers, enums, data path resolution.
  Files compile into both targets.
- **`LekhoiOS/Screens/`** — host-app-only views (Home, Settings,
  About, TestTextFieldView, KeyboardPreviewScreen).
- **`LekhoKeyboard/Keyboard/`** — keyboard-only SwiftUI views
  (Theme, KeyboardLayout, KeyboardKey, KeyboardRootView,
  SuggestionBarView, KeyAction, KeyKind).
- **`LekhoKeyboard/Input/`** — keyboard-only logic (InputSession,
  KeyRouter, BengaliDigitInput).
- **`LekhoKeyboard/KeyboardViewController.swift`** — the
  UIKit/AppKit bridge.

## Transliteration engine

`RitiEngine` is a Swift class that wraps the C FFI exported by
`avrobangla_engine` (Rust crate). The FFI surface mirrors the
macOS Lekho upstream verbatim:

- `riti_context_new_with_config` / `riti_context_free`
- `riti_get_suggestion_for_key` — drive the engine with a keycode
- `riti_context_backspace_event` — handle backspace
- `riti_context_candidate_committed` — notify the engine that the
  user picked a candidate
- `riti_context_finish_input_session` — end the session
- `riti_context_ongoing_input_session` — query session state
- `riti_suggestion_*` family — extract strings from the result
- `avro_keycode_for_char` — map a Swift `Character` to the riti
  virtual keycode

### Three typing modes

| Mode | Engine state | Suggestion bar |
|------|--------------|----------------|
| `.smart` | one primary context | shows top 3 ranked candidates |
| `.phoneticFirst` | one primary context | shows top 3, phonetic pre-selected |
| `.phoneticOnly` | one phonetic-only context | none, commits inline |

In `.phoneticFirst`, the wrapper selects riti's literal phonetic
candidate from its ranked output. This keeps the keyboard to one
engine context while preserving Lekho's phonetic-first behaviour.

## App Group + data files

- App Group: `group.com.lekho.ios` (declared in both
  entitlements files).
- `DataPaths.ensureDataFilesCopied()` runs on first launch of
  either target and copies the bundled JSON files into
  `<AppGroup>/LekhoData/`.
- The engine reads its dictionary, autocorrect, suffix, and
  Probhat files from there. The host app's bundled copy is only
  used as the source for this copy.

## Settings → Extension sync

- Host and extension share `UserDefaults(suiteName:
  "group.com.lekho.ios")`.
- When the user toggles a setting in the host app, the host
  posts a Darwin notification
  (`com.lekho.ios.settingsChanged`).
- The extension listens for this notification and rebuilds the
  engine if mode / layout changed. As a safety net, the
  extension also rebuilds in `viewWillAppear` based on the
  current settings values.

## File layout summary

```
/Volumes/extreme_II/projects_II/lekhi/LekhoiOS/
├── LekhoiOS.xcodeproj/
├── LekhoiOS/
│   ├── LekhoiOSApp.swift
│   ├── Info.plist
│   ├── LekhoiOS.entitlements
│   ├── Assets.xcassets/
│   ├── Resources/
│   │   ├── dictionary.json   ← copied from /Lekho/data
│   │   ├── autocorrect.json
│   │   ├── suffix.json
│   │   └── probhat.json
│   ├── Onboarding/
│   │   └── OnboardingView.swift
│   └── Screens/
│       ├── MainTabView.swift
│       ├── HomeView.swift
│       ├── SettingsView.swift
│       ├── AboutView.swift
│       ├── TestTextFieldView.swift
│       └── KeyboardPreviewScreen.swift
├── LekhoKeyboard/
│   ├── KeyboardViewController.swift
│   ├── Info.plist
│   ├── LekhoKeyboard.entitlements
│   ├── Keyboard/
│   │   ├── KeyboardRootView.swift
│   │   ├── KeyboardLayout.swift
│   │   ├── KeyboardKey.swift
│   │   ├── KeyAction.swift
│   │   ├── KeyKind.swift
│   │   ├── SuggestionBarView.swift
│   │   └── Theme.swift
│   └── Input/
│       ├── InputSession.swift
│       ├── KeyRouter.swift
│       └── BengaliDigitInput.swift
├── SharedKit/
│   ├── AppGroup.swift
│   ├── DataPaths.swift
│   ├── Layout.swift
│   ├── TypingMode.swift
│   ├── Suggestion.swift
│   └── Transliteration/
│       ├── LekhoEngine.swift
│       └── RitiEngine.swift
├── RitiFFI.xcframework/    ← generated static Rust library
├── RitiFFI-stub/           ← placeholder C implementation
└── scripts/
    ├── build_xcframework.sh
    ├── build_stub_xcframework.sh
    └── copy_data.sh
```
