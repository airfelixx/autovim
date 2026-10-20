-- Global editor options go here. Dashboard-only options stay in its scope.
local M = {}

function M.setup()
  -- Set leaders before any mappings are registered.
  vim.g.mapleader = " "
  vim.g.maplocalleader = " "
  vim.opt.termguicolors = true
  vim.opt.mouse = "a"
  vim.opt.winminwidth = 1
  vim.opt.equalalways = false
  vim.opt.undofile = true
end

return M
