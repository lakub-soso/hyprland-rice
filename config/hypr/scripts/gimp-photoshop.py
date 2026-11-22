#!/usr/bin/env python3
"""GIMP 3: Catppuccin (via the GTK theme) + Photoshop-style shortcuts & layout.
Run by `./install.sh ide`; safe to re-run. Close GIMP first (it rewrites
shortcutsrc/sessionrc/gimprc on exit and would undo this).

  gimprc       theme System (follows the GTK Catppuccin theme), dark, symbolic icons
  shortcutsrc  Photoshop key map (below). Any default binding that collides with
               one of ours is unbound, so nothing fires twice.
  sessionrc    PS-like docks: slim one-column toolbox left; tool options (like PS Properties),
               colours/brushes and layers/channels/paths/history on the right.
Originals are saved once as <file>.pre-photoshop.
"""
import re
import shutil
import subprocess
import sys
from pathlib import Path

P, S, A = "<Primary>", "<Shift>", "<Alt>"
KEYS = {
    # tools
    "tools-move": ["v"], "tools-rect-select": ["m"], "tools-ellipse-select": [S + "m"],
    "tools-free-select": ["l"], "tools-fuzzy-select": ["w"], "tools-by-color-select": [S + "w"],
    "tools-crop": ["c"], "tools-color-picker": ["i"], "tools-heal": ["j"],
    "tools-clone": ["s"], "tools-paintbrush": ["b"], "tools-pencil": [S + "b"],
    "tools-eraser": ["e"], "tools-gradient": ["g"], "tools-bucket-fill": [S + "g"],
    "tools-dodge-burn": ["o"], "tools-path": ["p"], "tools-text": ["t"], "tools-zoom": ["z"],
    "tools-smudge": ["r"], "tools-unified-transform": [P + "t"],
    # undo / redo (Ctrl+Z, Ctrl+Shift+Z, Ctrl+Alt+Z = step backward)
    "edit-undo": [P + "z"], "edit-redo": [P + S + "z", P + "y"], "edit-strong-undo": [P + A + "z"],
    "edit-strong-redo": [],
    # layers
    "layers-duplicate": [P + "j"], "layers-new": [P + S + "n"], "layers-new-group": [P + "g"],
    "layers-merge-down": [P + "e"], "image-merge-layers": [P + S + "e"],
    "layers-new-from-visible": [P + S + A + "e"],
    "layers-raise": [P + "bracketright"], "layers-lower": [P + "bracketleft"],
    "layers-raise-to-top": [P + S + "bracketright"], "layers-lower-to-bottom": [P + S + "bracketleft"],
    "layers-select-next": [A + "bracketright"], "layers-select-previous": [A + "bracketleft"],
    # selection
    "select-all": [P + "a"], "select-none": [P + "d"], "select-invert": [P + S + "i"],
    # fills
    "edit-fill-fg": [A + "BackSpace"], "edit-fill-bg": [P + "BackSpace"],
    # adjustments
    "tools-levels": [P + "l"], "tools-curves": [P + "m"], "filters-hue-saturation": [P + "u"],
    "filters-color-balance": [P + "b"], "filters-desaturate": [P + S + "u"],
    "filters-invert-perceptual": [P + "i"],
    # image
    "image-scale": [P + A + "i"], "image-resize": [P + A + "c"],
    "file-export-as": [P + S + A + "s"],
    # view
    "view-zoom-fit-in": [P + "0"], "view-zoom-1-1": [P + "1"],
    "view-zoom-in": [P + "equal", P + "plus", "plus", "KP_Add"],
    "view-zoom-out": [P + "minus", "minus", "KP_Subtract"],
    "view-show-rulers": [P + "r"], "view-show-guides": [P + "semicolon"],
    "view-show-grid": [P + "apostrophe"], "view-show-selection": [P + "h"],
    # panels
    "dialogs-layers": ["F7"], "dialogs-brushes": ["F5"], "dialogs-colors": ["F6"],
    "dialogs-channels": ["F8"], "dialogs-undo-history": ["F9"],
}

GIMPRC = {"theme": '"System"', "theme-color-scheme": "dark"}

