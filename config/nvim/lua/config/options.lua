local o = vim.opt

o.number = true
o.relativenumber = true
o.signcolumn = "yes"          -- no text jumping when diagnostics appear
o.cursorline = true
o.scrolloff = 8
o.sidescrolloff = 8
o.wrap = false
o.colorcolumn = ""

o.expandtab = true            -- 4-space indent by default; .editorconfig and
o.shiftwidth = 4              -- per-language ftplugins override this
o.tabstop = 4
o.smartindent = true

o.ignorecase = true
o.smartcase = true
o.inccommand = "split"        -- live preview of :s/// in a split

o.splitright = true
o.splitbelow = true
o.termguicolors = true
o.showmode = false            -- lualine shows it
o.laststatus = 3              -- one statusline for all splits
o.winborder = "rounded"       -- floats (hover, signature, diagnostics)
o.list = true
o.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
o.fillchars = { eob = " " }

o.mouse = "a"
o.clipboard = "unnamedplus"   -- system clipboard (wl-clipboard on Wayland)
o.undofile = true             -- persistent undo
o.swapfile = false
o.updatetime = 250
o.timeoutlen = 400
o.confirm = true              -- ask instead of failing on :q with changes

-- remote-plugin providers: nothing here uses them (all plugins are Lua), and
-- they only add :checkhealth warnings. Clipboard is a separate provider.
vim.g.loaded_node_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_python3_provider = 0
vim.g.loaded_ruby_provider = 0
