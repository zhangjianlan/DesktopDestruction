#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SOURCE_APP="${1:-build/DesktopDestruction.app}"
DESTINATION_APP="${2:-$HOME/Applications/DesktopDestruction.app}"

if [[ ! -d "$SOURCE_APP/Contents/MacOS" ]]; then
  echo "Source app not found or invalid: $SOURCE_APP" >&2
  exit 1
fi

if [[ "$DESTINATION_APP" != *.app || "$DESTINATION_APP" == "/" || "$DESTINATION_APP" == "/Applications" ]]; then
  echo "Destination must be a complete .app path, not a directory." >&2
  echo "Usage: $0 SOURCE.app DESTINATION.app" >&2
  exit 1
fi

DESTINATION_DIR="$(dirname "$DESTINATION_APP")"
mkdir -p "$DESTINATION_DIR"

STAGING_APP="$DESTINATION_APP.staging.$$"
trap 'rm -rf "$STAGING_APP"' EXIT
rm -rf "$STAGING_APP"
ditto --norsrc --noextattr "$SOURCE_APP" "$STAGING_APP"
xattr -cr "$STAGING_APP"
codesign --verify --deep --strict "$STAGING_APP"

rm -rf -- "$DESTINATION_APP"
mv "$STAGING_APP" "$DESTINATION_APP"

echo "Installed $DESTINATION_APP"
echo "Launch with: open '$DESTINATION_APP'"
