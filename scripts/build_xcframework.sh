#!/usr/bin/env bash
#
# Build the iOS XCFramework wrapper around OpenBangla's `riti`
# transliteration engine. Outputs `RitiFFI.xcframework` at the
# project root for both iOS Device and iOS Simulator (arm64 + x86_64).
#
# Prerequisites:
#   * Rust toolchain (rustup)
#   * rustup target add aarch64-apple-ios aarch64-apple-ios-sim x86_64-apple-ios
#   * Xcode command line tools (for `xcodebuild -create-xcframework` & `lipo`)
#
# Usage:
#   bash scripts/build_xcframework.sh
#

set -euo pipefail

# Resolve paths relative to this script.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ENGINE_DIR="$(cd "$ROOT_DIR/../Lekho/engine" && pwd)"

BUILD_TYPE="${BUILD_TYPE:-release}"
FRAMEWORK_NAME="RitiFFI"
BUILD_DIR="$ROOT_DIR/build"
OUTPUT_XCFRAMEWORK="$ROOT_DIR/$FRAMEWORK_NAME.xcframework"

TARGET_DEVICE="aarch64-apple-ios"
TARGET_SIM_ARM="aarch64-apple-ios-sim"
TARGET_SIM_X86="x86_64-apple-ios"

echo "==> Ensuring Rust targets are installed..."
for t in "$TARGET_DEVICE" "$TARGET_SIM_ARM" "$TARGET_SIM_X86"; do
    if ! rustup target list --installed | grep -q "$t"; then
        echo "==> Installing Rust target $t"
        rustup target add "$t"
    fi
done

# ----- 1. cargo build for all targets -----
echo "==> Building $FRAMEWORK_NAME ($BUILD_TYPE) in $ENGINE_DIR"
cd "$ENGINE_DIR"

RUSTFLAGS="-C strip=symbols" cargo build --$BUILD_TYPE --target "$TARGET_DEVICE" -p avrobangla-engine
RUSTFLAGS="-C strip=symbols" cargo build --$BUILD_TYPE --target "$TARGET_SIM_ARM" -p avrobangla-engine
RUSTFLAGS="-C strip=symbols" cargo build --$BUILD_TYPE --target "$TARGET_SIM_X86" -p avrobangla-engine

# ----- 2. Stage device & simulator framework folders -----
DEVICE_STAGE="$BUILD_DIR/ios-arm64/$FRAMEWORK_NAME.framework"
SIM_STAGE="$BUILD_DIR/ios-arm64_x86_64-simulator/$FRAMEWORK_NAME.framework"

rm -rf "$BUILD_DIR/ios-arm64" "$BUILD_DIR/ios-arm64_x86_64-simulator" "$OUTPUT_XCFRAMEWORK"
mkdir -p "$DEVICE_STAGE/Headers" "$DEVICE_STAGE/Modules"
mkdir -p "$SIM_STAGE/Headers" "$SIM_STAGE/Modules"

# Copy device static library
cp "target/$TARGET_DEVICE/$BUILD_TYPE/libavrobangla_engine.a" "$DEVICE_STAGE/$FRAMEWORK_NAME"

# Create universal simulator fat static library
lipo -create \
  "target/$TARGET_SIM_ARM/$BUILD_TYPE/libavrobangla_engine.a" \
  "target/$TARGET_SIM_X86/$BUILD_TYPE/libavrobangla_engine.a" \
  -output "$SIM_STAGE/$FRAMEWORK_NAME"

# Copy headers, Info.plist, and modulemap to both slices
for stage in "$DEVICE_STAGE" "$SIM_STAGE"; do
    cp "include/riti.h" "include/avrobangla_engine.h" "$stage/Headers/"
    cp "$ROOT_DIR/RitiFFI-stub/Info.plist" "$stage/Info.plist"
    cat > "$stage/Modules/module.modulemap" << 'EOF'
framework module RitiFFI {
    umbrella header "avrobangla_engine.h"
    header "riti.h"
    export *
    link "c"
}
EOF
done

# ----- 3. Create XCFramework -----
echo "==> Creating $OUTPUT_XCFRAMEWORK"
xcodebuild -create-xcframework \
  -framework "$DEVICE_STAGE" \
  -framework "$SIM_STAGE" \
  -output "$OUTPUT_XCFRAMEWORK"

echo
echo "✅ Built $OUTPUT_XCFRAMEWORK"
ls -la "$OUTPUT_XCFRAMEWORK"

