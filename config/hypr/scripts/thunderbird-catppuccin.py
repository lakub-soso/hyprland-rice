#!/usr/bin/env python3
"""Catppuccin Macchiato (mauve) for Thunderbird. Run by `./install.sh ide`;
safe to re-run. Thunderbird must be CLOSED: it rewrites prefs.js on exit.

For every profile in ~/.config/thunderbird/profiles.ini:
  extensions/<id>.xpi   the official theme (github.com/catppuccin/thunderbird),
                        pinned to a commit + checksum, cached in ~/.cache
  prefs.js              extensions.activeThemeID = the theme
                        extensions.autoDisableScopes = 14: add-ons dropped
                        into the profile folder are enabled instead of held
                        for an "allow this add-on?" prompt (only the profile
                        scope; system/app-wide sideloads still need approval)
                        layout.css.prefers-color-scheme.content-override = 0:
                        settings pages and HTML content render dark too
Written to prefs.js, not user.js, so the theme stays changeable in
Settings → Add-ons and Themes (user.js would force it back on every start).
"""
import hashlib
import json
import re
import shutil
import subprocess
import sys
import urllib.request
import zipfile
from configparser import ConfigParser
from pathlib import Path

COMMIT = "575ab278460137dba10c1a23d00af0bc583fe509"
URL = f"https://raw.githubusercontent.com/catppuccin/thunderbird/{COMMIT}/themes/macchiato/macchiato-mauve.xpi"
SHA256 = "2b3612d2cdd1a59ee7be1ea4a61dd89dcd0fae821c47cdaccbae1cab1bb01f01"
CACHE = Path.home() / ".cache/hyprland-rice/catppuccin-macchiato-mauve.xpi"
ROOT = Path.home() / ".config/thunderbird"     # Thunderbird ≥ 128 on Linux (was ~/.thunderbird)


def fetch():
    if CACHE.exists() and hashlib.sha256(CACHE.read_bytes()).hexdigest() == SHA256:
        return True
    try:
        with urllib.request.urlopen(URL, timeout=30) as r:
            data = r.read()
    except OSError as e:
        print(f"!! Thunderbird: couldn't download the theme: {e}")
        return False
    if hashlib.sha256(data).hexdigest() != SHA256:
        print("!! Thunderbird: theme checksum mismatch — not installing")
        return False
    CACHE.parent.mkdir(parents=True, exist_ok=True)
    CACHE.write_bytes(data)
    return True


def set_prefs(path, prefs):
    """Replace or append user_pref(...) lines; every other line is kept."""
    text = path.read_text() if path.exists() else ""
    for key, value in prefs.items():
        line = f"user_pref({json.dumps(key)}, {json.dumps(value)});"
        pat = re.compile(r"^user_pref\(" + re.escape(json.dumps(key)) + r",.*\);$", re.M)
        text = pat.sub(line, text, count=1) if pat.search(text) else text.rstrip("\n") + ("\n" if text else "") + line + "\n"
    changed = not path.exists() or path.read_text() != text
    if changed:
        path.write_text(text)
    return changed


def activate(profile, theme_id):
    """extensions.activeThemeID alone doesn't enable a newly found theme:
    Thunderbird registers it in extensions.json as disabled. Flip it there
    (and turn the other themes off). Returns None if it isn't registered yet."""
    db = profile / "extensions.json"
    if not db.exists():
        return None
    data = json.loads(db.read_text())
    themes = [a for a in data.get("addons", []) if a.get("type") == "theme"]
    if not any(a["id"] == theme_id for a in themes):
        return None
    changed = False
    for a in themes:
        on = a["id"] == theme_id
        if a.get("active") != on or a.get("userDisabled") != (not on):
            a["active"], a["userDisabled"] = on, not on
            changed = True
    if changed:
        db.write_text(json.dumps(data, separators=(",", ":")))
    return changed


def main():
    if not shutil.which("thunderbird"):
        print("!! Thunderbird not installed — skipping")
        return 0
    if subprocess.run(["pgrep", "-x", "thunderbird"], capture_output=True).returncode == 0:
        print("!! Thunderbird is running — close it and re-run ./install.sh ide")
        return 0
    ini = ROOT / "profiles.ini"
    if not ini.exists():
        print("!! Thunderbird has no profile yet — start it once, close it, then re-run")
        return 0
    cp = ConfigParser()
    cp.read(ini)
    profiles = [(ROOT / s["Path"]) if s.get("IsRelative", "1") == "1" else Path(s["Path"])
                for name, s in cp.items() if name.startswith("Profile") and "Path" in s]
    profiles = [p for p in profiles if p.is_dir()]
    if not fetch():
        return 1
    theme_id = json.loads(zipfile.ZipFile(CACHE).read("manifest.json"))["applications"]["gecko"]["id"]
    prefs = {
        "extensions.activeThemeID": theme_id,
        "extensions.autoDisableScopes": 14,
        "layout.css.prefers-color-scheme.content-override": 0,
    }
    changed, pending = False, []
    for p in profiles:
        xpi = p / "extensions" / f"{theme_id}.xpi"
        if not xpi.exists() or xpi.read_bytes() != CACHE.read_bytes():
            xpi.parent.mkdir(exist_ok=True)
            shutil.copy2(CACHE, xpi)
            changed = True
        changed |= set_prefs(p / "prefs.js", prefs)
        state = activate(p, theme_id)
        if state is None:
            pending.append(p.name)
        else:
            changed |= state
    print(f"==> Thunderbird: Catppuccin Macchiato {'set' if changed else 'already set'} "
          f"({len(profiles)} profile{'s' if len(profiles) != 1 else ''})")
    if pending:
        print(f"!! Thunderbird: theme copied but not registered yet in {', '.join(pending)} — "
              "start Thunderbird once, close it, then re-run ./install.sh ide")
    return 0


if __name__ == "__main__":
    sys.exit(main())
