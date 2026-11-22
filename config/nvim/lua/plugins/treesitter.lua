-- Syntax highlighting / indentation. nvim-treesitter's `main` branch: parsers
-- are compiled locally, which needs tree-sitter-cli + a C compiler.
local parsers = {
  "bash", "c", "cpp", "css", "diff", "go", "html", "javascript", "json", "lua", "luadoc",
  "markdown", "markdown_inline", "python", "query", "regex", "rust", "sql", "toml",
  "tsx", "typescript", "vim", "vimdoc", "yaml", "hyprlang",
}

return {
  "nvim-treesitter/nvim-treesitter",
  branch = "main",
  lazy = false,
  build = ":TSUpdate",
  config = function()
    if vim.fn.executable("tree-sitter") == 1 then
      require("nvim-treesitter").install(parsers)
    else
      vim.notify("tree-sitter-cli missing — parsers not installed (pacman -S tree-sitter-cli)",
                 vim.log.levels.WARN)
    end
    vim.api.nvim_create_autocmd("FileType", {
      group = vim.api.nvim_create_augroup("rice_treesitter", { clear = true }),
      callback = function(ev)
        if pcall(vim.treesitter.start, ev.buf) then
          vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end
      end,
    })
  end,
}
