#!/usr/bin/env python3
"""Catppuccin Macchiato versions of the network (nm-applet) and Bluetooth
(blueman) tray icons. Run by `./install.sh theme`; safe to re-run.

Those applets hand waybar's tray plain *named* icons (nm-signal-75,
blueman-active…), not symbolic ones, so CSS can't tint them. Papirus panel
icons colour themselves via a few `.ColorScheme-*` classes with Google-ish
colours; this rewrites those to Macchiato and writes the result to
~/.local/share/icons/Papirus-Dark/<size>/panel/. GTK merges a theme's
directories across all icon dirs, so these override the system copies by
name while every state/signal level keeps working.
"""
import os
import re
import sys
from pathlib import Path

SRC = Path("/usr/share/icons/Papirus-Dark")
DST = Path(os.environ.get("XDG_DATA_HOME", Path.home() / ".local/share")) / "icons" / "Papirus-Dark"

# icon name prefix → main ("Text") colour; the status colours are shared
FAMILIES = [
    (("nm-", "network-", "gnome-netstatus"), "#8bd5ca"),   # teal — Wi-Fi / network
    (("blueman", "bluetooth"),               "#8aadf4"),   # blue — Bluetooth
]
STATUS = {
    "#4285f4": "#c6a0f6",   # Highlight   → mauve (accent)
    "#4caf50": "#a6da95",   # PositiveText → green
    "#ff9800": "#f5a97f",   # NeutralText  → peach
    "#f44336": "#ed8796",   # NegativeText → red
}
TEXT = "#dfdfdf"


def family_colour(name):
    for prefixes, colour in FAMILIES:
        if name.startswith(prefixes):
            return colour
    return None


def recolour(svg, main):
    svg = re.sub(re.escape(TEXT), main, svg, flags=re.I)
    for old, new in STATUS.items():
        svg = re.sub(re.escape(old), new, svg, flags=re.I)
    return svg


def main():
    if not SRC.is_dir():
        sys.exit(f"{SRC} not found — is papirus-icon-theme installed?")
    written = 0
    for panel in sorted(SRC.glob("*/panel")):
        out_dir = DST / panel.parent.name / "panel"
        for icon in sorted(panel.iterdir()):
            main_colour = family_colour(icon.name)
            if not main_colour or icon.suffix != ".svg":
                continue
            try:
                svg = icon.resolve().read_text()
            except OSError:
                continue
            out_dir.mkdir(parents=True, exist_ok=True)
            target = out_dir / icon.name
            new = recolour(svg, main_colour)
            if not target.exists() or target.read_text() != new:
                target.write_text(new)
                written += 1
    print(f"tray icons: {written} written/updated in {DST}")


if __name__ == "__main__":
    main()
