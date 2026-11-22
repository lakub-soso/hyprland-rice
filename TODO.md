# TODO

## Neovim config

Goal: `config/nvim/` in this repo, linked to `~/.config/nvim` by `./install.sh link`,
themed like the rest of the rice (Catppuccin Macchiato, mauve accent, JetBrains Mono
via kitty). Done so far: kickstart-style own config (lazy.nvim, Mason, blink.cmp, fzf-lua,
oil, gitsigns, mini.*, conform, nvim-treesitter `main`). Notes on choices below.

### Decide first
- [x] Base: **LazyVim** (batteries included, fastest to useful) vs **kickstart.nvim**
      (one file, learn every line) vs from scratch. Picked: own kickstart-style config,
      split into lua/config + lua/plugins.
- [x] Plugin manager: `lazy.nvim` (whichever base is picked uses it).
- [x] `vim` → `nvim` alias in `.zshrc`; the `vim` package stays as a fallback.

### Packages (pacman.txt)
- [x] `ripgrep`: live grep in the fuzzy finder (`fd` is already there)
- [x] `tree-sitter-cli`: building parsers
- [x] `lazygit` (config/lazygit, Catppuccin)
- [x] `wl-clipboard`: checked, `+` register round-trips through wl-copy / wl-paste
- [x] Language servers / formatters: install them with Mason inside nvim, or from
      pacman (`lua-language-server`, `typescript-language-server`, `pyright`,
      `rust-analyzer`, `gopls`, `prettier`, `stylua`…). Picked: Mason (clangd from pacman).

### Core
- [x] Options: relative numbers, `scrolloff`, persistent undo, 4-space indent default,
      `signcolumn=yes`, system clipboard
- [x] Leader = Space; which-key to show the bindings
- [x] Theme: `catppuccin/nvim` with `flavour = "macchiato"`, transparent background
      off (match kitty)
- [x] Statusline (lualine, Catppuccin theme)
- [x] File tree (`oil.nvim` or `neo-tree`) + fuzzy finder (`telescope` or `fzf-lua`): picked oil + fzf-lua
- [x] Treesitter: highlight + indent for the languages below

### Languages (match the IDE stack: JetBrains / VS Code / Zed)
- [x] TypeScript / JavaScript (bun + node via nvm)
- [x] Python
- [x] Lua (for this config + the Hyprland Lua config)
- [ ] hyprlang parser is in the list; check it highlights config/hypr *.conf files
- [x] Bash / zsh, JSON, YAML, TOML, Markdown
- [x] C / C++ (CLion projects): clangd
- [ ] Rust / Go, if needed
- [ ] SQL (DBeaver stays for real DB work)

### Editing
- [x] LSP: go-to-definition, references, rename, code actions, diagnostics
- [x] Completion (`blink.cmp` or `nvim-cmp`): blink.cmp + snippets
- [x] Format on save (`conform.nvim`)
- [ ] Lint: only what the LSPs report for now (bashls runs shellcheck). Add `nvim-lint`
      or the `ruff` LSP if Python lint warnings are wanted inline
- [x] Git: gitsigns
- [x] lazygit.nvim: `<space> g g`
- [x] Comments, surround, autopairs
- [ ] Debugging (`nvim-dap`): later, only if it replaces the IDE for something

### Rice integration
- [ ] Repoint the Kate default-app entries in `install.sh` (`DEFAULT_APPS`) to an
      nvim-in-kitty `.desktop` file, or keep Kate as the GUI default
- [x] `EDITOR=nvim` / `VISUAL=nvim` in `home/.zshenv` (git commits, sudoedit)
- [x] Add the nvim keybinds to the keybinds cheatsheet (config/nvim/cheatsheet.tsv)
- [x] Keep `lazy-lock.json` in git so plugin versions are reproducible
- [x] README: Neovim section
