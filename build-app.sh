#!/bin/bash
# Builds "Clipboard Markdown.app", the native menu bar app in macapp/.
#
# This is the App Store track.  The older Platypus apps built by build-apps.sh
# shell out to pandoc, which cannot be sandboxed or shipped on the App Store
# (pandoc is GPL), so this app does the conversions itself in Swift.
#
# Environment:
#   SIGN_IDENTITY   codesign identity.  Defaults to ad-hoc ("-"), which is fine
#                   for running locally.  For the App Store, use your
#                   "Apple Distribution: ..." identity.  For a notarized
#                   download outside the store, use "Developer ID Application: ...".
#   APP_NAME        bundle name, defaults to "Clipboard Markdown".  Set it
#                   together with BUNDLE_ID to build a variant that installs
#                   alongside the release app instead of replacing it.
#   BUNDLE_ID       defaults to com.jefftk.ClipboardMarkdown
#   SHORT_VERSION   marketing version, defaults to 1.0
#   BUILD_VERSION   build number, must increase with every App Store upload
#   ICON            source PNG for the app and menu bar icons
#   PROVISIONING_PROFILE
#                   .provisionprofile to embed (App Store builds)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_DIR="$SCRIPT_DIR/macapp"
APP_NAME="${APP_NAME:-Clipboard Markdown}"
APP="$SCRIPT_DIR/$APP_NAME.app"
# The executable is named after the app, so two variants are told apart in
# Activity Monitor, in crash reports, and by killall.
EXECUTABLE="$(echo "$APP_NAME" | tr -cd '[:alnum:]')"

SIGN_IDENTITY="${SIGN_IDENTITY:--}"
BUNDLE_ID="${BUNDLE_ID:-com.jefftk.ClipboardMarkdown}"
SHORT_VERSION="${SHORT_VERSION:-1.0}"
BUILD_VERSION="${BUILD_VERSION:-1}"
COPYRIGHT="${COPYRIGHT:-Copyright © $(date +%Y) Jeff Kaufman. MIT licensed.}"
ICON="${ICON:-$SCRIPT_DIR/logos/clipboard-md.png}"

# Universal, so one upload covers Apple Silicon and Intel.
ARCHS=(--arch arm64 --arch x86_64)

echo "Building $APP_NAME (release, universal)..."
swift build --package-path "$PACKAGE_DIR" -c release "${ARCHS[@]}"
BIN_DIR="$(swift build --package-path "$PACKAGE_DIR" -c release "${ARCHS[@]}" --show-bin-path)"

echo "Assembling $(basename "$APP")..."
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

cp "$BIN_DIR/ClipboardMarkdown" "$APP/Contents/MacOS/$EXECUTABLE"

sed -e "s|@APP_NAME@|$APP_NAME|" \
    -e "s|@EXECUTABLE@|$EXECUTABLE|" \
    -e "s|@BUNDLE_ID@|$BUNDLE_ID|" \
    -e "s|@SHORT_VERSION@|$SHORT_VERSION|" \
    -e "s|@BUILD_VERSION@|$BUILD_VERSION|" \
    -e "s|@COPYRIGHT@|$COPYRIGHT|" \
    "$PACKAGE_DIR/Resources/Info.plist" > "$APP/Contents/Info.plist"

# Icons.  The source art is not quite square, so pad rather than squash it.
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
SIDE="$(sips -g pixelWidth -g pixelHeight "$ICON" | awk '/pixel/ {print $2}' | sort -rn | head -1)"
sips --padToHeightWidth "$SIDE" "$SIDE" "$ICON" --out "$WORK/square.png" >/dev/null

mkdir -p "$WORK/AppIcon.iconset"
for size in 16 32 128 256 512; do
    sips -z $size $size "$WORK/square.png" \
        --out "$WORK/AppIcon.iconset/icon_${size}x${size}.png" >/dev/null
    sips -z $((size * 2)) $((size * 2)) "$WORK/square.png" \
        --out "$WORK/AppIcon.iconset/icon_${size}x${size}@2x.png" >/dev/null
done
iconutil -c icns "$WORK/AppIcon.iconset" -o "$APP/Contents/Resources/AppIcon.icns"

# Rendered at 18pt; 72px keeps it sharp on Retina.
sips -z 72 72 "$WORK/square.png" \
    --out "$APP/Contents/Resources/MenuBarIcon.png" >/dev/null

# App Store builds carry a provisioning profile, which must be in place
# before signing.
if [ -n "${PROVISIONING_PROFILE:-}" ]; then
    echo "Embedding $(basename "$PROVISIONING_PROFILE")"
    cp "$PROVISIONING_PROFILE" "$APP/Contents/embedded.provisionprofile"
fi

echo "Signing with identity: $SIGN_IDENTITY"
SIGN_ARGS=(--force --sign "$SIGN_IDENTITY"
           --entitlements "$PACKAGE_DIR/Resources/ClipboardMarkdown.entitlements"
           --options runtime)
if [ "$SIGN_IDENTITY" = "-" ]; then
    # Ad-hoc signatures cannot be timestamped.
    SIGN_ARGS+=(--timestamp=none)
else
    SIGN_ARGS+=(--timestamp)
fi
codesign "${SIGN_ARGS[@]}" "$APP"

codesign --verify --strict --verbose=2 "$APP"

echo ""
echo "Built $APP"
