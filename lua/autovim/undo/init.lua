-- Adapt Undotree's supported window-command hook to the shared panel.
local M = {}
local panel

function M.mount(win, editor)
  require("lazy").load({ plugins = { "undotree" } })
  panel = win
  vim.api.nvim_create_user_command("AutoVimUndoBuffer", function(opts)
    assert(panel and vim.api.nvim_win_is_valid(panel), "No AutoVim undo panel")
    vim.api.nvim_set_current_win(panel)
    vim.cmd("hide edit " .. vim.fn.fnameescape(opts.args))
  end, { nargs = 1, force = true })
  vim.api.nvim_set_current_win(editor)
  vim.fn["undotree#UndotreeShow"]()
  vim.api.nvim_set_current_win(win)
  vim.wo.winbar = "%#AVBarMuted# UNDO HISTORY"
  for _, key in ipairs({ "q", "<Esc>" }) do
    vim.keymap.set("n", key, function() require("autovim.sidebar").close() end, { buffer = true, silent = true })
  end
  -- The shared tool area stays one window; never spawn the optional diff split.
  vim.keymap.set("n", "D", "<Nop>", { buffer = true, silent = true })
end

function M.unmount()
  pcall(vim.api.nvim_clear_autocmds, { group = "Undotree" })
end

return M
