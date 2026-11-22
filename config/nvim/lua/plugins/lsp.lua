-- Language servers. Mason installs them into ~/.local/share/nvim/mason (npm-based
-- ones need node/npm on PATH — nvm's, so start nvim from a shell the first time).
-- clangd comes from pacman (already installed), not Mason.
local servers = {
  lua_ls = {
    settings = { Lua = { workspace = { checkThirdParty = false }, completion = { callSnippet = "Replace" } } },
  },
  vtsls = {},          -- TypeScript / JavaScript
  basedpyright = {},   -- Python
  bashls = {},
  jsonls = {},
  yamlls = {},
  taplo = {},          -- TOML
  marksman = {},       -- Markdown
  html = {},
  cssls = {},
}

return {
  {
    "mason-org/mason.nvim",
    cmd = "Mason",
    opts = { ui = { border = "rounded" } },
  },
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "mason-org/mason.nvim",
      "mason-org/mason-lspconfig.nvim",
      "WhoIsSethDaniel/mason-tool-installer.nvim",
      "saghen/blink.cmp",
    },
    config = function()
      local caps = require("blink.cmp").get_lsp_capabilities()
      for name, cfg in pairs(servers) do
        vim.lsp.config(name, vim.tbl_deep_extend("force", { capabilities = caps }, cfg))
      end
      vim.lsp.config("clangd", { capabilities = caps })
      vim.lsp.enable("clangd")

      require("mason-tool-installer").setup({
        ensure_installed = vim.list_extend(vim.tbl_keys(servers),
          { "stylua", "prettierd", "ruff", "shfmt", "shellcheck" }),
      })
      require("mason-lspconfig").setup({ automatic_enable = vim.tbl_keys(servers) })

      vim.diagnostic.config({
        severity_sort = true,
        virtual_text = { spacing = 2, source = "if_many" },
        float = { border = "rounded", source = "if_many" },
        signs = { text = {
          [vim.diagnostic.severity.ERROR] = "", [vim.diagnostic.severity.WARN] = "",
          [vim.diagnostic.severity.INFO] = "", [vim.diagnostic.severity.HINT] = "",
        } },
      })

      -- keymaps once a server attaches (Neovim already maps K, grn, gra, grr, gri)
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("rice_lsp", { clear = true }),
        callback = function(ev)
          local function map(l, r, desc) vim.keymap.set("n", l, r, { buffer = ev.buf, desc = desc }) end
          map("gd", "<cmd>FzfLua lsp_definitions<cr>", "Go to definition")
          map("gr", "<cmd>FzfLua lsp_references<cr>", "References")
          map("gI", "<cmd>FzfLua lsp_implementations<cr>", "Implementations")
          map("<leader>cr", vim.lsp.buf.rename, "Rename")
          map("<leader>ca", vim.lsp.buf.code_action, "Code action")
          map("<leader>ch", function()
            vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = ev.buf }), { bufnr = ev.buf })
          end, "Toggle inlay hints")
        end,
      })
    end,
  },
}
