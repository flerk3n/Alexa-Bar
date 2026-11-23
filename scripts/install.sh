#!/bin/zsh
# Installs build/Alexa Bar.app into /Applications (or ~/Applications if
# /Applications isn't writable), replacing a running copy, then opens it.
set -euo pipefail

ROOT=${0:A:h:h}
APP="$ROOT/build/Alexa Bar.app"
[[ -d "$APP" ]] || { echo "Build the app first: scripts/build_app.sh"; exit 1; }

DEST=/Applications
[[ -w "$DEST" ]] || DEST="$HOME/Applications"
mkdir -p "$DEST"

if pgrep -x AlexaBar >/dev/null; then
  osascript -e 'tell application id "com.alexabar.AlexaBar" to quit' 2>/dev/null || pkill -x AlexaBar || true
  for _ in {1..20}; do pgrep -x AlexaBar >/dev/null || break; sleep 0.25; done
  pkill -x AlexaBar 2>/dev/null || true
fi

rm -rf "$DEST/Alexa Bar.app"
ditto "$APP" "$DEST/Alexa Bar.app"
print -P "%F{green}✓%f Installed to $DEST/Alexa Bar.app"
open "$DEST/Alexa Bar.app"
