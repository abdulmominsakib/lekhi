# Testing

## Build

```bash
# 1. Generate the placeholder XCFramework (C stub)
bash scripts/build_stub_xcframework.sh

# 2. Build the project for the simulator
xcodebuild \
  -project LekhoiOS.xcodeproj \
  -scheme LekhoiOS \
  -destination 'generic/platform=iOS Simulator' \
  -configuration Debug \
  CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO \
  build
```

Expected: `** BUILD SUCCEEDED **`. The output app lands in
`~/Library/Developer/Xcode/DerivedData/...`. Copy it into the
working tree for `simctl`:

```bash
APP_SRC=$(find ~/Library/Developer/Xcode/DerivedData/LekhoiOS-* \
  -name "LekhoiOS.app" -path "*Debug-iphonesimulator*" | head -1)
mkdir -p build
cp -R "$APP_SRC" build/
```

## Install + run

```bash
xcrun simctl boot "iPhone 17 Pro"
xcrun simctl uninstall "iPhone 17 Pro" com.lekho.ios.app
xcrun simctl install "iPhone 17 Pro" build/LekhoiOS.app
xcrun simctl launch "iPhone 17 Pro" com.lekho.ios.app
```

## Functional checklist

### Host app

- [ ] **Onboarding** appears on first launch
- [ ] Tapping **Next** advances through 3 screens
- [ ] **Start Typing Bangla** button goes to the Home tab
- [ ] Home tab shows enable-status card and quick examples
- [ ] **Settings** tab renders mode picker and layout picker
- [ ] Toggling a setting persists across app restarts
- [ ] **About** tab shows credits and version
- [ ] **Keyboard preview** renders the SwiftUI keyboard inline

### Keyboard extension

Enable the keyboard in Settings:

1. **Settings → General → Keyboard → Keyboards → Add New
   Keyboard → Lekho** (under "Third-Party Keyboards").
2. In any app (e.g. Notes), tap and hold the 🌐 globe key and
   pick Lekho.

Now verify:

- [ ] **QWERTY layout** matches the design — rounded white keys,
      blue Return key with arrow, globe + 123 + space row.
- [ ] **Suggestion bar** appears with three equal cards above the
      keyboard.
- [ ] Typing `ami` shows candidates `আমি`, `আমিও`, etc.
- [ ] Tapping the second card commits that candidate.
- [ ] Typing `bangla` shows `বাংলা`, `বাঙালি`, `বাংলাদেশ`.
- [ ] Typing a punctuation like `.bd` produces `.বিডি` via
      autocorrect.
- [ ] Typing `0` outside a session inserts `০` (Bengali digit).
- [ ] Backspace mid-word restores the previous suggestion.
- [ ] Space commits the top candidate, then inserts a space.
- [ ] Return commits the top candidate, then inserts a newline.
- [ ] Globe key cycles to the next installed keyboard.
- [ ] Switching to **Phonetic Only** mode in Settings hides the
      suggestion bar and types inline only.

### Performance / stability

- Memory Graph in Xcode shows the keyboard extension steady-state
  under ~35 MB after a few minutes of typing.
- Airplane Mode → still works (fully offline).
- 5-minute typing session produces no Jetsam crash reports in
  `~/Library/Logs/DiagnosticReports/`.

## Debugging

### Logs

```bash
xcrun simctl spawn "iPhone 17 Pro" log show \
  --predicate 'process == "LekhoiOS" OR process == "LekhoKeyboard"' \
  --last 5m
```

### Crash reports

```bash
ls -t ~/Library/Logs/DiagnosticReports/ | grep -i lekho | head -5
```

### Inspect the app bundle

```bash
ls build/LekhoiOS.app/PlugIns/LekhoKeyboard.appex/
find build/LekhoiOS.app -name 'RitiFFI.framework' # should print nothing; it is linked statically
```

## Reverting to a clean state

```bash
xcrun simctl uninstall "iPhone 17 Pro" com.lekho.ios.app
rm -rf build/
xcodebuild -project LekhoiOS.xcodeproj -scheme LekhoiOS clean
```
