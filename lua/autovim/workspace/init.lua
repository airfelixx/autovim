-- Workspace scope: one explicit root per tab, independent of the explorer.
-- A nil root means standalone editing. No automatic Git-root guessing.
local M = {}
local api = vim.api

local function absolute(path)
  local full = vim.fs.normalize(vim.fn.fnamemodify(vim.fs.normalize(path), ":p"))
  if #full > 1 then full = full:gsub("/$", "") end
  return full
end

function M.root()
  return vim.t.autovim_root
end

function M.file()
  if vim.bo.buftype ~= "" or vim.bo.filetype == "netrw" or vim.bo.filetype == "autovim" then
    return vim.t.autovim_file
  end
  local name = api.nvim_buf_get_name(0)
  if name == "" or vim.fn.isdirectory(name) == 1 then return nil end
  return name
end

function M.directory()
  local file = M.file()
  return M.root() or (file and vim.fs.dirname(file)) or vim.fn.getcwd()
end

function M.open(path)
  if not path or path == "" then
    require("autovim.explorer.picker").open("workspace")
    return
  end
  path = absolute(path)
  if vim.fn.isdirectory(path) ~= 1 then
    vim.notify("Not a directory: " .. path, vim.log.levels.WARN)
    return
  end
  local explorer = require("autovim.explorer")
  require("autovim.sidebar").close()
  require("autovim.sidebar").focus_editor()
  -- Hide the old buffer; selecting a new workspace never discards its edits.
  vim.cmd("hide enew")
  vim.t.autovim_root = path
  vim.t.autovim_file = nil
  vim.cmd("tcd " .. vim.fn.fnameescape(path))
  explorer.open()
end

function M.open_file(path, standalone)
  if not path or path == "" then
    require("autovim.explorer.picker").open(standalone and "standalone" or "file")
    return
  end
  path = absolute(path)
  if vim.fn.isdirectory(path) == 1 or vim.fn.isdirectory(vim.fs.dirname(path)) ~= 1 then
    vim.notify("Choose a file in an existing directory: " .. path, vim.log.levels.WARN)
    return
  end
  local explorer = require("autovim.explorer")
  local reopen = explorer.is_open()
  explorer.close()
  require("autovim.sidebar").focus_editor()
  local buffer
  for _, candidate in ipairs(api.nvim_list_bufs()) do
    if api.nvim_buf_get_name(candidate) == path then buffer = candidate; break end
  end
  if buffer then vim.cmd("hide buffer " .. buffer)
  else vim.cmd("hide edit " .. vim.fn.fnameescape(path)) end
  if standalone then vim.t.autovim_root = nil end
  if not M.root() then vim.cmd("tcd " .. vim.fn.fnameescape(vim.fs.dirname(path))) end
  if reopen then
    local editor = api.nvim_get_current_win()
    explorer.open()
    api.nvim_set_current_win(editor)
  end
end

function M.pick()
  require("autovim.explorer.picker").open("any")
end

function M.setup()
  local group = api.nvim_create_augroup("AutoVimWorkspace", { clear = true })
  api.nvim_create_autocmd("BufEnter", { group = group, callback = function()
    if vim.bo.buftype ~= "" or vim.bo.filetype == "netrw" or vim.bo.filetype == "autovim" then return end
    local file = M.file()
    if file then vim.t.autovim_file = file end
  end })
  api.nvim_create_autocmd("VimEnter", { group = group, once = true, callback = function()
    -- Native file arguments stay files. Only an explicit directory gets a root.
    if vim.fn.argc() == 1 then
      local path = vim.fn.argv(0)
      if vim.fn.isdirectory(path) == 1 then
        path = absolute(path)
        vim.t.autovim_root = path
        if #api.nvim_list_uis() > 0 then vim.schedule(function() M.open(path) end) end
      end
    end
  end })
end

return M
