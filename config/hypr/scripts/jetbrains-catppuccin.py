#!/usr/bin/env python3
"""Catppuccin Macchiato for the JetBrains IDEs installed via Toolbox
(CLion, WebStorm, Android Studio). Run by `./install.sh ide`; safe to re-run.

Per IDE (skipped while it's running — plugin installs need it closed):
  1. installs the official plugin com.github.catppuccin.jetbrains through the
     IDE's own CLI (`<launcher> installPlugins <id>`), unless already present
  2. in its newest config dir sets
       options/laf.xml           → UI theme "Islands Catppuccin Macchiato"
                                   (also as the dark theme for "sync with OS")
       options/colors.scheme.xml → editor scheme "Catppuccin Macchiato"
     editing only those settings, so other options in the files survive.
Theme/scheme IDs come from the plugin's plugin.xml / templates:
https://github.com/catppuccin/jetbrains
"""
import glob
import os
import subprocess
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

PLUGIN = "com.github.catppuccin.jetbrains"
THEME = "com.github.catppuccin.macchiato.islands.jetbrains"   # new ("Islands") UI
SCHEME = "Catppuccin Macchiato"

HOME = Path.home()
SCRIPTS = HOME / ".local/share/JetBrains/Toolbox/scripts"
IDES = [  # (Toolbox launcher, Toolbox app dir, config dir glob, plugins dir glob)
    ("clion",    "clion",          "~/.config/JetBrains/CLion*",       "~/.local/share/JetBrains/CLion*"),
    ("webstorm", "webstorm",       "~/.config/JetBrains/WebStorm*",    "~/.local/share/JetBrains/WebStorm*"),
    ("studio",   "android-studio", "~/.config/Google/AndroidStudio*",  "~/.local/share/Google/AndroidStudio*"),
]


def newest(pattern):
    dirs = sorted(glob.glob(os.path.expanduser(pattern)), key=os.path.getmtime)
    return Path(dirs[-1]) if dirs else None


def running(app_dir):
    return subprocess.run(["pgrep", "-f", f"Toolbox/apps/{app_dir}/"], capture_output=True).returncode == 0


def plugin_installed(plugins_glob):
    d = newest(plugins_glob)
    return bool(d and any("catppuccin" in p.name.lower() for p in d.iterdir()))


def edit_xml(path, component, apply):
    """Load <application> XML (or start one), find/create <component name=…>,
    let apply() modify it, write back."""
    path.parent.mkdir(parents=True, exist_ok=True)
    root = ET.parse(path).getroot() if path.exists() else ET.Element("application")
    comp = next((c for c in root.findall("component") if c.get("name") == component), None)
    if comp is None:
        comp = ET.SubElement(root, "component", name=component)
    apply(comp)
    ET.indent(root, space="  ")
    path.write_text(ET.tostring(root, encoding="unicode") + "\n")


def set_child(comp, tag, **attrs):
    el = comp.find(tag)
    if el is None:
        el = ET.SubElement(comp, tag)
    el.attrib.clear()
    el.attrib.update(attrs)


def main():
    done = 0
    for launcher, app_dir, config_glob, plugins_glob in IDES:
        exe = SCRIPTS / launcher
        if not exe.exists():
            continue
        name = {"clion": "CLion", "webstorm": "WebStorm", "studio": "Android Studio"}[launcher]
        if running(app_dir):
            print(f"!! {name} is running — close it and re-run ./install.sh ide")
            continue
        if not plugin_installed(plugins_glob):
            print(f"==> {name}: installing the Catppuccin plugin")
            r = subprocess.run([str(exe), "installPlugins", PLUGIN],
                               capture_output=True, text=True, timeout=600)
            if not plugin_installed(plugins_glob):
                print(f"!! {name}: plugin install failed (exit {r.returncode}):\n"
                      + (r.stdout + r.stderr).strip()[-600:])
                continue
        config = newest(config_glob)
        if config is None:
            print(f"!! {name}: no config dir yet — start it once, then re-run")
            continue
        edit_xml(config / "options/laf.xml", "LafManager",
                 lambda c: (set_child(c, "laf", themeId=THEME),
                            set_child(c, "preferred-dark-laf", themeId=THEME)))
        edit_xml(config / "options/colors.scheme.xml", "EditorColorsManagerImpl",
                 lambda c: set_child(c, "global_color_scheme", name=SCHEME))
        print(f"==> {name}: Catppuccin Macchiato set ({config.name})")
        done += 1
    if not done:
        print("no JetBrains IDEs configured")


if __name__ == "__main__":
    sys.exit(main())
