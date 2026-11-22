#!/usr/bin/env python3
"""Keybind cheatsheet (SUPER + /): fullscreen, symbolic keycaps, multi-column.

Reads the data file hypr/modules/cheatsheet.lua writes on every config load
(S<tab>Section / K<tab>KEYS<tab>Description), then:
  • draws keys as keycaps with symbols (❖ ⇧ ⌃ ⌥ ␣ ⏎ ⎋ …)
  • picks a column count for the focused monitor's width
  • packs whole sections into columns (a section never splits) and pads the
    columns to equal height, because rofi fills columns top-to-bottom
    (flow: vertical) in themes/cheatsheet.rasi
Type to filter. Esc (or SUPER + / again) closes.
"""
import html
import math
import subprocess
import sys

DATA = sys.argv[1] if len(sys.argv) > 1 else "/run/user/1000/hypr-cheatsheet.tsv"
MIN_COLUMN_PX = 520           # logical px per column → 4 on 2560, 2 on a 1080 portrait
MAX_COLUMNS = 4

SYMBOLS = {
    "SUPER": "❖", "SHIFT": "⇧", "CTRL": "⌃", "CONTROL": "⌃", "ALT": "⌥",
    "space": "␣", "Return": "⏎", "Escape": "⎋", "Tab": "⇥", "BackSpace": "⌫",
    "slash": "/", "period": ".", "comma": ",", "left": "←", "right": "→", "up": "↑", "down": "↓",
    "mouse:272": "L-drag", "mouse:273": "R-drag",
    "mouse_down": "wheel↓", "mouse_up": "wheel↑",
    "XF86AudioRaiseVolume": "vol+", "XF86AudioLowerVolume": "vol−",
    "XF86AudioMute": "mute", "XF86AudioMicMute": "mic",
    "XF86AudioPlay": "⏯", "XF86AudioPause": "⏸",
    "XF86AudioNext": "⏭", "XF86AudioPrev": "⏮",
    "XF86MonBrightnessUp": "☀+", "XF86MonBrightnessDown": "☀−",
}
KEYCAP = '<span background="#363a4f" foreground="#cad3f5"> {} </span>'   # surface0 / text
DESC = '<span foreground="#b8c0e0">{}</span>'                             # subtext1
HEADER = '<span foreground="#c6a0f6" weight="bold">{}</span>'            # mauve


def esc(s):
    return html.escape(s, quote=False)


def keycaps(keys):
    """'SUPER + SHIFT + S' → (markup, visible width)"""
    toks = [SYMBOLS.get(t.strip(), t.strip()) for t in keys.split("+") if t.strip()]
    width = sum(len(t) + 2 for t in toks) + max(0, len(toks) - 1)
    return " ".join(KEYCAP.format(esc(t)) for t in toks), width


def read_sections():
    sections = []
    with open(DATA, encoding="utf-8") as f:
        for line in f:
            parts = line.rstrip("\n").split("\t")
            if parts[0] == "S" and len(parts) > 1:
                sections.append((parts[1], []))
            elif parts[0] == "K" and len(parts) > 2:
                if not sections:
                    sections.append(("General", []))
                sections[-1][1].append((parts[1], parts[2]))
    return [s for s in sections if s[1]]


def focused_logical_width():
    out = subprocess.run(["hyprctl", "monitors"], capture_output=True, text=True).stdout
    w = h = None
    scale, transform = 1.0, 0
    for line in out.splitlines() + ["Monitor"]:
        line = line.strip()
        if line.startswith("Monitor"):
            w = None
        elif w is None and "x" in line and "@" in line and line[0].isdigit():
            w, h = (int(v) for v in line.split("@")[0].split("x"))
        elif line.startswith("scale:"):
            scale = float(line.split()[1])
        elif line.startswith("transform:"):
            transform = int(line.split()[1])
        elif line == "focused: yes" and w:
            return (h if transform % 2 else w) / scale
    return 2560


def pack(sections, cols):
    """Split sections (kept in order, never split) into at most `cols` columns
    with the smallest possible column height. Sections in a column are
    separated by a blank spacer row."""
    def fill(height):
        columns = [[]]
        for rows in sections:
            cur = columns[-1]
            if cur and len(cur) + 1 + len(rows) > height:
                columns.append([])
                cur = columns[-1]
            if cur:
                cur.append(" ")
            cur.extend(rows)
        return columns
    height = max(len(r) for r in sections)
    while len(fill(height)) > cols:
        height += 1
    return fill(height)


def main():
    # toggle: a second press closes it
    if subprocess.run(["pkill", "-x", "rofi"]).returncode == 0:
        return
    sections = read_sections()
    if not sections:
        return

    # rows per section: header + items, plus a blank spacer between sections
    rendered = []
    key_w = max(keycaps(k)[1] for _, items in sections for k, _ in items) + 2
    for name, items in sections:
        rows = [HEADER.format(esc(name.upper()))]
        for keys, desc in items:
            caps, w = keycaps(keys)
            rows.append(caps + " " * (key_w - w) + DESC.format(esc(desc)))
        rendered.append(rows)

    cols = max(1, min(MAX_COLUMNS, int(focused_logical_width() // MIN_COLUMN_PX), len(rendered)))
    columns = pack(rendered, cols)
    lines = max(len(c) for c in columns)
    text = "\n".join(row for c in columns for row in c + [" "] * (lines - len(c))) + "\n"

    subprocess.run(
        ["rofi", "-dmenu", "-i", "-no-custom", "-markup-rows", "-p", "Keybinds",
         "-theme", "cheatsheet",
         "-theme-str", f"listview {{ lines: {lines}; columns: {len(columns)}; }}"],
        input=text, text=True, stdout=subprocess.DEVNULL)


if __name__ == "__main__":
    main()
