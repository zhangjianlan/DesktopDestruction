#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

TARGET="${1:-native}"
DEFAULT_SIGNING_IDENTITY="$(security find-identity -v -p codesigning | sed -n 's/^.*"\(.*\)"$/\1/p' | head -n 1)"
SIGNING_IDENTITY="${DD_CODESIGN_IDENTITY:-${DEFAULT_SIGNING_IDENTITY:--}}"
ARTIFACT_ZIP=""
case "$TARGET" in
  arm64)
    BUILD_ROOT=".build/arm64-app"
    BIN_DIR="$BUILD_ROOT/out/Products/Release"
    APP_DIR="build/DesktopDestruction-Apple-Silicon.app"
    ARTIFACT_ZIP="artifacts/DesktopDestruction-Apple-Silicon.zip"
    swift build -c release --arch arm64 --build-path "$BUILD_ROOT"
    ;;
  x86_64)
    BUILD_ROOT=".build/x86_64-app"
    BIN_DIR="$BUILD_ROOT/out/Products/Release"
    APP_DIR="build/DesktopDestruction-Intel-x86_64.app"
    ARTIFACT_ZIP="artifacts/DesktopDestruction-Intel-x86_64.zip"
    swift build -c release --arch x86_64 --build-path "$BUILD_ROOT"
    ;;
  universal)
    BUILD_ROOT=".build/universal-app"
    BIN_DIR="$BUILD_ROOT/out/Products/Release"
    APP_DIR="build/DesktopDestruction-Universal.app"
    swift build -c release --arch arm64 --arch x86_64 --build-path "$BUILD_ROOT"
    ;;
  native)
    BIN_DIR=".build/release"
    APP_DIR="build/DesktopDestruction.app"
    swift build -c release
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
trap 'rm -rf "$STAGING_ROOT"; if [[ -n "$VERIFY_DIR" ]]; then rm -rf "$VERIFY_DIR"; fi' EXIT

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
  <key>CFBundleShortVersionString</key><string>1.5.0</string>
  <key>CFBundleVersion</key><string>7</string>
  <key>LSMinimumSystemVersion</key><string>14.0</string>
  <key>LSUIElement</key><true/>
  <key>NSPrincipalClass</key><string>NSApplication</string>
  <key>NSScreenCaptureUsageDescription</key><string>仅在启用可选桌面截图模式时，用于截取当前桌面作为破坏画板背景。</string>
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

VERIFY_DIR="$(mktemp -d "${TMPDIR:-/tmp}/DesktopDestruction-verify.XXXXXX")"
VERIFY_APP="$VERIFY_DIR/$(basename "$APP_DIR")"
ditto --norsrc --noextattr "$APP_DIR" "$VERIFY_APP"
codesign --verify --deep --strict "$VERIFY_APP"

if [[ -n "$ARTIFACT_ZIP" ]]; then
  mkdir -p "$(dirname "$ARTIFACT_ZIP")"
  ditto -c -k --norsrc --noextattr --keepParent "$VERIFY_APP" "$ARTIFACT_ZIP"
fi

echo "Built $APP_DIR"
if [[ -n "$ARTIFACT_ZIP" ]]; then
  echo "Packaged $ARTIFACT_ZIP"
fi
echo "Signing identity: $SIGNING_IDENTITY"
