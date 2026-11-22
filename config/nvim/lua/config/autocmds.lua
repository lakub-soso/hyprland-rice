local au = vim.api.nvim_create_autocmd
local group = vim.api.nvim_create_augroup("rice", { clear = true })

-- flash yanked text
au("TextYankPost", { group = group, callback = function() vim.hl.on_yank() end })

-- reopen files at the last cursor position
au("BufReadPost", {
  group = group,
  callback = function(ev)
    local mark = vim.api.nvim_buf_get_mark(ev.buf, '"')
    if mark[1] > 0 and mark[1] <= vim.api.nvim_buf_line_count(ev.buf) then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- 2-space indent where that's the convention
au("FileType", {
  group = group,
  pattern = { "lua", "javascript", "typescript", "javascriptreact", "typescriptreact",
              "json", "jsonc", "yaml", "html", "css", "scss", "markdown", "vue", "svelte" },
  callback = function() vim.opt_local.shiftwidth = 2; vim.opt_local.tabstop = 2 end,
})

-- prose: wrap + spellcheck
au("FileType", {
  group = group,
  pattern = { "markdown", "gitcommit", "text" },
  callback = function() vim.opt_local.wrap = true; vim.opt_local.spell = true end,
})

-- resize splits when the window (Hyprland tile) changes size
au("VimResized", { group = group, command = "tabdo wincmd =" })
