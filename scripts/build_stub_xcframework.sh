#!/usr/bin/env bash
#
# Build the placeholder `RitiFFI.xcframework` from the local C stub.
# This lets the iOS Xcode project compile before the Rust
# transliteration engine has been built. Replace the framework
# with the real one via `scripts/build_xcframework.sh` once Rust
# is available.
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
STUB_DIR="$ROOT_DIR/RitiFFI-stub"

DEVICE_TARGET="aarch64-apple-ios"
SIM_TARGET="aarch64-apple-ios-simulator"
OUTPUT="$ROOT_DIR/RitiFFI.xcframework"

# Sanity check the toolchain
for t in "$DEVICE_TARGET" "$SIM_TARGET"; do
    if ! xcrun --sdk $([[ "$t" == *simulator* ]] && echo iphonesimulator || echo iphoneos) --show-sdk-path >/dev/null 2>&1; then
        echo "Missing SDK for $t" >&2
        exit 1
    fi
done

BUILD="$ROOT_DIR/build"
rm -rf "$BUILD" "$OUTPUT"

# --- Device slice ---
DEVICE_OUT="$BUILD/ios-arm64"
mkdir -p "$DEVICE_OUT/RitiFFI.framework/Headers" "$DEVICE_OUT/RitiFFI.framework/Modules"

xcrun --sdk iphoneos clang \
    -arch arm64 \
    -dynamiclib \
    -install_name @rpath/RitiFFI.framework/RitiFFI \
    -iframework "$(xcrun --sdk iphoneos --show-sdk-path)/System/Library/Frameworks" \
    -I"$STUB_DIR/include" \
    -o "$DEVICE_OUT/RitiFFI.framework/RitiFFI" \
    "$STUB_DIR/src/riti_stub.c"

cp "$STUB_DIR/include/riti.h" "$STUB_DIR/include/avrobangla_engine.h" \
   "$DEVICE_OUT/RitiFFI.framework/Headers/"

cp "$STUB_DIR/Info.plist" "$DEVICE_OUT/RitiFFI.framework/Info.plist"

cat > "$DEVICE_OUT/RitiFFI.framework/Modules/module.modulemap" <<'EOF'
framework module RitiFFI {
    umbrella header "avrobangla_engine.h"
    header "riti.h"
    export *
    link "c"
}
EOF

# --- Simulator slice (Apple Silicon + Intel) ---
SIM_OUT="$BUILD/ios-arm64-sim"
mkdir -p "$SIM_OUT/RitiFFI.framework/Headers" "$SIM_OUT/RitiFFI.framework/Modules"

# Build a single fat framework with arm64 + x86_64 simulator slices
xcrun --sdk iphonesimulator clang \
    -arch arm64 -arch x86_64 \
    -dynamiclib \
    -install_name @rpath/RitiFFI.framework/RitiFFI \
    -I"$STUB_DIR/include" \
    -o "$SIM_OUT/RitiFFI.framework/RitiFFI" \
    "$STUB_DIR/src/riti_stub.c"

cp "$STUB_DIR/include/riti.h" "$STUB_DIR/include/avrobangla_engine.h" \
   "$SIM_OUT/RitiFFI.framework/Headers/"

cp "$STUB_DIR/Info.plist" "$SIM_OUT/RitiFFI.framework/Info.plist"

cat > "$SIM_OUT/RitiFFI.framework/Modules/module.modulemap" <<'EOF'
framework module RitiFFI {
    umbrella header "avrobangla_engine.h"
    header "riti.h"
    export *
    link "c"
}
EOF

xcodebuild -create-xcframework \
    -framework "$DEVICE_OUT/RitiFFI.framework" \
    -framework "$SIM_OUT/RitiFFI.framework" \
    -output "$OUTPUT"

echo "✅ Built stub $OUTPUT"
