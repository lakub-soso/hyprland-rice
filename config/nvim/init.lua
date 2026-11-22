-- Neovim config (hyprland-rice). Linked to ~/.config/nvim by ./install.sh link.
--   lua/config/   options, keymaps, autocmds, plugin manager bootstrap
--   lua/plugins/  one file per area; lazy.nvim loads every file in there
-- Plugin versions are pinned in lazy-lock.json (in git). :Lazy to manage,
-- :Mason for language servers / formatters, :checkhealth if something's off.

vim.g.mapleader = " "
vim.g.maplocalleader = " "

require("config.options")
require("config.keymaps")
require("config.autocmds")
require("config.lazy")
