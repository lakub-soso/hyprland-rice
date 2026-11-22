# hyprland-rice

My Arch + Hyprland (Lua config, Hyprland ≥ 0.57) setup, reproducible from scratch.

## Layout

```
config/          mirrors ~/.config — every file here is symlinked into place
  hypr/hyprland.lua      entry point — just requires the modules in order
  hypr/modules/          one file per section (keybinds, appearance, rules, ...)
                         programs.lua returns shared values (terminal, mainMod)
  ~/.config/hypr/local.lua   optional per-machine overrides, untracked
  theme/macchiato.css    Catppuccin Macchiato palette (GTK CSS) for waybar;
                         Lua copy in hypr/modules/colors.lua. Accent = mauve.
  waybar/ rofi/ wlogout/ kitty/ dunst/ gtk-3.0/ gtk-4.0/ qt6ct/   per-app configs
  nvim/                  Neovim config, see Neovim below
data/            mirrors ~/.local/share — symlinked the same way
  wallpapers/wallhaven-ly3x32.png   desktop (hypr/hyprpaper.conf) + login
                 screen wallpaper — https://wallhaven.cc/w/ly3x32
  color-schemes/CatppuccinMacchiatoMauve.colors
                 KDE colour scheme. KDE apps (Dolphin) ignore qt6ct, so
                 `./install.sh theme` merges this into ~/.config/kdeglobals and
                 selects it in dolphinrc (kdeglobals isn't symlinked because
                 KDE apps write their own settings into it).
home/            mirrors $HOME — symlinked like config/ (just .zshenv, which
                 points zsh at ~/.config/zsh via ZDOTDIR)
config/zsh/.zshrc        zsh: zinit plugins, fzf-tab, zoxide, history…
config/starship.toml     prompt: Catppuccin Macchiato powerline (p10k-like)
system/          mirrors / — COPIED (sudo) by `./install.sh system`, since
                 system daemons can't read $HOME. Re-run after editing.
  etc/sddm.conf.d/10-theme.conf   SDDM login theme (Catppuccin Macchiato mauve)
packages/
  pacman.txt     official-repo packages — RICE section, then APPS by category
  aur.txt        AUR packages (installed via yay), same layout
  flatpak.txt    Flathub app IDs (Bazaar store, Dev Toolbox), installed system-wide
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

## Startup apps

Things start at login from three places:

1. **`config/hypr/modules/autostart.lua`** — the rice's own (waybar, hyprpaper,
   nm-applet, clipboard history…). Edit it like any other config.
2. **XDG autostart** — `.desktop` files in `~/.config/autostart/` (per user,
   usually written by the app itself, e.g. JetBrains Toolbox) and
   `/etc/xdg/autostart/` (system-wide, from packages). uwsm starts these as
   `app-*@autostart.service` units.
3. **systemd user services** — e.g. Docker Desktop's "start on login" enables
   `docker-desktop.service`.

**Easiest: launcher → Settings → Startup Apps** (`config/rofi/scripts/startup.py`).
It lists login items and session services with ● on / ○ off. Enter toggles,
"Add an app…" adds one, Shift+Delete removes one you added. Overrides for
system entries and apps you add are saved in `config/autostart/` and linked,
so they survive a reinstall. Changes apply at the next login.

By hand — see what's active:

```sh
ls ~/.config/autostart /etc/xdg/autostart
systemctl --user list-units --all 'app-*@autostart.service'
systemctl --user list-unit-files --state=enabled
```

Remove one:

- **App wrote it itself** → turn off its own "start at login" setting first
  (otherwise it re-adds the file), then delete its file in `~/.config/autostart/`.
  JetBrains Toolbox: Settings → *Launch Toolbox App at system startup*.
- **systemd service** → `systemctl --user disable <name>.service`
  (Docker Desktop: also untick *Start Docker Desktop when you sign in*).
- **System-wide entry** → don't edit `/etc/xdg/autostart`; put a file with the
  same name in `config/autostart/` containing `[Desktop Entry]` + `Hidden=true`
  and run `./install.sh link`. That hides it for your user only.

## Neovim

Config in `config/nvim/` (linked to `~/.config/nvim`). An own small config in
the spirit of kickstart.nvim, not a distro: every line is in this repo.

```
init.lua             leader = Space, loads the rest
lua/config/          options, keymaps, autocmds, lazy.nvim bootstrap
lua/plugins/         one file per area — lazy.nvim loads them all
  colorscheme.lua    Catppuccin Macchiato
  ui.lua             lualine, which-key, icons
  editor.lua         fzf-lua, nvim-tree, oil, gitsigns, lazygit, mini.*
  treesitter.lua     nvim-treesitter (main branch) parsers
  lsp.lua            language servers via Mason + vim.lsp.config
  completion.lua     blink.cmp
  format.lua         conform.nvim, format on save
lazy-lock.json       pinned plugin versions (`:Lazy update` updates this file)
cheatsheet.tsv       the Neovim tab of the SUPER + / cheatsheet — keep in sync
```

**First run** (after `./install.sh packages` and `./install.sh link`):

1. Run `./install.sh dev` first: the npm-based language servers need node
   (from nvm) on PATH.
2. Start `nvim` from a terminal. lazy.nvim installs the plugins, and Mason
   installs the language servers + formatters in the background (`:Mason`
   shows progress).
3. `:TSUpdate` builds the treesitter parsers (needs `tree-sitter-cli`).
4. `:checkhealth` if anything looks off.

**Getting around:** press `Space` and wait. which-key lists everything, and
the full list is in the cheatsheet (`SUPER + /`, then `Tab`). The essentials:
`Space Space` find files · `Space f g` grep · `Space e` file tree · `-` oil ·
`gd` / `gr` definition / references · `Space c a` code action ·
`Space g g` lazygit.

**Notes**
- `vim` is aliased to `nvim` (`config/zsh/.zshrc`), and `EDITOR`/`VISUAL` are
  `nvim` (`home/.zshenv`). The `vim` package stays installed as a fallback.
- Clipboard: `clipboard=unnamedplus` uses `wl-copy` / `wl-paste`, so yank/paste
  is shared with every other app.
- Add a language server: put it in the `servers` table in `lsp.lua` (name from
  `:help lspconfig-all`). Mason installs it on the next start.
- lazygit's theme: `config/lazygit/config.yml`. Pressing `e` in lazygit opens
  the file in the nvim it was launched from.
