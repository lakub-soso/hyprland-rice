#!/usr/bin/env python3
"""Catppuccin Macchiato for VS Code, merged into the existing (Settings-Sync'd)
setup. Run by `./install.sh ide`; safe to re-run.

  1. installs the official extension if missing:
       Catppuccin.catppuccin-vsc        (colour themes)
  2. sets only these keys in ~/.config/Code/User/settings.json:
       workbench.colorTheme   = "Catppuccin Macchiato"
       catppuccin.accentColor = "mauve"
     as a text edit — VS Code's settings.json is JSONC (comments, trailing
     commas), so it's never re-serialised: every other byte stays as it was.
The file-icon theme is deliberately left alone (your own choice, synced).
Settings Sync then carries the change to your other machines.
"""
import json
import re
import shutil
import subprocess
import sys
from pathlib import Path

EXTENSIONS = ["Catppuccin.catppuccin-vsc"]
SETTINGS = {
    "workbench.colorTheme": "Catppuccin Macchiato",
    "catppuccin.accentColor": "mauve",
}
FILE = Path.home() / ".config/Code/User/settings.json"


def set_key(text, key, value):
    """Replace "key": <string> in place, or insert it after the opening brace."""
    val = json.dumps(value)
    pat = re.compile(r'("' + re.escape(key) + r'"\s*:\s*)"(?:[^"\\]|\\.)*"')
    if pat.search(text):
        return pat.sub(lambda m: m.group(1) + val, text, count=1)
    m = re.search(r"\{[ \t]*\r?\n?", text)
    if not m:                                   # empty / odd file
        return "{\n    " + f'"{key}": {val}\n' + "}\n"
    indent = re.search(r"\n([ \t]+)\"", text)
    ind = indent.group(1) if indent else "    "
    nl = "\r\n" if "\r\n" in text else "\n"
    return text[:m.end()] + f'{ind}"{key}": {val},{nl}' + text[m.end():]


def main():
    code = shutil.which("code")
    if not code:
        print("!! VS Code (code) not installed — skipping")
        return 0
    installed = {e.lower() for e in subprocess.run([code, "--list-extensions"],
                                                   capture_output=True, text=True).stdout.split()}
    for ext in EXTENSIONS:
        if ext.lower() not in installed:
            print(f"==> VS Code: installing {ext}")
            subprocess.run([code, "--install-extension", ext], capture_output=True, text=True)
    FILE.parent.mkdir(parents=True, exist_ok=True)
    # newline="" keeps the file's own line endings (Settings Sync from Windows
    # → CRLF); without it every line would show as changed
    text = FILE.read_text(newline="") if FILE.exists() else "{\n}\n"
    new = text
    for k, v in SETTINGS.items():
        new = set_key(new, k, v)
    if new != text:
        FILE.write_text(new, newline="")
        print("==> VS Code: Catppuccin Macchiato set in settings.json")
    else:
        print("==> VS Code: already Catppuccin Macchiato")
    return 0


if __name__ == "__main__":
    sys.exit(main())
