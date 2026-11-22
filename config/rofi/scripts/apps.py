#!/usr/bin/env python3
"""rofi script mode "Apps" for the launcher (SUPER + Space).

Lists desktop apps under category headers, alphabetical within each category,
with the 5 most recently launched apps on top, tagged "recent" (shown
there only, so search results don't contain duplicates).

Also handles the launcher's header buttons (themes/launcher.rasi). With
use-hot-keys on, rofi sends custom keys here instead of switching modes:
  kb-custom-1..4  (Alt+1..4)  → switch to Apps / Calc / Files / Windows
  kb-custom-13    (avatar)    → user settings (mugshot)
  kb-custom-17    (power)     → power menu (wlogout, scripts/power.sh)
files.sh handles the same keys, so the buttons work in both script modes.
"""
import html
import os
import subprocess
import sys
from pathlib import Path

RECENT_SHOWN = 5
RECENT_KEPT = 30
MODES = ["apps", "calc", "files", "window"]           # -modi order (launcher.sh)
KEY_AVATAR, KEY_POWER = 10 + 12, 10 + 16               # ROFI_RETV for kb-custom-13 / -17
HOME = Path.home()
STATE = Path(os.environ.get("XDG_STATE_HOME", HOME / ".local/state")) / "rofi-launcher"
RECENT_FILE = STATE / "recent"
SCRIPTS = Path(__file__).resolve().parent

# Freedesktop main categories → section; first match in this order wins
# (many apps list several, e.g. "Utility;Development").
CATEGORY_MAP = [
    ("Game", "Games"), ("Development", "Development"), ("Graphics", "Graphics"),
    ("AudioVideo", "Multimedia"), ("Audio", "Multimedia"), ("Video", "Multimedia"),
    ("Network", "Internet"), ("Office", "Office"), ("Education", "Education"),
    ("Science", "Science"), ("Settings", "Settings"), ("System", "System"),
    ("Utility", "Utilities"),
]
OTHER = "Other"
HEADER = '<span size="small" weight="bold" foreground="#8aadf4">{}</span>'


def out(text, **opts):
    """One rofi row: text\\0key\\x1fvalue\\x1fkey\\x1fvalue…"""
    extra = "\x1f".join(f"{k}\x1f{v}" for k, v in opts.items())
    sys.stdout.write(text + ("\0" + extra if extra else "") + "\n")


def header(key, value):
    sys.stdout.write(f"\0{key}\x1f{value}\n")


def spawn(*cmd):
    subprocess.Popen(["setsid", "-f", *cmd], stdout=subprocess.DEVNULL,
                     stderr=subprocess.DEVNULL, stdin=subprocess.DEVNULL)


def app_dirs():
    data_home = Path(os.environ.get("XDG_DATA_HOME", HOME / ".local/share"))
    data_dirs = os.environ.get("XDG_DATA_DIRS", "/usr/local/share:/usr/share").split(":")
    dirs = [data_home] + [Path(d) for d in data_dirs if d]
    # Flatpak exports, in case the session's XDG_DATA_DIRS lacks them
    dirs += [data_home / "flatpak/exports/share", Path("/var/lib/flatpak/exports/share")]
    seen, result = set(), []
    for d in dirs:
        a = (d / "applications").resolve()
        if a not in seen and a.is_dir():
            seen.add(a)
            result.append(a)
    return result


def parse_desktop(path):
    entry, in_main = {}, False
    try:
        for line in path.read_text(errors="replace").splitlines():
            line = line.strip()
            if line.startswith("["):
                in_main = line == "[Desktop Entry]"
            elif in_main and "=" in line and not line.startswith("#"):
                k, v = line.split("=", 1)
                entry.setdefault(k.strip(), v.strip())   # first wins (skip dupes)
    except OSError:
        return None
    return entry


def visible(e, desktops):
    if e.get("Type") != "Application" or not e.get("Name"):
        return False
    if e.get("NoDisplay", "").lower() == "true" or e.get("Hidden", "").lower() == "true":
        return False
    only = [x for x in e.get("OnlyShowIn", "").split(";") if x]
    if only and not desktops & set(only):
        return False
    if desktops & {x for x in e.get("NotShowIn", "").split(";") if x}:
        return False
    tryexec = e.get("TryExec")
    if tryexec:
        from shutil import which
        if not (which(tryexec) or os.access(tryexec, os.X_OK)):
            return False
    return True


