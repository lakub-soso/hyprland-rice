return {
  -- fuzzy finder (uses fd + ripgrep)
  {
    "ibhagwan/fzf-lua",
    cmd = "FzfLua",
    opts = { winopts = { border = "rounded" }, fzf_colors = true },
    keys = {
      { "<leader><space>", "<cmd>FzfLua files<cr>", desc = "Find files" },
      { "<leader>ff", "<cmd>FzfLua files<cr>", desc = "Files" },
      { "<leader>fg", "<cmd>FzfLua live_grep<cr>", desc = "Grep" },
      { "<leader>fw", "<cmd>FzfLua grep_cword<cr>", desc = "Word under cursor" },
      { "<leader>fb", "<cmd>FzfLua buffers<cr>", desc = "Buffers" },
      { "<leader>fr", "<cmd>FzfLua oldfiles<cr>", desc = "Recent files" },
      { "<leader>fh", "<cmd>FzfLua helptags<cr>", desc = "Help" },
      { "<leader>fk", "<cmd>FzfLua keymaps<cr>", desc = "Keymaps" },
      { "<leader>fd", "<cmd>FzfLua diagnostics_document<cr>", desc = "Diagnostics" },
      { "<leader>fs", "<cmd>FzfLua lsp_document_symbols<cr>", desc = "Symbols" },
      { "<leader>f.", "<cmd>FzfLua resume<cr>", desc = "Resume last search" },
    },
  },

  -- file explorer: edit a directory like a buffer (rename = edit the line, :w applies)
  {
    "stevearc/oil.nvim",
    lazy = false,                      -- so `nvim .` opens oil
    opts = { view_options = { show_hidden = true }, float = { border = "rounded" } },
    keys = { { "-", "<cmd>Oil<cr>", desc = "Open parent directory" } },
  },

  -- sidebar file tree (VS Code style), with git + diagnostic markers.
  -- oil stays on `-` for quick rename/move; directories (`nvim .`) open in oil.
  {
    "nvim-tree/nvim-tree.lua",
    cmd = { "NvimTreeToggle", "NvimTreeFindFileToggle" },
    keys = {
      { "<leader>e", "<cmd>NvimTreeToggle<cr>", desc = "File tree" },
      { "<leader>E", "<cmd>NvimTreeFindFileToggle<cr>", desc = "File tree (reveal current file)" },
    },
    opts = {
      hijack_netrw = false,
      hijack_directories = { enable = false },
      sync_root_with_cwd = true,
      view = { width = 34 },
      renderer = { group_empty = true, highlight_git = "name", indent_markers = { enable = true } },
      diagnostics = { enable = true, show_on_dirs = true },
      filters = { dotfiles = false, custom = { "^.git$" } },
      actions = { open_file = { quit_on_open = false } },
    },
  },

  -- git signs in the gutter + hunk actions
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      on_attach = function(buf)
        local gs = require("gitsigns")
        local function map(l, r, desc) vim.keymap.set("n", l, r, { buffer = buf, desc = desc }) end
        map("]h", function() gs.nav_hunk("next") end, "Next hunk")
        map("[h", function() gs.nav_hunk("prev") end, "Prev hunk")
        map("<leader>gs", gs.stage_hunk, "Stage hunk")
        map("<leader>gr", gs.reset_hunk, "Reset hunk")
        map("<leader>gp", gs.preview_hunk, "Preview hunk")
        map("<leader>gb", gs.blame_line, "Blame line")
        map("<leader>gd", gs.diffthis, "Diff file")
      end,
    },
  },

  -- lazygit in a floating window (needs the lazygit package)
  {
    "kdheepak/lazygit.nvim",
    cmd = { "LazyGit", "LazyGitCurrentFile", "LazyGitLog" },
    dependencies = { "nvim-lua/plenary.nvim" },
    init = function()
      vim.g.lazygit_floating_window_scaling_factor = 0.92
      vim.g.lazygit_floating_window_border_chars = { "╭", "─", "╮", "│", "╯", "─", "╰", "│" }
      vim.g.lazygit_use_custom_config_file_path = 0   -- use ~/.config/lazygit/config.yml
    end,
    keys = {
      { "<leader>gg", "<cmd>LazyGit<cr>", desc = "Lazygit" },
      { "<leader>gf", "<cmd>LazyGitCurrentFile<cr>", desc = "Lazygit (this file's repo)" },
      { "<leader>gl", "<cmd>LazyGitLog<cr>", desc = "Git log" },
    },
  },

  -- small editing helpers (gc to comment is built into Neovim)
  { "echasnovski/mini.pairs", event = "InsertEnter", opts = {} },
  { "echasnovski/mini.surround", event = "VeryLazy", opts = {} },  -- sa / sd / sr
  { "echasnovski/mini.ai", event = "VeryLazy", opts = {} },        -- better a/i text objects
}
