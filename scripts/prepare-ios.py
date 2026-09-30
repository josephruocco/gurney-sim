#!/usr/bin/env python3
"""Create an offline page from the canonical game; no network or npm required."""
from pathlib import Path
import re
import shutil
import sys
root = Path(__file__).resolve().parents[1]
destination = Path(sys.argv[1]) if len(sys.argv) > 1 else root / "ios/Gurney/Web"
destination.mkdir(parents=True, exist_ok=True)
page = (root / "index.html").read_text()
page, count = re.subn(r'<script type="importmap">.*?</script>\s*<script type="module">\s*import \* as THREE from \'three\';', '<script src="three.min.js"></script>\n<script>', page, count=1, flags=re.S)
if count != 1:
    raise SystemExit("Game import changed; update the iOS bundling script.")
(destination / "index.html").write_text(page)
for name in ("three.min.js", "THREE-LICENSE.txt"):
    (destination / name).write_bytes((root / "vendor" / name).read_bytes())

shutil.copytree(root / "assets", destination / "assets", dirs_exist_ok=True, ignore=shutil.ignore_patterns("*.md"))
