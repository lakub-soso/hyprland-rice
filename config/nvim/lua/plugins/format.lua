-- Format on save. Formatters are installed by Mason (see lsp.lua); a project's
-- own config (.prettierrc, pyproject.toml, stylua.toml…) is respected.
return {
  "stevearc/conform.nvim",
  event = "BufWritePre",
  cmd = "ConformInfo",
  keys = {
    { "<leader>cf", function() require("conform").format({ async = true }) end, desc = "Format buffer" },
  },
  opts = {
    formatters_by_ft = {
      lua = { "stylua" },
      python = { "ruff_format", "ruff_organize_imports" },
      javascript = { "prettierd" }, typescript = { "prettierd" },
      javascriptreact = { "prettierd" }, typescriptreact = { "prettierd" },
      json = { "prettierd" }, jsonc = { "prettierd" }, yaml = { "prettierd" },
      html = { "prettierd" }, css = { "prettierd" }, markdown = { "prettierd" },
      sh = { "shfmt" }, bash = { "shfmt" }, zsh = { "shfmt" },
      c = { "clang-format" }, cpp = { "clang-format" },
    },
    format_on_save = { timeout_ms = 1000, lsp_format = "fallback" },
  },
}
