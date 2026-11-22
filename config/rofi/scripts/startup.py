#!/usr/bin/env python3
"""Startup Apps manager — a rofi script mode (launcher: Settings → Startup Apps).

Shows what starts at login and lets you change it:
  • Login items  — XDG autostart (~/.config/autostart, /etc/xdg/autostart)
  • Background services — systemd user services tied to the graphical session
Enter toggles on/off · "Add an app…" adds any app · Shift+Delete removes an
item you (or an app) added. Changes apply from the next login.

Where changes go:
  • turning OFF a system-wide entry → an override with Hidden=true, saved in
    the repo's config/autostart/ and linked into ~/.config/autostart, so it
    survives a fresh install (same idea as ./install.sh link)
  • apps you add → copied into config/autostart/ and linked the same way
  • files an app wrote itself (e.g. JetBrains Toolbox) → edited in place;
    turn off the app's own "start at login" setting too, or it rewrites them
  • services → systemctl --user enable/disable

Run with --open to start rofi on this mode.
"""
import html
import os
import shutil
import subprocess
import sys
from pathlib import Path

sys.dont_write_bytecode = True          # no __pycache__ in the repo
sys.path.insert(0, str(Path(__file__).resolve().parent))
import apps  # noqa: E402  (shares the .desktop parsing / app list)

HOME = Path.home()
USER_DIR = Path(os.environ.get("XDG_CONFIG_HOME", HOME / ".config")) / "autostart"
SYSTEM_DIRS = [Path(d) / "autostart" for d in
               os.environ.get("XDG_CONFIG_DIRS", "/etc/xdg").split(":") if d]
# Repo root: this file lives in <repo>/config/rofi/scripts/
_repo = Path(__file__).resolve().parents[3]
REPO_DIR = _repo / "config" / "autostart" if (_repo / "install.sh").exists() else None

# Services the rice already starts itself (hypr/modules/autostart.lua):
# enabling their units would start a second copy, so they aren't offered.
RICE_MANAGED = {"waybar.service", "hyprpaper.service", "hyprpolkitagent.service",
                "cliphist.service"}

ON = '<span foreground="#a6da95">●</span>'
OFF = '<span foreground="#6e738d">○</span>'
NOTE = '<span size="small" foreground="#6e738d">  {}</span>'
HEADER = apps.HEADER


def out(text, **opts):
    apps.out(text, **opts)


def hdr(key, value):
    apps.header(key, value)


# ---------------------------------------------------------------- XDG entries
def applies_here(e):
    desktops = set(os.environ.get("XDG_CURRENT_DESKTOP", "").split(":"))
    only = {x for x in e.get("OnlyShowIn", "").split(";") if x}
    if only and not desktops & only:
        return False
    if desktops & {x for x in e.get("NotShowIn", "").split(";") if x}:
        return False
    te = e.get("TryExec")
    return not te or bool(shutil.which(te) or os.access(te, os.X_OK))


def xdg_entries():
    """id → dict(name, icon, enabled, user_path, system_path)"""
    found = {}
    for d in reversed(SYSTEM_DIRS):
        for f in sorted(d.glob("*.desktop")) if d.is_dir() else []:
            found.setdefault(f.name, {})["system"] = f
    if USER_DIR.is_dir():
        for f in sorted(USER_DIR.glob("*.desktop")):
            found.setdefault(f.name, {})["user"] = f
    result = {}
    for app_id, paths in found.items():
        eff = paths.get("user") or paths.get("system")
        e = apps.parse_desktop(eff) or {}
        base = apps.parse_desktop(paths["system"]) if "system" in paths else e
        if not applies_here(base or e):
            continue
        enabled = (e.get("Hidden", "").lower() != "true"
                   and e.get("X-GNOME-Autostart-enabled", "true").lower() != "false")
        result[app_id] = dict(
            name=e.get("Name") or (base or {}).get("Name") or app_id[:-8],
            icon=e.get("Icon") or (base or {}).get("Icon") or "application-x-executable",
            enabled=enabled, user=paths.get("user"), system=paths.get("system"))
    return result


def set_keys(text, **kv):
    """Set keys in the [Desktop Entry] section of a .desktop file's text."""
    lines, out_lines, in_main, done = text.splitlines(), [], False, set()
    for line in lines:
        s = line.strip()
        if s.startswith("["):
            if in_main:  # leaving the section: append keys not seen yet
                out_lines += [f"{k}={v}" for k, v in kv.items() if k not in done]
                done |= set(kv)
            in_main = s == "[Desktop Entry]"
        elif in_main and "=" in s and s.split("=", 1)[0].strip() in kv:
            k = s.split("=", 1)[0].strip()
            out_lines.append(f"{k}={kv[k]}")
            done.add(k)
            continue
        out_lines.append(line)
    if in_main:
        out_lines += [f"{k}={v}" for k, v in kv.items() if k not in done]
    return "\n".join(out_lines) + "\n"


def save_user_file(app_id, text):
    """Write ~/.config/autostart/<id>: via the repo (linked) when possible."""
    USER_DIR.mkdir(parents=True, exist_ok=True)
    dst = USER_DIR / app_id
    if REPO_DIR is None:
        dst.write_text(text)
        return
    REPO_DIR.mkdir(parents=True, exist_ok=True)
    (REPO_DIR / app_id).write_text(text)
    if dst.is_symlink() or dst.exists():
        dst.unlink()
    dst.symlink_to(REPO_DIR / app_id)


