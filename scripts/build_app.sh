#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

# macOS file providers can attach Finder/FileProvider metadata to generated
# resources. Clear it at the source before SwiftPM copies and signs the bundle.
if command -v xattr >/dev/null 2>&1; then
  xattr -cr Sources/DesktopDestruction/Resources
fi

TARGET="${1:-native}"
DEFAULT_SIGNING_IDENTITY="$(security find-identity -v -p codesigning | sed -n 's/^.*"\(.*\)"$/\1/p' | head -n 1)"
SIGNING_IDENTITY="${DD_CODESIGN_IDENTITY:-${DEFAULT_SIGNING_IDENTITY:--}}"
APP_OUTPUT_ROOT="${DD_APP_OUTPUT_ROOT:-/Users/Shared/DesktopDestruction}"
BUILD_SCRATCH_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/DesktopDestruction-scratch.XXXXXX")"
ARTIFACT_ZIP=""
case "$TARGET" in
  arm64)
    BUILD_ROOT="$BUILD_SCRATCH_ROOT/arm64"
    BIN_DIR="$BUILD_ROOT/out/Products/Release"
    APP_DIR="$APP_OUTPUT_ROOT/DesktopDestruction-Apple-Silicon.app"
    ARTIFACT_ZIP="artifacts/DesktopDestruction-Apple-Silicon.zip"
    swift build -c release --arch arm64 --build-path "$BUILD_ROOT"
    ;;
  x86_64)
    BUILD_ROOT="$BUILD_SCRATCH_ROOT/x86_64"
    BIN_DIR="$BUILD_ROOT/out/Products/Release"
    APP_DIR="$APP_OUTPUT_ROOT/DesktopDestruction-Intel-x86_64.app"
    ARTIFACT_ZIP="artifacts/DesktopDestruction-Intel-x86_64.zip"
    swift build -c release --arch x86_64 --build-path "$BUILD_ROOT"
    ;;
  universal)
    BUILD_ROOT="$BUILD_SCRATCH_ROOT/universal"
    BIN_DIR="$BUILD_ROOT/out/Products/Release"
    APP_DIR="$APP_OUTPUT_ROOT/DesktopDestruction-Universal.app"
    swift build -c release --arch arm64 --arch x86_64 --build-path "$BUILD_ROOT"
    ;;
  native)
    BUILD_ROOT="$BUILD_SCRATCH_ROOT/native"
    BIN_DIR="$BUILD_ROOT/out/Products/Release"
    APP_DIR="$APP_OUTPUT_ROOT/DesktopDestruction.app"
    swift build -c release --build-path "$BUILD_ROOT"
    ;;
  *)
    echo "Usage: $0 [arm64|x86_64|universal|native]" >&2
    exit 2
    ;;
esac

STAGING_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/DesktopDestruction-build.XXXXXX")"
STAGING_APP="$STAGING_ROOT/DesktopDestruction.app"
STAGING_MACOS_DIR="$STAGING_APP/Contents/MacOS"
STAGING_RESOURCES_DIR="$STAGING_APP/Contents/Resources"
VERIFY_DIR=""
mkdir -p "$APP_OUTPUT_ROOT"
trap 'rm -rf "$STAGING_ROOT" "$BUILD_SCRATCH_ROOT"; if [[ -n "$VERIFY_DIR" ]]; then rm -rf "$VERIFY_DIR"; fi' EXIT

mkdir -p "$STAGING_MACOS_DIR" "$STAGING_RESOURCES_DIR"
cp "$BIN_DIR/DesktopDestruction" "$STAGING_MACOS_DIR/DesktopDestruction"
if [ -d "$BIN_DIR/DesktopDestruction_DesktopDestruction.bundle" ]; then
  cp -R "$BIN_DIR/DesktopDestruction_DesktopDestruction.bundle" "$STAGING_RESOURCES_DIR/"
else
  echo "Missing SwiftPM resource bundle" >&2
  exit 1
fi

cat > "$STAGING_APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key><string>zh_CN</string>
  <key>CFBundleExecutable</key><string>DesktopDestruction</string>
  <key>CFBundleIdentifier</key><string>com.codex.desktopdestruction</string>
  <key>CFBundleName</key><string>DesktopDestruction</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>1.6.6</string>
  <key>CFBundleVersion</key><string>14</string>
  <key>LSMinimumSystemVersion</key><string>14.0</string>
  <key>LSUIElement</key><true/>
  <key>NSPrincipalClass</key><string>NSApplication</string>
  <key>NSScreenCaptureUsageDescription</key><string>截取当前桌面作为破坏画板背景；所有破坏效果只发生在内存画面中，不会修改真实文件。</string>
</dict>
</plist>
PLIST

chmod +x "$STAGING_MACOS_DIR/DesktopDestruction"
xattr -cr "$STAGING_APP"
if [[ "$SIGNING_IDENTITY" == "-" ]]; then
  echo "Warning: no stable codesigning identity found; using ad-hoc signing." >&2
fi
codesign --force --sign "$SIGNING_IDENTITY" "$STAGING_APP"
codesign --verify --deep --strict "$STAGING_APP"

rm -rf "$APP_DIR"
# Keep the embedded signature intact when copying out of /tmp into a directory
# managed by File Provider.
ditto --norsrc --noextattr "$STAGING_APP" "$APP_DIR"

# File Provider can attach Finder and provenance metadata while copying back
# into the repository. Strip every extended attribute before final validation.
xattr -cr "$APP_DIR"

VERIFY_DIR="$(mktemp -d "${TMPDIR:-/tmp}/DesktopDestruction-verify.XXXXXX")"
VERIFY_APP="$VERIFY_DIR/$(basename "$APP_DIR")"
ditto --norsrc --noextattr "$APP_DIR" "$VERIFY_APP"
for metadata_attr in "com.apple.FinderInfo" "com.apple.fileprovider.fpfs#P"; do
    if xattr -p "$metadata_attr" "$VERIFY_APP" >/dev/null 2>&1; then
        xattr -d "$metadata_attr" "$VERIFY_APP"
    fi
done
codesign --verify --deep --strict "$VERIFY_APP"
codesign --verify --deep --strict "$APP_DIR"

if [[ -n "$ARTIFACT_ZIP" ]]; then
  mkdir -p "$(dirname "$ARTIFACT_ZIP")"
  ditto -c -k --norsrc --noextattr --keepParent "$VERIFY_APP" "$ARTIFACT_ZIP"
fi

echo "Built $APP_DIR"
if [[ -n "$ARTIFACT_ZIP" ]]; then
  echo "Packaged $ARTIFACT_ZIP"
fi
echo "Signing identity: $SIGNING_IDENTITY"
