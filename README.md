# hyprland-rice

My Arch + Hyprland (Lua config, Hyprland ≥ 0.57) setup, reproducible from scratch.

## Layout

```
config/          mirrors ~/.config — every file here is symlinked into place
  hypr/hyprland.lua      entry point — just requires the modules in order
  hypr/modules/          one file per section (keybinds, appearance, rules, ...)
                         programs.lua returns shared values (terminal, mainMod)
  ~/.config/hypr/local.lua   optional per-machine overrides, untracked
  theme/macchiato.css    Catppuccin Macchiato palette (GTK CSS) for wofi + waybar;
                         Lua copy in hypr/modules/colors.lua. Accent = mauve.
  waybar/ wofi/ kitty/ dunst/ gtk-3.0/ gtk-4.0/ qt6ct/   per-app configs
data/            mirrors ~/.local/share — symlinked the same way
  wallpapers/wallhaven-ly3x32.png   desktop (hypr/hyprpaper.conf) + login
                 screen wallpaper — https://wallhaven.cc/w/ly3x32
  color-schemes/CatppuccinMacchiatoMauve.colors
                 KDE colour scheme. KDE apps (Dolphin) ignore qt6ct, so
                 `./install.sh theme` merges this into ~/.config/kdeglobals and
                 selects it in dolphinrc (kdeglobals isn't symlinked because
                 KDE apps write their own settings into it).
system/          mirrors / — COPIED (sudo) by `./install.sh system`, since
                 system daemons can't read $HOME. Re-run after editing.
  etc/sddm.conf.d/10-theme.conf   SDDM login theme (Catppuccin Macchiato mauve)
packages/
  pacman.txt     official-repo packages for the rice
  aur.txt        AUR packages (installed via yay)
  hardware.txt   machine-specific (CPU ucode, GPU driver, fs tools) — opt-in
install.sh       bootstrap / maintenance script
```

## Fresh machine

1. Install Arch (base, linux, linux-firmware, networking, sudo user).
2. Clone and run:
   ```sh
   git clone <this-repo> ~/Documents/hyprland-rice
   cd ~/Documents/hyprland-rice
   ./install.sh packages --hardware   # drop --hardware on different hardware
   ./install.sh link
   ./install.sh services
   ```
3. Reboot, pick Hyprland (uwsm) in SDDM.

Use `DRY_RUN=1 ./install.sh <cmd>` to preview any step.

## Day-to-day

- **Edit configs in place.** `~/.config/hypr/hyprland.lua` is a symlink into
  this repo, so edits are tracked automatically — just commit.
- **Track a new app's config:** move it into `config/<app>/`, then run
  `./install.sh link` (e.g. `mv ~/.config/waybar config/ && ./install.sh link`).
- **Installed something new?** Run `./install.sh diff` to see packages that
  aren't in a list yet, and add them.
- **Undo:** `./install.sh unlink` removes the symlinks; originals replaced by
  `link` are kept in `~/.config/.rice-backup-<timestamp>/`.
