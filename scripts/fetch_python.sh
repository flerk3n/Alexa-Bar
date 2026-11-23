#!/bin/zsh
# Downloads the pinned standalone CPython (python-build-standalone), verifies
# its SHA-256 and unpacks it into build/cache. Prints the unpacked folder.
set -euo pipefail

ROOT=${0:A:h:h}
RELEASE="20261110"
PY_VERSION="3.12.16"
ARCH="aarch64"
SHA256="2f11b8aa3726bdbd87dd9eb76568412faddf4f47e26913fa45d6a2e424972acd"

NAME="cpython-${PY_VERSION}+${RELEASE}-${ARCH}-apple-darwin-install_only_stripped.tar.gz"
URL="https://github.com/astral-sh/python-build-standalone/releases/download/${RELEASE}/${NAME//+/%2B}"
CACHE="$ROOT/build/cache"
ARCHIVE="$CACHE/$NAME"
DEST="$CACHE/python-${PY_VERSION}-${RELEASE}-${ARCH}"

mkdir -p "$CACHE"

if [[ ! -x "$DEST/python/bin/python3" ]]; then
  if [[ ! -f "$ARCHIVE" ]]; then
    echo "Downloading Python $PY_VERSION ($ARCH)…" >&2
    curl -fL --retry 3 --progress-bar -o "$ARCHIVE.part" "$URL" >&2
    mv "$ARCHIVE.part" "$ARCHIVE"
  fi
  actual=$(shasum -a 256 "$ARCHIVE" | awk '{print $1}')
  if [[ "$actual" != "$SHA256" ]]; then
    echo "Checksum mismatch for $NAME" >&2
    echo "  expected $SHA256" >&2
    echo "  got      $actual" >&2
    rm -f "$ARCHIVE"
    exit 1
  fi
  rm -rf "$DEST"
  mkdir -p "$DEST"
  tar -xzf "$ARCHIVE" -C "$DEST"
fi

echo "$DEST/python"
