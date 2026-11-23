#!/bin/zsh
# Builds a self-contained "Alexa Bar.app" into build/.
#
# Environment:
#   VERSION        marketing version (default 1.0.0)
#   BUNDLE_ID      bundle identifier (default com.alexabar.AlexaBar)
#   SIGN_IDENTITY  codesign identity, e.g. "Developer ID Application: Name (TEAMID)".
#                  Defaults to "-" (ad hoc), which runs on this Mac but not
#                  through Gatekeeper on other Macs.
set -euo pipefail
setopt null_glob

ROOT=${0:A:h:h}
cd "$ROOT"

VERSION=${VERSION:-1.0.0}
BUNDLE_ID=${BUNDLE_ID:-com.alexabar.AlexaBar}
SIGN_IDENTITY=${SIGN_IDENTITY:--}
BUILD_NUMBER=$(git rev-list --count HEAD 2>/dev/null || echo 1)

APP="$ROOT/build/Alexa Bar.app"
CONTENTS="$APP/Contents"
HELPER="$CONTENTS/Resources/helper"

step() { print -P "%F{cyan}▸%f $1"; }
# codesign, minus its "replacing existing signature" chatter
sign() {
  codesign "$@" 2>&1 | { grep -v "replacing existing signature" || true; }
  return ${pipestatus[1]}
}

# ---------------------------------------------------------------- compile
step "Compiling Swift (release)"
swift build -c release --product AlexaBar 2>&1 | grep -vE "ld: warning: search path|^\[ *[0-9]+ */ *[0-9]+\]" || true
BIN="$(swift build -c release --show-bin-path)/AlexaBar"
[[ -x "$BIN" ]] || { echo "Swift build failed"; exit 1; }

# ---------------------------------------------------------------- bundle
step "Assembling bundle"
rm -rf "$APP"
mkdir -p "$CONTENTS/MacOS" "$CONTENTS/Resources" "$HELPER"
cp "$BIN" "$CONTENTS/MacOS/AlexaBar"
sed -e "s/__BUNDLE_ID__/$BUNDLE_ID/" -e "s/__VERSION__/$VERSION/" -e "s/__BUILD__/$BUILD_NUMBER/" \
  Packaging/Info.plist > "$CONTENTS/Info.plist"
plutil -lint -s "$CONTENTS/Info.plist"

step "Rendering icon"
ICONSET="$ROOT/build/AppIcon.iconset"
rm -rf "$ICONSET"
swift scripts/make_icon.swift "$ICONSET" >/dev/null
iconutil -c icns "$ICONSET" -o "$CONTENTS/Resources/AppIcon.icns"
rm -rf "$ICONSET"

# ---------------------------------------------------------------- python
step "Bundling Python runtime"
PY_SRC=$(scripts/fetch_python.sh)
cp -R "$PY_SRC" "$HELPER/python"
PY="$HELPER/python"
PYLIB="$PY/lib/python3.12"
# Drop what the helper never uses: GUI toolkits, tests, IDLE, headers, docs.
rm -rf "$PYLIB"/{test,idlelib,tkinter,turtledemo,lib2to3,pydoc_data,ensurepip} \
       "$PYLIB"/config-3.12-darwin "$PY"/include "$PY"/share "$PY"/lib/pkgconfig \
       "$PY"/lib/{itcl*,tcl*,tk*,thread*} "$PY"/lib/libtcl* "$PY"/lib/libtk* \
       "$PYLIB"/lib-dynload/_tkinter*.so
rm -f "$PY"/bin/{idle*,pydoc*,2to3*,python3*-config}

step "Installing AlexaPy into the bundle"
"$PY/bin/python3" -m pip install --quiet --disable-pip-version-check --no-warn-script-location \
  --only-binary=:all: --no-compile --target "$HELPER/site-packages" -r backend/requirements.txt
rm -rf "$HELPER/site-packages/bin" "$PYLIB/site-packages/pip" "$PYLIB"/site-packages/pip-*.dist-info
rm -f "$PY"/bin/pip*
# CLI-only dependencies (authcaptureproxy's and httpx's command-line tools);
# nothing the helper imports needs them.
SP="$HELPER/site-packages"
rm -rf "$SP"/{typer,rich,pygments,markdown_it,mdurl,shellingham} \
       "$SP"/{typer,rich,pygments,Pygments,markdown_it_py,mdurl,shellingham}-*.dist-info

step "Copying helper"
cp backend/run_helper.py "$HELPER/"
rsync -a --exclude "__pycache__" backend/alexabar_helper "$HELPER/"
"$PY/bin/python3" -m compileall -q -j 0 "$PYLIB" "$HELPER/site-packages" "$HELPER/alexabar_helper" >/dev/null || true

# ---------------------------------------------------------------- sanity
step "Checking the bundled helper starts"
TMP=$(mktemp -d)
reply=$(printf '{"id":1,"cmd":"hello"}\n' | \
  env -i HOME="$TMP" ALEXABAR_DATA_DIR="$TMP/data" \
  "$PY/bin/python3" -I -B -u "$HELPER/run_helper.py" 2>"$TMP/err" | grep '"id":1' || true)
if [[ "$reply" != *'"ok":true'* ]]; then
  echo "Bundled helper failed to start:"; cat "$TMP/err"; rm -rf "$TMP"; exit 1
fi
rm -rf "$TMP"

# ---------------------------------------------------------------- sign
step "Signing (${SIGN_IDENTITY/#-/ad hoc})"
SIGN_ARGS=(--force --sign "$SIGN_IDENTITY")
if [[ "$SIGN_IDENTITY" != "-" ]]; then
  SIGN_ARGS+=(--options runtime --timestamp)
fi
# Inner code first: every Mach-O in the helper, then the interpreter, then the app.
find "$HELPER" -type f \( -name "*.so" -o -name "*.dylib" \) -print0 | \
  xargs -0 -n 50 codesign "${SIGN_ARGS[@]}" 2>&1 | { grep -v "replacing existing signature" || true; }
sign "${SIGN_ARGS[@]}" --entitlements Packaging/Python.entitlements "$PY/bin/python3.12"
sign "${SIGN_ARGS[@]}" --entitlements Packaging/AlexaBar.entitlements "$APP"
codesign --verify --strict --deep "$APP"

SIZE=$(du -sh "$APP" | awk '{print $1}')
print -P "%F{green}✓%f Built $APP ($SIZE, version $VERSION build $BUILD_NUMBER)"
