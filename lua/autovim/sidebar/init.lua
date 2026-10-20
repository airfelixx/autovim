-- Layout scope: a narrow activity rail and one shared tool window per tab.
local M = {}
local api = vim.api
local tabs = {}
local width = 48 -- Minimum preferred panel width, capped for narrow terminals.
local rail_width, button_height = 5, 3
local busy = false
local tools = {
  { kind = "explorer", icon = "", key = "f", title = "FILES", module = "autovim.explorer" },
  { kind = "terminal", icon = ">_", key = "t", title = "TERMINAL", module = "autovim.terminal" },
  { kind = "undo", icon = "↶", key = "u", title = "UNDO HISTORY", module = "autovim.undo" },
  { kind = "harpoon", icon = "⚑", key = "h", title = "HARPOON", module = "autovim.harpoon" },
}

local function panel_width()
  return math.max(1, math.min(72, math.max(width, math.floor(vim.o.columns * 0.3)), math.floor(vim.o.columns * 0.45)))
end

local function tool_at(row)
  return tools[math.floor((row - 1) / button_height) + 1]
end

local function state()
  local tab = api.nvim_get_current_tabpage()
  tabs[tab] = tabs[tab] or {}
  return tabs[tab]
end

local function valid(win)
  return win and api.nvim_win_is_valid(win) and api.nvim_win_get_tabpage(win) == api.nvim_get_current_tabpage()
end

function M.is_tool(win)
  local s = state()
  return win == s.rail or win == s.panel
end

function M.kind()
  local s = state()
  return valid(s.panel) and s.kind or nil
end

local function editor(s)
  if valid(s.editor) and not M.is_tool(s.editor) then return s.editor end
  for _, win in ipairs(api.nvim_tabpage_list_wins(0)) do
    if not M.is_tool(win) and api.nvim_win_get_config(win).relative == "" then
      s.editor = win
      return win
    end
  end
end

function M.editor()
  return editor(state())
end

function M.focus_editor()
  local win = M.editor()
  if win then api.nvim_set_current_win(win) end
end

local function paint(s)
  if not valid(s.rail) then return end
  local buf = api.nvim_win_get_buf(s.rail)
  api.nvim_buf_clear_namespace(buf, -1, 0, -1)
  for index, tool in ipairs(tools) do
    for row = (index - 1) * button_height, index * button_height - 1 do
      api.nvim_buf_add_highlight(buf, -1, s.kind == tool.kind and valid(s.panel) and "AVRailActive" or "AVRailMuted", row, 0, -1)
    end
  end
end

function M.resize()
  for _, s in pairs(tabs) do
    if s.rail and api.nvim_win_is_valid(s.rail) then pcall(api.nvim_win_set_width, s.rail, rail_width) end
    if s.panel and api.nvim_win_is_valid(s.panel) then pcall(api.nvim_win_set_width, s.panel, panel_width()) end
  end
end

