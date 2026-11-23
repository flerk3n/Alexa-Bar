"""Where the helper keeps its data.

The app passes its Application Support folder in ALEXABAR_DATA_DIR. Older
builds and the CLI prototype used ~/.alexa-menubar; a saved session found
there is copied over once so existing users stay signed in.
"""

from __future__ import annotations

import os
import shutil
from pathlib import Path

LEGACY_DIR = Path.home() / ".alexa-menubar"
DATA_DIR = Path(
    os.environ.get("ALEXABAR_DATA_DIR")
    or Path.home() / "Library" / "Application Support" / "Alexa Bar"
)
STATE_FILE = DATA_DIR / "state.json"
STORAGE_DIR = DATA_DIR / ".storage"


def ensure_dirs() -> None:
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    STORAGE_DIR.mkdir(parents=True, exist_ok=True)
    os.chmod(DATA_DIR, 0o700)


def migrate_legacy() -> bool:
    """Copy a session from ~/.alexa-menubar if we have none yet."""
    old_state = LEGACY_DIR / "state.json"
    if STATE_FILE.exists() or not old_state.exists():
        return False
    ensure_dirs()
    shutil.copy2(old_state, STATE_FILE)
    os.chmod(STATE_FILE, 0o600)
    old_storage = LEGACY_DIR / ".storage"
    if old_storage.is_dir():
        for f in old_storage.iterdir():
            if f.is_file():
                shutil.copy2(f, STORAGE_DIR / f.name)
    return True