def load_apps():
    desktops = set(os.environ.get("XDG_CURRENT_DESKTOP", "").split(":"))
    apps = {}                                   # desktop id → info; earlier dirs win
    for d in app_dirs():
        for f in sorted(d.rglob("*.desktop")):
            app_id = str(f.relative_to(d)).replace("/", "-")
            if app_id in apps:
                continue
            e = parse_desktop(f)
            if e is None:
                continue
            apps[app_id] = e if visible(e, desktops) else None   # None = hidden override
            if e is not None and apps[app_id] is not None:
                e["_path"] = str(f)
    return {k: v for k, v in apps.items() if v}


def section(e):
    cats = set(e.get("Categories", "").split(";"))
    for cat, name in CATEGORY_MAP:
        if cat in cats:
            return name
    return OTHER


def read_recent():
    try:
        return [l for l in RECENT_FILE.read_text().splitlines() if l]
    except OSError:
        return []


def record_recent(app_id):
    ids = [app_id] + [i for i in read_recent() if i != app_id]
    STATE.mkdir(parents=True, exist_ok=True)
    RECENT_FILE.write_text("\n".join(ids[:RECENT_KEPT]) + "\n")


RECENT_TAG = '<span size="small" foreground="#6e738d">  recent</span>'
SUBTITLE = '<span size="small" foreground="#6e738d">  {}</span>'


def row(app_id, e, recent=False):
    name = html.escape(e["Name"], quote=False)
    generic = e.get("GenericName", "")
    # Hidden search terms (rofi "meta"): the generic name ("File Manager"), the
    # description (Comment: "Manage your files"), keywords and categories — so
    # fuzzy search finds apps by what they do, not only by their name.
    meta = " ".join(filter(None, [
        generic, e.get("Comment", ""),
        e.get("Keywords", "").replace(";", " "),
        e.get("Categories", "").replace(";", " "), app_id]))
    opts = dict(icon=e.get("Icon", "application-x-executable"), info=app_id, meta=meta)
    # `display` only changes what's shown (search uses the plain name + meta):
    # the generic name as a grey subtitle shows why a search matched, and the
    # "recent" tag doesn't make "rec" match every recent app.
    display = name
    if generic and generic.casefold() != e["Name"].casefold():
        display += SUBTITLE.format(html.escape(generic, quote=False))
    if recent:
        display += RECENT_TAG
    if display != name:
        opts["display"] = display
    out(name, **opts)


def list_apps():
    header("markup-rows", "true")
    header("use-hot-keys", "true")
    header("no-custom", "false")   # hot keys need a selection or custom input
    apps = load_apps()
    # Recent apps first, tagged "recent" instead of under a header: rofi selects
    # row 0 on open AND after every search keystroke, so row 0 must be an app.
    # (-selected-row 1 would skip a header on open, but it keeps the SECOND
    # row selected while searching.) Until something has been launched, the
    # list starts with a category header — press Down once.
    recent = [i for i in read_recent() if i in apps][:RECENT_SHOWN]
    for app_id in recent:
        row(app_id, apps[app_id], recent=True)
    groups = {}
    for app_id, e in apps.items():
        if app_id not in recent:
            groups.setdefault(section(e), []).append((e["Name"].casefold(), app_id, e))
    for name in sorted(groups, key=lambda n: (n == OTHER, n)):   # A–Z, "Other" last
        out(HEADER.format(name.upper()), nonselectable="true")
        for _, app_id, e in sorted(groups[name]):
            row(app_id, e)


def handle_hot_key(retv):
    """Shared with files.sh (imported via `apps.py --hot-key N`)."""
    if retv == KEY_POWER:
        spawn(str(SCRIPTS / "power.sh"))
        return True                      # print nothing → rofi closes
    if retv == KEY_AVATAR:
        spawn("mugshot")
        return True
    idx = retv - 10
    if 0 <= idx < len(MODES):
        header("switch-mode", MODES[idx])
        return False
    return False


def main():
    if len(sys.argv) > 2 and sys.argv[1] == "--hot-key":   # from files.sh
        handle_hot_key(int(sys.argv[2]))
        return
    retv = int(os.environ.get("ROFI_RETV", "0"))
    if retv >= 10:
        if not handle_hot_key(retv):
            list_apps()
        return
    if retv == 1:                        # an app was chosen
        app_id = os.environ.get("ROFI_INFO", "")
        apps = load_apps()
        if app_id in apps:
            record_recent(app_id)
            spawn("gio", "launch", apps[app_id]["_path"])
        return                           # print nothing → rofi closes
    if retv == 2:                        # Enter on text matching nothing: close
        return
    list_apps()


if __name__ == "__main__":
    main()
