#!/usr/bin/env python3
"""Resize the shared model render into native and web icons (macOS)."""
from pathlib import Path
import subprocess
root = Path(__file__).resolve().parents[1]
source = root / 'assets/gurney-journey-icon.png'
for size, destination in [
    (1024, 'ios/Gurney/Assets.xcassets/AppIcon.appiconset/AppIcon.png'),
    (180, 'assets/apple-touch-icon.png'),
    (64, 'assets/favicon.png'),
]:
    subprocess.run(['sips', '-z', str(size), str(size), str(source), '--out', str(root / destination)], check=True)