def remove_user_file(app_id):
    dst = USER_DIR / app_id
    target = dst.resolve() if dst.is_symlink() else None
    if dst.is_symlink() or dst.exists():
        dst.unlink()
    if target and REPO_DIR and target.parent == REPO_DIR.resolve() and target.exists():
        target.unlink()


def toggle_xdg(app_id):
    e = xdg_entries().get(app_id)
    if not e:
        return
    if e["enabled"]:                                  # turn off
        src = e["user"] or e["system"]
        text = set_keys(src.read_text(errors="replace"), Hidden="true")
        if e["user"] and not e["user"].is_symlink():
            e["user"].write_text(text)                # app-written file: in place
        else:
            save_user_file(app_id, text)
    else:                                             # turn on
        if e["system"] and e["user"] and e["user"].is_symlink():
            remove_user_file(app_id)                  # drop our override
        elif e["user"]:
            text = set_keys(e["user"].read_text(errors="replace"),
                            Hidden="false", **{"X-GNOME-Autostart-enabled": "true"})
            if e["user"].is_symlink():
                e["user"].resolve().write_text(text)
            else:
                e["user"].write_text(text)


def add_app(app_id):
    a = apps.load_apps().get(app_id)
    if a:
        save_user_file(app_id, Path(a["_path"]).read_text(errors="replace"))


def remove_xdg(app_id):
    e = xdg_entries().get(app_id)
    if e and e["user"] and not e["system"]:           # only items added per user
        remove_user_file(app_id)


# ------------------------------------------------------------------- services
def systemctl(*args):
    return subprocess.run(["systemctl", "--user", *args], capture_output=True,
                          text=True).stdout.strip()


def services():
    """unit → (description, enabled) for session-bound user services."""
    result = {}
    for line in systemctl("list-unit-files", "--type=service", "--no-legend").splitlines():
        parts = line.split()
        if len(parts) < 2 or parts[1] not in ("enabled", "disabled") or parts[0] in RICE_MANAGED:
            continue
        frag = systemctl("show", "-p", "FragmentPath", "--value", parts[0])
        try:
            text = Path(frag).read_text(errors="replace")
        except OSError:
            continue
        wanted = [l for l in text.splitlines() if l.startswith("WantedBy=")]
        if not any("graphical-session" in l or "xdg-desktop-autostart" in l for l in wanted):
            continue
        desc = next((l.split("=", 1)[1] for l in text.splitlines()
                     if l.startswith("Description=")), parts[0])
        result[parts[0]] = (desc, parts[1] == "enabled")
    return result


# -------------------------------------------------------------------- listing
def list_main():
    hdr("prompt", "Startup")
    hdr("markup-rows", "true")
    hdr("no-custom", "true")
    hdr("keep-selection", "true")
    hdr("data", "main")
    hdr("message", "Enter: turn on/off · Shift+Del: remove an added item · applies at next login")
    out(HEADER.format("LOGIN ITEMS"), nonselectable="true")
    for app_id, e in sorted(xdg_entries().items(), key=lambda kv: kv[1]["name"].casefold()):
        where = "system" if e["system"] else "added"
        out(f'{ON if e["enabled"] else OFF}  {html.escape(e["name"], quote=False)}'
            + NOTE.format(where), icon=e["icon"], info=f"xdg:{app_id}", meta=app_id)
    out("＋  Add an app…", icon="list-add", info="add")
    svcs = services()
    if svcs:
        out(HEADER.format("BACKGROUND SERVICES"), nonselectable="true")
        for unit, (desc, enabled) in sorted(svcs.items(), key=lambda kv: kv[1][0].casefold()):
            out(f'{ON if enabled else OFF}  {html.escape(desc, quote=False)}'
                + NOTE.format(unit), icon="preferences-system-session",
                info=f"svc:{unit}", meta=unit)


def list_add():
    hdr("prompt", "Add to startup")
    hdr("markup-rows", "true")
    hdr("no-custom", "true")
    hdr("keep-selection", "false")
    hdr("data", "add")
    hdr("message", "Pick an app to start at login · Esc to close")
    out("←  Back", icon="go-previous", info="back")
    existing = set(xdg_entries())
    for app_id, e in sorted(apps.load_apps().items(), key=lambda kv: kv[1]["Name"].casefold()):
        if app_id not in existing:
            out(html.escape(e["Name"], quote=False),
                icon=e.get("Icon", "application-x-executable"), info=f"app:{app_id}")


def main():
    if "--open" in sys.argv:
        me = str(Path(sys.argv[0]).absolute())
        os.execvp("rofi", ["rofi", "-show", "startup", "-modi", f"startup:{me}"])
    retv = int(os.environ.get("ROFI_RETV", "0"))
    info = os.environ.get("ROFI_INFO", "")
    kind, _, arg = info.partition(":")
    if retv == 1:                                     # Enter
        if info == "add":
            return list_add()
        if kind == "xdg":
            toggle_xdg(arg)
        elif kind == "svc":
            systemctl("disable" if services().get(arg, ("", False))[1] else "enable", arg)
        elif kind == "app":
            add_app(arg)
    elif retv == 3 and kind == "xdg":                 # Shift+Delete
        remove_xdg(arg)
    list_main()


if __name__ == "__main__":
    main()