function M.ensure()
  if busy or vim.bo.filetype == "autovim" or require("autovim.explorer.picker").active() then return end
  if api.nvim_win_get_config(0).relative ~= "" then return end
  local s = state()
  if valid(s.rail) then return end
  local origin = editor(s)
  if not origin then return end
  busy = true
  vim.cmd("topleft " .. rail_width .. "vnew")
  s.rail = api.nvim_get_current_win()
  local buf = api.nvim_get_current_buf()
  vim.bo[buf].buftype, vim.bo[buf].bufhidden = "nofile", "wipe"
  vim.bo[buf].buflisted, vim.bo[buf].swapfile, vim.bo[buf].filetype = false, false, "autovim_rail"
  local lines = {}
  for _, tool in ipairs(tools) do
    local padding = math.floor((rail_width - vim.fn.strdisplaywidth(tool.icon)) / 2)
    lines[#lines + 1] = string.rep(" ", rail_width)
    lines[#lines + 1] = string.rep(" ", padding) .. tool.icon .. string.rep(" ", rail_width - padding - vim.fn.strdisplaywidth(tool.icon))
    lines[#lines + 1] = string.rep(" ", rail_width)
  end
  api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  local wo = vim.wo[s.rail]
  wo.number, wo.relativenumber, wo.wrap, wo.cursorline = false, false, false, false
  wo.signcolumn, wo.foldcolumn, wo.winbar = "no", "0", ""
  wo.winfixwidth = true
  wo.fillchars = "eob: "
  wo.winhighlight = "Normal:AVRail,NormalNC:AVRail,EndOfBuffer:AVRail,WinSeparator:AVRail"
  local function select()
    local tool = tool_at(api.nvim_win_get_cursor(s.rail)[1])
    if tool then M.toggle(tool.kind) end
  end
  vim.keymap.set("n", "<CR>", select, { buffer = buf, silent = true })
  for _, tool in ipairs(tools) do
    vim.keymap.set("n", tool.key, function() M.toggle(tool.kind) end, { buffer = buf, silent = true })
  end
  for key, direction in pairs({ j = 1, ['<Down>'] = 1, k = -1, ['<Up>'] = -1 }) do
    vim.keymap.set("n", key, function()
      local index = math.floor((api.nvim_win_get_cursor(s.rail)[1] - 1) / button_height) + 1
      index = math.max(1, math.min(#tools, index + direction))
      api.nvim_win_set_cursor(s.rail, { (index - 1) * button_height + 2, 0 })
    end, { buffer = buf, silent = true })
  end
  vim.keymap.set("n", "<LeftMouse>", function()
    local mouse = vim.fn.getmousepos()
    if mouse.winid == s.rail and tool_at(mouse.line) then
      M.toggle(tool_at(mouse.line).kind)
    elseif valid(mouse.winid) then api.nvim_set_current_win(mouse.winid) end
  end, { buffer = buf, silent = true })
  paint(s)
  api.nvim_set_current_win(origin)
  busy = false
end

function M.close(kind)
  local s = state()
  if kind and s.kind ~= kind then return end
  if s.kind == "undo" then require("autovim.undo").unmount() end
  local win = s.panel
  s.kind, s.panel = nil, nil
  if valid(win) then
    local target = editor(s)
    if target then api.nvim_set_current_win(target) end
    if #api.nvim_tabpage_list_wins(0) > 1 then api.nvim_win_close(win, false) end
  end
  paint(s)
end

function M.hide()
  busy = true
  M.close()
  local s = state()
  local rail = s.rail
  s.rail = nil
  if valid(rail) and #api.nvim_tabpage_list_wins(0) > 1 then api.nvim_win_close(rail, false) end
  busy = false
end

function M.open(kind)
  if require("autovim.explorer.picker").active() then return end
  local tool
  for _, candidate in ipairs(tools) do if candidate.kind == kind then tool = candidate; break end end
  if not tool then return end
  local directory = require("autovim.workspace").directory()
  if kind == "explorer" and vim.fn.isdirectory(directory) ~= 1 then
    vim.notify("Directory no longer exists: " .. directory, vim.log.levels.WARN)
    return
  end
  local s = state()
  if s.kind == kind and valid(s.panel) then api.nvim_set_current_win(s.panel); return end
  local target = editor(s)
  if not target then return end
  api.nvim_set_current_win(target)
  if vim.bo.filetype == "autovim" or vim.bo.filetype == "netrw" then vim.cmd("hide enew") end
  M.ensure()
  busy = true
  if s.kind == "undo" then require("autovim.undo").unmount() end
  if not valid(s.panel) then
    api.nvim_set_current_win(target)
    vim.cmd("leftabove " .. panel_width() .. "vnew")
    s.panel = api.nvim_get_current_win()
  else
    api.nvim_set_current_win(s.panel)
    -- Hide the terminal before netrw opens a directory in this same window.
    local scratch = api.nvim_create_buf(false, true)
    vim.bo[scratch].bufhidden = "wipe"
    api.nvim_win_set_buf(s.panel, scratch)
  end
  s.kind = kind
  vim.wo.winfixwidth = true
  vim.wo.winbar = "%#AVBarMuted# " .. tool.title
  local ok, err = pcall(function()
    require(tool.module).mount(s.panel, target)
  end)
  busy = false
  paint(s)
  if not ok then vim.notify("Could not open sidebar: " .. tostring(err), vim.log.levels.ERROR) end
end

function M.toggle(kind)
  if M.kind() == kind then M.close() else M.open(kind) end
end

function M.setup()
  local group = api.nvim_create_augroup("AutoVimSidebar", { clear = true })
  api.nvim_create_autocmd("VimResized", { group = group, callback = M.resize })
  api.nvim_create_autocmd({ "BufEnter", "WinEnter", "TabEnter" }, { group = group, callback = function()
    if busy then return end
    local s, win = state(), api.nvim_get_current_win()
    if api.nvim_win_get_config(win).relative == "" and not M.is_tool(win) then s.editor = win end
    vim.schedule(M.ensure)
  end })
  api.nvim_create_autocmd("WinClosed", { group = group, callback = function()
    vim.schedule(function() if not busy then paint(state()) end end)
  end })
end

return M
