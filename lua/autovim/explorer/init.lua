-- Explorer scope: a netrw tree sidebar and editing-window routing per tab.
local M = {}
local api = vim.api
local tabs = {}

local function current()
  local tab = api.nvim_get_current_tabpage()
  tabs[tab] = tabs[tab] or {}
  return tabs[tab]
end

local function valid(win)
  return win and api.nvim_win_is_valid(win) and api.nvim_win_get_tabpage(win) == api.nvim_get_current_tabpage()
end

function M.is_open()
  local state = current()
  return valid(state.tree) and vim.bo[api.nvim_win_get_buf(state.tree)].filetype == "netrw" or false
end

local function route()
  local state = current()
  local win = api.nvim_get_current_win()
  local open = M.is_open()
  if not open then vim.g.netrw_chgwin = -1 end
  if win == state.tree then
    if not open then return end
    if not valid(state.editor) or state.editor == win then
      for _, other in ipairs(api.nvim_tabpage_list_wins(0)) do
        if other ~= win and api.nvim_win_get_config(other).relative == "" then state.editor = other; break end
      end
    end
    -- Enter routes files by window ID in select(); leave netrw's global
    -- target unset so native refreshes cannot replace an editing buffer.
  elseif vim.bo.buftype == "" and vim.bo.filetype ~= "netrw" and api.nvim_win_get_config(win).relative == "" then
    state.editor = win
  end
end

function M.close()
  require("autovim.sidebar").close("explorer")
  current().tree = nil
  vim.g.netrw_chgwin = -1
end

function M.select()
  local picker = require("autovim.explorer.picker")
  if picker.active() then picker.select(); return end
  local state = current()
  if M.is_open() and api.nvim_get_current_win() == state.tree then
    -- netrw resolves names and tree ancestors (including spaces and symlinks).
    local name = vim.fn["netrw#Call"]("NetrwGetWord")
    local dir = vim.fn["netrw#Call"]("NetrwTreeDir", 1)
    local path = vim.fs.normalize(dir .. "/" .. name)
    if vim.fn.filereadable(path) == 1 then
      route()
      if valid(state.editor) then
        api.nvim_set_current_win(state.editor)
        local buffer
        for _, candidate in ipairs(api.nvim_list_bufs()) do
          if api.nvim_buf_get_name(candidate) == path then buffer = candidate; break end
        end
        if buffer then vim.cmd("hide buffer " .. buffer)
        else vim.cmd("hide edit " .. vim.fn.fnameescape(path)) end
        return
      end
    end
  end
  -- Directories keep netrw's native expand/collapse and parent navigation.
  local keys = api.nvim_replace_termcodes("<Plug>NetrwLocalBrowseCheck", true, false, true)
  api.nvim_feedkeys(keys, "mx", false)
end

local function reveal(file, root)
  if not file then return end
  local prefix = root == "/" and "/" or root .. "/"
  if file:sub(1, #prefix) ~= prefix then return end
  local relative = file:sub(#prefix + 1)
  local parts = vim.split(relative, "/", { plain = true, trimempty = true })
  local start = 1
  for i, part in ipairs(parts) do
    local directory = i < #parts
    local wanted = part .. (directory and "/" or "")
    local found
    for row = start, api.nvim_buf_line_count(0) do
      local line = api.nvim_buf_get_lines(0, row - 1, row, false)[1]
      -- netrw uses Unicode or ASCII indentation, depending on the terminal.
      local name = line:gsub("\t -->.*$", "")
      while true do
        if name:sub(1, #"│ ") == "│ " then name = name:sub(#"│ " + 1)
        elseif name:sub(1, 2) == "| " then name = name:sub(3)
        else break end
      end
      if name == wanted or (not directory and (name == wanted .. "*" or name == wanted .. "@")) then found = row; break end
    end
    if not found then return end
    api.nvim_win_set_cursor(0, { found, 0 })
    if directory then
      M.select()
      start = found + 1
    end
  end
end

-- The shared sidebar owns geometry; this scope only fills it with netrw.
function M.mount(win, editor)
  local workspace = require("autovim.workspace")
  local root, file = workspace.directory(), workspace.file()
  local state = current()
  state.editor, state.tree = editor, win
  api.nvim_set_current_win(win)
  vim.w.netrw_liststyle = 3
  vim.cmd("Explore " .. vim.fn.fnameescape(root))
  vim.wo.winfixwidth = true
  vim.bo.bufhidden = "wipe"
  route()
  reveal(file, root)
end

function M.open()
  require("autovim.sidebar").open("explorer")
end

function M.toggle()
  if M.is_open() then M.close() else M.open() end
end

function M.setup()
  vim.g.netrw_banner = 0
  vim.g.netrw_liststyle = 3
  vim.g.netrw_keepdir = 1
  vim.g.netrw_browse_split = 0
  vim.g.netrw_chgwin = -1
  -- netrw's supported user-map hook survives its buffer refreshes. This tiny
  -- Vimscript bridge exports an action; all Lua state remains module-local.
  vim.cmd([[
    function! AutoVimNetrwSelect(islocal) abort
      lua require("autovim.explorer").select()
      return ''
    endfunction
  ]])
  local maps = {}
  for _, entry in ipairs(vim.g.Netrw_UserMaps or {}) do
    if entry[1] ~= "<CR>" then maps[#maps + 1] = entry end
  end
  maps[#maps + 1] = { "<CR>", "AutoVimNetrwSelect" }
  vim.g.Netrw_UserMaps = maps
  local group = api.nvim_create_augroup("AutoVimExplorer", { clear = true })
  api.nvim_create_autocmd({ "WinEnter", "BufEnter" }, { group = group, callback = route })
  api.nvim_create_autocmd("TabClosed", { group = group, callback = function()
    for tab in pairs(tabs) do if not api.nvim_tabpage_is_valid(tab) then tabs[tab] = nil end end
  end })
end

return M
