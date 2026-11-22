#!/usr/bin/env python3
"""Inkscape 1.x: Catppuccin GTK theme + Adobe Illustrator shortcut set.
Run by `./install.sh ide`; safe to re-run. Close Inkscape first (it rewrites
preferences.xml on exit).

  theme/gtkTheme, iconTheme   the Catppuccin GTK theme + Papirus-Dark icons
  options/kbshortcuts         Inkscape's bundled adobe-illustrator-cs2.xml key
                              set (V/A selection, P pen, T text, Ctrl+J join…)
Edited as text so the rest of preferences.xml is untouched; original saved
once as preferences.xml.pre-illustrator.
"""
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

PREFS = Path.home() / ".config/inkscape/preferences.xml"
GTK_THEME = os.environ.get("GTK_THEME", "catppuccin-macchiato-mauve-standard+default")
ICONS = "Papirus-Dark"
KEYS = Path("/usr/share/inkscape/keys/adobe-illustrator-cs2.xml")


def set_attr(text, group_id, attr, val):
    """Set attr on <group id="group_id" …> (first one), adding it if absent."""
    m = re.search(r'(<group\s+id="%s")([^>]*?)(/?>)' % re.escape(group_id), text)
    if not m:
        return text, False
    head, attrs, tail = m.groups()
    pat = re.compile(r'(\b%s=")[^"]*(")' % re.escape(attr))
    if pat.search(attrs):
        attrs = pat.sub(lambda x: x.group(1) + val + x.group(2), attrs, count=1)
    else:
        attrs += f'\n     {attr}="{val}"'
    return text[:m.start()] + head + attrs + tail + text[m.end():], True


def main():
    if not shutil.which("inkscape"):
        print("!! Inkscape not installed — skipping")
        return 0
    if not PREFS.exists():
        print("!! no preferences.xml (start Inkscape once) — skipping")
        return 0
    if subprocess.run(["pgrep", "-x", "inkscape"], capture_output=True).returncode == 0:
        print("!! Inkscape is running — close it and re-run")
        return 0
    text = PREFS.read_text()
    bak = PREFS.with_name(PREFS.name + ".pre-illustrator")
    if not bak.exists():
        shutil.copy2(PREFS, bak)
    for attr, val in (("gtkTheme", GTK_THEME), ("iconTheme", ICONS),
                      ("preferDarkTheme", "1"), ("darkTheme", "1")):
        text, ok = set_attr(text, "theme", attr, val)
        if not ok:
            print("!! <group id=\"theme\"> missing — theme not set")
            break
    if KEYS.exists():
        text, ok = set_attr(text, "kbshortcuts", "shortcutfile", str(KEYS))
        if not ok:   # add the group inside <group id="options" …>
            text = re.sub(r'(<group\s+id="options"[^>]*>)',
                          lambda m: m.group(1) + f'\n    <group\n       id="kbshortcuts"\n'
                                    f'       shortcutfile="{KEYS}" />', text, count=1)
    else:
        print("!! bundled Illustrator key set not found — shortcuts unchanged")
    PREFS.write_text(text)
    print("==> Inkscape: Catppuccin theme + Illustrator shortcuts")
    return 0


if __name__ == "__main__":
    sys.exit(main())
