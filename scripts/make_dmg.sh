#!/bin/zsh
# Packages build/Alexa Bar.app into build/Alexa-Bar-<version>.dmg with an
# Applications shortcut for drag-to-install.
#
# Optional notarization (needs a Developer ID signed app, see build_app.sh):
#   NOTARY_PROFILE=<keychain profile from `xcrun notarytool store-credentials`>
set -euo pipefail

ROOT=${0:A:h:h}
cd "$ROOT"

APP="$ROOT/build/Alexa Bar.app"
[[ -d "$APP" ]] || { echo "Build the app first: scripts/build_app.sh"; exit 1; }
VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "$APP/Contents/Info.plist")
DMG="$ROOT/build/Alexa-Bar-$VERSION.dmg"
STAGE=$(mktemp -d)

cp -R "$APP" "$STAGE/"
ln -s /Applications "$STAGE/Applications"
rm -f "$DMG"
hdiutil create -quiet -volname "Alexa Bar" -srcfolder "$STAGE" -fs HFS+ -format UDZO \
  -imagekey zlib-level=9 "$DMG"
rm -rf "$STAGE"

SIGNER=$(codesign -dvv "$APP" 2>&1 | sed -n 's/^Authority=//p' | head -1)
if [[ -n "$SIGNER" ]]; then
  codesign --force --sign "$SIGNER" --timestamp "$DMG"
fi

if [[ -n "${NOTARY_PROFILE:-}" ]]; then
  echo "Submitting for notarization…"
  xcrun notarytool submit "$DMG" --keychain-profile "$NOTARY_PROFILE" --wait
  xcrun stapler staple "$DMG"
fi

print -P "%F{green}✓%f $DMG ($(du -h "$DMG" | awk '{print $1}'))"
