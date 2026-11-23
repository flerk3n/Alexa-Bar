"""Entry point the app launches: `python3 -I -B -u run_helper.py`.

Isolated mode (-I) ignores the user's PYTHON* variables and site-packages, so
put this folder and the bundled site-packages on the path explicitly.
"""

import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
for p in (HERE, HERE / "site-packages"):
    if p.is_dir() and str(p) not in sys.path:
        sys.path.insert(0, str(p))

from alexabar_helper.protocol import main  # noqa: E402

main()
