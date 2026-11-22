#!/usr/bin/env python3
"""Catppuccin Macchiato (mauve) for every Obsidian vault. Run by
`./install.sh ide`; safe to re-run. Themes are per vault in Obsidian.

For each vault listed in ~/.config/obsidian/obsidian.json that exists now
(vaults on unmounted drives are skipped — re-run later):
  .obsidian/themes/Catppuccin/   official theme, downloaded from GitHub
  .obsidian/snippets/catppuccin-macchiato.css   flavour/accent (config/obsidian/)
  .obsidian/appearance.json      cssTheme=Catppuccin, dark mode, snippet enabled
Obsidian picks the change up on its next start (or Settings → Appearance).
"""
import json
import shutil
import sys
import urllib.request
from pathlib import Path

REPO = Path(__file__).resolve().parents[3]
SNIPPET = REPO / "config/obsidian/catppuccin-macchiato.css"
RAW = "https://raw.githubusercontent.com/catppuccin/obsidian/main/"
VAULTS = Path.home() / ".config/obsidian/obsidian.json"


def fetch_theme(cache: Path) -> bool:
    cache.mkdir(parents=True, exist_ok=True)
    for name in ("theme.css", "manifest.json"):
        try:
            with urllib.request.urlopen(RAW + name, timeout=30) as r:
                (cache / name).write_bytes(r.read())
        except OSError as e:
            if not (cache / name).exists():
                print(f"!! couldn't download {name}: {e}")
                return False
    return True


def main():
    if not VAULTS.exists():
        print("!! Obsidian has no vaults yet — skipping")
        return 0
    vaults = [Path(v["path"]) for v in json.loads(VAULTS.read_text())["vaults"].values()]
    vaults = [v for v in vaults if (v / ".obsidian").is_dir()]
    if not vaults:
        print("!! no Obsidian vault reachable (unmounted drive?) — skipping")
        return 0
    cache = Path.home() / ".cache/obsidian-catppuccin"
    if not fetch_theme(cache):
        return 1
    for v in vaults:
        cfg = v / ".obsidian"
        theme = cfg / "themes/Catppuccin"
        theme.mkdir(parents=True, exist_ok=True)
        for name in ("theme.css", "manifest.json"):
            shutil.copy2(cache / name, theme / name)
        (cfg / "snippets").mkdir(exist_ok=True)
        shutil.copy2(SNIPPET, cfg / "snippets" / SNIPPET.name)
        app = cfg / "appearance.json"
        data = json.loads(app.read_text()) if app.exists() else {}
        data["cssTheme"] = "Catppuccin"
        data["theme"] = "obsidian"            # = dark mode
        snips = data.setdefault("enabledCssSnippets", [])
        if SNIPPET.stem not in snips:
            snips.append(SNIPPET.stem)
        app.write_text(json.dumps(data, indent=2) + "\n")
        print(f"==> Obsidian: Catppuccin Macchiato in {v}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
