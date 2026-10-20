-- Dashboard controller: owns the buffer, window, local state, and timer.
local M = {}
local api, uv = vim.api, vim.uv
local settings = require("autovim.dashboard.config")
local view = require("autovim.dashboard.view")
local animation = require("autovim.dashboard.animation")
local theme = require("autovim.dashboard.theme")
local menus = settings.menu
local config_path = vim.fn.stdpath("config") .. "/init.lua"
local state = { selected = 1, paused = false, elapsed = 0, spin = 0 }
local group

local function render()
  view.render(state)
end

local function stop_timer()
  if state.timer then
    state.timer:stop()
    state.timer:close()
    state.timer = nil
  end
end

local function restore()
  stop_timer()
  if state.leave_autocmd then
    pcall(api.nvim_del_autocmd, state.leave_autocmd)
    state.leave_autocmd = nil
  end
  if not state.saved then return end
  for name, value in pairs(state.saved.global) do vim.o[name] = value end
  if state.win and api.nvim_win_is_valid(state.win) then
    for name, value in pairs(state.saved.window) do vim.wo[state.win][name] = value end
  end
  state.saved = nil
end

-- Menu actions are named in config.lua, so their order can change safely.
local function activate(index)
  local menu = menus[index]
  if menu.disabled then return end
  if menu.action == "files" then
    require("autovim.workspace").pick()
  elseif menu.action == "config" then
    restore()
    vim.cmd("edit " .. vim.fn.fnameescape(config_path))
  end
end

local function configure_window()
  state.saved = { global = {}, window = {} }
  for _, name in ipairs({ "laststatus", "showtabline", "showmode", "ruler", "guicursor" }) do
    state.saved.global[name] = vim.o[name]
  end
  for _, name in ipairs({ "number", "relativenumber", "signcolumn", "foldcolumn", "wrap", "list", "spell", "cursorline", "cursorcolumn", "colorcolumn", "winhighlight", "fillchars", "scrolloff" }) do
    state.saved.window[name] = vim.wo[state.win][name]
  end
  vim.o.laststatus, vim.o.showtabline, vim.o.showmode, vim.o.ruler = 0, 0, false, false
  vim.o.guicursor = "a:ver1-AVNormal"
  local wo = vim.wo[state.win]
  wo.number, wo.relativenumber, wo.wrap, wo.list, wo.spell = false, false, false, false, false
  wo.cursorline, wo.cursorcolumn, wo.scrolloff = false, false, 0
  wo.signcolumn, wo.foldcolumn, wo.colorcolumn = "no", "0", ""
  wo.winhighlight = "Normal:AVNormal,NormalNC:AVNormal,EndOfBuffer:AVNormal,Cursor:AVNormal"
  wo.fillchars = "eob: "
end

local function map_actions()
  local function map(keys, fn, description)
    vim.keymap.set("n", keys, fn, { buffer = state.buf, nowait = true, silent = true, desc = description })
  end
  local function move(direction)
    repeat state.selected = (state.selected - 1 + direction) % #menus + 1 until not menus[state.selected].disabled
    render()
  end
  for i, menu in ipairs(menus) do map(menu.key, function() activate(i) end, menu.label) end
  for _, key in ipairs({ "j", "<Down>", "<Tab>" }) do
    map(key, function() move(1) end, "Next action")
  end
  for _, key in ipairs({ "k", "<Up>", "<S-Tab>" }) do
    map(key, function() move(-1) end, "Previous action")
  end
  map("<CR>", function() activate(state.selected) end, "Open selected action")
  map("<leader><Space>", function() state.paused = not state.paused end, "Pause animation")
  map("q", function() vim.cmd("quit") end, "Quit")
  map("<LeftMouse>", function()
    local mouse = vim.fn.getmousepos()
    if mouse.winid ~= state.win or mouse.column < state.menu_col or mouse.column > state.menu_end then return end
    for i, row in ipairs(state.menu_rows) do
      if mouse.line == row or mouse.line == row + 1 then activate(i); return end
    end
  end, "Open clicked action")
end

local function start_timer()
  local last = uv.hrtime()
  local timer = uv.new_timer()
  state.timer = timer
  timer:start(settings.frame_ms, settings.frame_ms, vim.schedule_wrap(function()
    -- Ignore a callback queued by a previous visit to the menu.
    if state.timer ~= timer then return end
    if not api.nvim_buf_is_valid(state.buf) or api.nvim_get_current_buf() ~= state.buf then restore(); return end
    local now = uv.hrtime()
    local dt = math.min((now - last) / 1e9, 0.2)
    last = now
    if state.paused or vim.fn.mode() ~= "n" then return end
    local _, active = animation.motion(state.elapsed)
    if active == "gear" then state.spin = state.spin - dt * 1.35 end
    state.elapsed = state.elapsed + dt
    render()
  end))
end

-- Public functions belong to M. Helpers and state above stay module-local.
function M.open()
  if vim.fn.getcmdwintype() ~= "" then
    -- Command-history windows cannot switch buffers. First leave the
    -- history window and command line, then run the public command normally.
    local keys = api.nvim_replace_termcodes("<C-c><C-c>:AutoVim<CR>", true, false, true)
    api.nvim_feedkeys(keys, "n", false)
    return
  end
  require("autovim.explorer.picker").dismiss(false)
  require("autovim.sidebar").hide()
  if state.timer and api.nvim_get_current_buf() == state.buf then render(); return end
  restore()

  -- Reuse a visible dashboard (including one in another tab) instead of
  -- creating a second buffer with the same name.
  if state.buf and api.nvim_buf_is_valid(state.buf) then
    local windows = vim.fn.win_findbuf(state.buf)
    if #windows > 0 then vim.fn.win_gotoid(windows[1]) end
  else
    state.buf = api.nvim_create_buf(false, true)
    api.nvim_buf_set_name(state.buf, "AutoVim://welcome")
    vim.bo[state.buf].buftype, vim.bo[state.buf].bufhidden = "nofile", "wipe"
    vim.bo[state.buf].swapfile, vim.bo[state.buf].filetype = false, "autovim"
  end
  state.win = api.nvim_get_current_win()
  -- :hide preserves the previous buffer and its edits even with 'nohidden'.
  if api.nvim_get_current_buf() ~= state.buf then vim.cmd("hide buffer " .. state.buf) end
  state.selected, state.elapsed, state.spin, state.paused = 1, 0, 0, false
  configure_window()
  map_actions()
  state.leave_autocmd = api.nvim_create_autocmd({ "BufLeave", "BufWipeout", "WinLeave" }, {
    group = group, buffer = state.buf, callback = restore,
  })
  render()
  start_timer()
end

function M.setup()
  -- Running setup again replaces handlers and stops the previous timer.
  restore()
  group = api.nvim_create_augroup("AutoVim", { clear = true })
  theme.setup(group)
  api.nvim_create_autocmd("VimResized", { group = group, callback = function()
    if state.timer then render() end
  end })
  api.nvim_create_autocmd("VimLeavePre", { group = group, callback = restore })
  local stdin = false
  api.nvim_create_autocmd("StdinReadPre", { group = group, callback = function() stdin = true end })
  api.nvim_create_autocmd("VimEnter", { group = group, callback = function()
    if not stdin and not vim.bo.modified and vim.fn.argc() == 0 and vim.fn.line("$") == 1 and vim.fn.getline(1) == ""
      and vim.bo.buftype == "" and vim.v.this_session == "" and #api.nvim_list_uis() > 0 then
      vim.schedule(M.open)
    end
  end })
end

return M
