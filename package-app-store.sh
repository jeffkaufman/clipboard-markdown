#!/bin/bash
# Builds and packages "Clipboard Markdown.app" as a signed .pkg ready to upload
# to App Store Connect.
#
# Before this will work you need, once:
#   1. An Apple Developer Program membership.
#   2. An App ID for the bundle identifier, in the developer portal.
#   3. An "Apple Distribution" certificate and a "Mac Installer Distribution"
#      certificate in your keychain.
#   4. A Mac App Store provisioning profile for the App ID, downloaded.
#   5. An app record in App Store Connect using the same bundle identifier.
#
# Then:
#   SIGN_IDENTITY="Apple Distribution: Your Name (TEAMID)" \
#   INSTALLER_IDENTITY="3rd Party Mac Developer Installer: Your Name (TEAMID)" \
#   PROVISIONING_PROFILE=~/Downloads/Clipboard_Markdown.provisionprofile \
#   BUILD_VERSION=2 \
#     ./package-app-store.sh
#
# `security find-identity -v` lists the identity names you have.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP="$SCRIPT_DIR/Clipboard Markdown.app"
PKG="$SCRIPT_DIR/ClipboardMarkdown.pkg"

for required in SIGN_IDENTITY INSTALLER_IDENTITY PROVISIONING_PROFILE; do
    if [ -z "${!required:-}" ]; then
        echo "Error: $required is not set.  See the comments in $0." >&2
        exit 1
    fi
done

export SIGN_IDENTITY PROVISIONING_PROFILE
"$SCRIPT_DIR/build-app.sh"

echo ""
echo "Building installer package..."
rm -f "$PKG"
productbuild --component "$APP" /Applications \
    --sign "$INSTALLER_IDENTITY" \
    "$PKG"

echo ""
echo "Built $PKG"
echo ""
echo "Upload it with either:"
echo "  * Transporter.app (free on the Mac App Store), or"
echo "  * xcrun altool --upload-app -f \"$PKG\" -t macos \\"
echo "        --apiKey <KEY_ID> --apiIssuer <ISSUER_ID>"
echo ""
echo "Then pick the build in App Store Connect and submit for review."
