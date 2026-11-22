-- Catppuccin Macchiato, mauve accent — same palette as the rest of the rice.
return {
  "catppuccin/nvim",
  name = "catppuccin",
  lazy = false,
  priority = 1000,
  opts = {
    flavour = "macchiato",
    transparent_background = false,   -- kitty's background is the same base colour
    auto_integrations = false,        -- listed below; auto-detect calls vim.pack, which creates an empty pack dir (:checkhealth warning)
    integrations = {
      blink_cmp = true, fzf = true, gitsigns = true, mason = true, nvimtree = true,
      native_lsp = { enabled = true }, treesitter = true, which_key = true, mini = { enabled = true },
    },
  },
  config = function(_, opts)
    require("catppuccin").setup(opts)
    vim.cmd.colorscheme("catppuccin")
  end,
}
