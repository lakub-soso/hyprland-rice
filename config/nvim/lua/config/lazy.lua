-- lazy.nvim bootstrap: clones itself on first start.
local path = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(path) then
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable",
                              "https://github.com/folke/lazy.nvim.git", path })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({ { "Failed to clone lazy.nvim:\n" .. out, "ErrorMsg" } }, true, {})
    return
  end
end
vim.opt.rtp:prepend(path)

require("lazy").setup("plugins", {
  -- lazy-lock.json is symlinked from the repo, so `:Lazy update` updates git
  lockfile = vim.fn.stdpath("config") .. "/lazy-lock.json",
  install = { colorscheme = { "catppuccin" } },
  checker = { enabled = false },          -- no background update checks
  rocks = { enabled = false },            -- no plugin here needs luarocks
  change_detection = { notify = false },
  ui = { border = "rounded" },
  performance = {
    rtp = { disabled_plugins = { "gzip", "tarPlugin", "tohtml", "tutor", "zipPlugin", "netrwPlugin" } },
  },
})
