#!/usr/bin/env python3
"""Catppuccin Macchiato for Zed. Run by `./install.sh ide`; safe to re-run.

Zed installs the extensions itself on next start (auto_install_extensions),
then picks the theme/icon theme below. Keys are merged into
~/.config/zed/settings.json; if that file has comments (JSONC) it's left
untouched and the snippet is printed instead, so nothing of yours is lost.
"""
import json
import shutil
import sys
from pathlib import Path

FILE = Path.home() / ".config/zed/settings.json"
WANT = {
    "auto_install_extensions": {"catppuccin": True, "catppuccin-icons": True},
    "theme": {"mode": "dark", "dark": "Catppuccin Macchiato", "light": "Catppuccin Latte"},
    "icon_theme": {"mode": "dark", "dark": "Catppuccin Macchiato", "light": "Catppuccin Latte"},
}


def merge(dst, src):
    for k, v in src.items():
        if isinstance(v, dict) and isinstance(dst.get(k), dict):
            merge(dst[k], v)
        else:
            dst[k] = v


def main():
    if not shutil.which("zeditor") and not shutil.which("zed"):
        print("!! Zed not installed — skipping")
        return 0
    cur = {}
    if FILE.exists() and FILE.read_text().strip():
        try:
            cur = json.loads(FILE.read_text())
        except ValueError:
            print(f"!! {FILE} has comments/trailing commas — add this yourself:")
            print(json.dumps(WANT, indent=2))
            return 0
    new = json.loads(json.dumps(cur))
    merge(new, WANT)
    if new == cur:
        print("==> Zed: already Catppuccin Macchiato")
        return 0
    FILE.parent.mkdir(parents=True, exist_ok=True)
    FILE.write_text(json.dumps(new, indent=2) + "\n")
    print("==> Zed: Catppuccin Macchiato set (extensions install on next start)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
