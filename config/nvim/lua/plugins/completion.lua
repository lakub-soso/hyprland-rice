return {
  "saghen/blink.cmp",
  version = "1.*",                   -- release builds ship a prebuilt fuzzy matcher
  event = "InsertEnter",
  dependencies = { "rafamadriz/friendly-snippets" },
  opts = {
    keymap = { preset = "default" },  -- Ctrl+y accept, Ctrl+n/p move, Ctrl+Space open
    appearance = { nerd_font_variant = "mono" },
    completion = {
      documentation = { auto_show = true, auto_show_delay_ms = 300, window = { border = "rounded" } },
      menu = { border = "rounded" },
    },
    signature = { enabled = true, window = { border = "rounded" } },
    sources = { default = { "lsp", "path", "snippets", "buffer" } },
  },
}