SESSION_DOCKS = '''    (gimp-toolbox
        (side left))
    (gimp-dock
        (side right)
        (book
            (current-page 0)
            (dockable "gimp-tool-options"
                (tab-style icon)
                (aux-info
                    (show-button-bar "true")))
            (dockable "gimp-color-editor"
                (tab-style icon)
                (aux-info
                    (show-button-bar "true")))
            (dockable "gimp-brush-grid"
                (tab-style icon)
                (aux-info
                    (show-button-bar "true")))
            (dockable "gimp-pattern-grid"
                (tab-style icon)
                (aux-info
                    (show-button-bar "true"))))
        (book
            (position 336)
            (current-page 0)
            (dockable "gimp-layer-list"
                (tab-style icon)
                (preview-size 32)
                (aux-info
                    (show-button-bar "true")))
            (dockable "gimp-channel-list"
                (tab-style icon)
                (preview-size 32)
                (aux-info
                    (show-button-bar "true")))
            (dockable "gimp-path-list"
                (tab-style icon)
                (preview-size 32)
                (aux-info
                    (show-button-bar "true")))
            (dockable "gimp-undo-history"
                (tab-style icon)
                (aux-info
                    (show-button-bar "true")))))
'''


def backup(f):
    b = f.with_name(f.name + ".pre-photoshop")
    if f.exists() and not b.exists():
        shutil.copy2(f, b)


def do_gimprc(f):
    text = f.read_text() if f.exists() else ""
    for k in GIMPRC:
        text = re.sub(r"^\(" + re.escape(k) + r" [^\n]*\)\n", "", text, flags=re.M)
    text = text.rstrip("\n") + "\n" + "".join(f"({k} {v})\n" for k, v in GIMPRC.items())
    f.write_text(text)


def do_shortcuts(f):
    lines = f.read_text().splitlines()
    wanted = {a for ks in KEYS.values() for a in ks}
    out, seen = [], set()
    pat = re.compile(r'^(#\s*)?\(action "([^"]+)"((?:\s+"[^"]*")*)\)\s*$')
    for ln in lines:
        if ln.startswith("# --- Photoshop key map"):
            continue
        m = pat.match(ln)
        if not m:
            out.append(ln)
            continue
        name, accels = m.group(2), re.findall(r'"([^"]*)"', m.group(3))
        if name in KEYS or name in seen:
            continue                                   # replaced below
        seen.add(name)
        left = [a for a in accels if a not in wanted]
        if left != accels:                              # collision → unbind
            out.append("(action \"%s\"%s)" % (name, "".join(f' "{a}"' for a in left)))
        else:
            out.append(ln)
    out.append("")
    out.append("# --- Photoshop key map (config/hypr/scripts/gimp-photoshop.py) ---")
    for name, ks in KEYS.items():
        out.append('(action "%s"%s)' % (name, "".join(f' "{a}"' for a in ks)))
    f.write_text("\n".join(out) + "\n")


def do_session(f):
    if not f.exists():
        return
    text = f.read_text()
    m = re.search(r'    \(gimp-toolbox\n.*?(?=\n\(hide-docks)', text, flags=re.S)
    if not m:
        print("!! sessionrc layout not recognised — layout left as is")
        return
    # the block ends with the single-image-window's closing paren
    text = re.sub(r'\(left-docks-width "\d+"\)', '(left-docks-width "56")', text)
    text = re.sub(r'\(right-docks-width "\d+"\)', '(right-docks-width "320")', text)
    m = re.search(r'    \(gimp-toolbox\n.*?(?=\n\(hide-docks)', text, flags=re.S)
    new = SESSION_DOCKS.rstrip("\n") + ")\n"           # re-close (session-info …)
    f.write_text(text[:m.start()] + new + text[m.end():])


def main():
    dirs = sorted(Path.home().glob(".config/GIMP/3.*"))
    if not dirs:
        print("!! GIMP 3 config not found (start GIMP once) — skipping")
        return 0
    if any(subprocess.run(["pgrep", "-x", n], capture_output=True).returncode == 0
           for n in ("gimp", "gimp-3.2", "gimp-3")):
        print("!! GIMP is running — close it and re-run (it overwrites these on exit)")
        return 0
    d = dirs[-1]
    for name, fn in (("gimprc", do_gimprc), ("shortcutsrc", do_shortcuts), ("sessionrc", do_session)):
        f = d / name
        if name != "gimprc" and not f.exists():
            continue
        backup(f)
        fn(f)
    print(f"==> GIMP ({d.name}): Catppuccin theme + Photoshop shortcuts/layout")
    return 0


if __name__ == "__main__":
    sys.exit(main())
