#!/usr/bin/env python3
"""Wallpaper picker (SUPER + W): rofi grid of thumbnails, applied live.

  wallpaper.py            open the picker (pressing the bind again closes it)
  wallpaper.py --start    used by autostart: start hyprpaper with the saved pick

Images come from the repo's wallpapers (~/.local/share/wallpapers, linked from
data/wallpapers/) and your own folder ~/Pictures/Wallpapers (untracked). The
pick is applied with `hyprctl hyprpaper wallpaper` to every monitor and saved
in ~/.local/state/wallpaper; --start renders config/hypr/hyprpaper.conf with
that path into ~/.local/state/hyprpaper.conf, so login shows it straight away
(the tracked hyprpaper.conf keeps the repo default). Thumbnails are cached in
~/.cache/wallpaper-thumbs (libvips; falls back to the full image).
"""
import hashlib
import os
import random
import re
import shutil
import subprocess
import sys
from pathlib import Path

HOME = Path.home()
DIRS = [HOME / ".local/share/wallpapers", HOME / "Pictures/Wallpapers"]
EXTS = {".png", ".jpg", ".jpeg", ".webp", ".jxl", ".bmp"}
STATE = HOME / ".local/state/wallpaper"
CONF_TEMPLATE = HOME / ".config/hypr/hyprpaper.conf"
CONF = HOME / ".local/state/hyprpaper.conf"
THUMBS = HOME / ".cache/wallpaper-thumbs"
THUMB_PX = 360
FIT = "cover"


def images():
    out = []
    for d in DIRS:
        if d.is_dir():
            out += sorted(p for p in d.iterdir() if p.suffix.lower() in EXTS and p.is_file())
    return out


def thumb(img: Path) -> str:
    key = hashlib.sha1(f"{img.resolve()}:{img.stat().st_mtime_ns}".encode()).hexdigest()
    t = THUMBS / f"{key}.jpg"
    if not t.exists() and shutil.which("vipsthumbnail"):
        THUMBS.mkdir(parents=True, exist_ok=True)
        subprocess.run(["vipsthumbnail", str(img), "--size", f"{THUMB_PX}x{THUMB_PX}",
                        "-o", f"{t}[Q=85]"], capture_output=True)
    return str(t if t.exists() else img)


def saved() -> Path | None:
    try:
        p = Path(STATE.read_text().strip())
        return p if p.is_file() else None
    except OSError:
        return None


def write_conf(path: Path | None):
    """hyprpaper.conf from the repo, with the wallpaper path swapped in."""
    text = CONF_TEMPLATE.read_text()
    if path:
        text = re.sub(r"(?m)^(\s*path\s*=\s*)\S.*$", lambda m: m.group(1) + str(path), text)
    CONF.parent.mkdir(parents=True, exist_ok=True)
    CONF.write_text(text)


def apply(path: Path):
    subprocess.run(["hyprctl", "hyprpaper", "wallpaper", f",{path},{FIT}"], capture_output=True)
    STATE.parent.mkdir(parents=True, exist_ok=True)
    STATE.write_text(str(path) + "\n")
    write_conf(path)


def start():
    write_conf(saved())
    os.execvp("hyprpaper", ["hyprpaper", "-c", str(CONF)])


def pick():
    if subprocess.run(["pkill", "-x", "rofi"]).returncode == 0:
        return
    (HOME / "Pictures/Wallpapers").mkdir(parents=True, exist_ok=True)
    imgs = images()
    if not imgs:
        return
    cur = saved()
    rows = ["Random\0icon\x1fmedia-playlist-shuffle"]
    rows += [f"{p.stem}\0icon\x1f{thumb(p)}" for p in imgs]
    selected = next((i + 1 for i, p in enumerate(imgs) if cur and p.resolve() == cur.resolve()), 0)
    r = subprocess.run(
        ["rofi", "-dmenu", "-i", "-show-icons", "-format", "i", "-p", "Wallpaper",
         "-theme", "wallpaper", "-selected-row", str(selected),
         "-mesg", "Add your own to ~/Pictures/Wallpapers"],
        input="\n".join(rows) + "\n", text=True, capture_output=True)
    if r.returncode != 0 or not r.stdout.strip():
        return
    i = int(r.stdout.strip())
    if i == 0:
        others = [p for p in imgs if not (cur and p.resolve() == cur.resolve())] or imgs
        apply(random.choice(others))
    else:
        apply(imgs[i - 1])


if __name__ == "__main__":
    start() if "--start" in sys.argv else pick()
