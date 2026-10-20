-- Harpoon owns persistence; AutoVim owns its sidebar and tabline presentation.
local M = {}
local api = vim.api
local panels = {}

local function root()
  return require("autovim.workspace").directory()
end

local function plugin()
  return require("harpoon")
end

local function list()
  return plugin():list(root())
end

function M.items()
  if not package.loaded.harpoon then return {} end
  local value, out = list(), {}
  for index = 1, value:length() do
    local item = value:get(index)
    if item then out[#out + 1] = { index = index, number = #out + 1, path = item.value } end
  end
  return out
end

local function render(win)
  if not api.nvim_win_is_valid(win) then panels[win] = nil; return end
  local buf = api.nvim_win_get_buf(win)
  if vim.bo[buf].filetype ~= "autovim_harpoon" then panels[win] = nil; return end
  local lines, indices = { "  × Clear Harpoon list", "" }, {}
  local prefix = root() == "/" and "/" or root() .. "/"
  for _, item in ipairs(M.items()) do
    local label = item.path:sub(1, #prefix) == prefix and item.path:sub(#prefix + 1) or vim.fn.fnamemodify(item.path, ":~")
    lines[#lines + 1] = "  " .. item.number .. ". " .. label:gsub("[\r\n]", " ")
    indices[#lines] = item.index
  end
  if #lines == 2 then lines[3] = "  No pinned files yet" end
  local row = api.nvim_win_get_cursor(win)[1]
  vim.bo[buf].modifiable = true
  api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  api.nvim_buf_clear_namespace(buf, -1, 0, -1)
  api.nvim_buf_add_highlight(buf, -1, "AVGear", 0, 0, -1)
  api.nvim_win_set_cursor(win, { math.min(row, #lines), 0 })
  panels[win] = indices
end

function M.refresh()
  vim.cmd("redrawtabline")
  for win in pairs(panels) do
    if not api.nvim_win_is_valid(win) then panels[win] = nil
    elseif api.nvim_win_get_tabpage(win) == api.nvim_get_current_tabpage() then render(win) end
  end
end

function M.configure()
  plugin():setup({
    -- One persisted collection with a named list per workspace. Harpoon's
    -- data object is loaded once, so changing its storage key with cwd would
    -- otherwise miss lists from workspaces opened later in the same process.
    settings = { key = function() return "autovim" end },
    default = {
      get_root_dir = root,
      -- Absolute paths stay valid when a standalone file changes its cwd.
      create_list_item = function(_, name)
        local path = name or api.nvim_buf_get_name(0)
        return { value = vim.fn.fnamemodify(path, ":p"), context = { row = api.nvim_win_get_cursor(0)[1], col = api.nvim_win_get_cursor(0)[2] } }
      end,
      BufLeave = function(event, value)
        local path = api.nvim_buf_get_name(event.buf)
        local item = value:get_by_value(path)
        if item then
          item.context = { row = api.nvim_win_get_cursor(0)[1], col = api.nvim_win_get_cursor(0)[2] }
          plugin():sync()
        end
      end,
      select = function(item)
        if not item then return end
        require("autovim.workspace").open_file(item.value, false)
        local cursor = item.context or {}
        local row = math.min(cursor.row or 1, api.nvim_buf_line_count(0))
        local line = api.nvim_buf_get_lines(0, row - 1, row, false)[1] or ""
        api.nvim_win_set_cursor(0, { row, math.min(cursor.col or 0, #line) })
      end,
    },
  })
  local function changed() vim.schedule(M.refresh) end
  plugin():extend({ ADD = changed, REMOVE = changed, REORDER = changed, LIST_CHANGE = changed })
  local group = api.nvim_create_augroup("AutoVimHarpoon", { clear = true })
  api.nvim_create_autocmd({ "DirChanged", "TabEnter", "BufEnter" }, { group = group, callback = changed })
  changed()
end

function M.add()
  local sidebar = require("autovim.sidebar")
  local win = sidebar.is_tool(api.nvim_get_current_win()) and sidebar.editor() or api.nvim_get_current_win()
  if not win then return end
  local buf = api.nvim_win_get_buf(win)
  local path = api.nvim_buf_get_name(buf)
  if vim.bo[buf].buftype ~= "" or path == "" or vim.fn.isdirectory(path) == 1 then
    vim.notify("Open a file before adding it to Harpoon", vim.log.levels.INFO)
    return
  end
  api.nvim_win_call(win, function() list():add() end)
  M.refresh()
end

function M.select(index)
  local value = list()
  require("autovim.sidebar").focus_editor()
  value:select(index)
end

function M.select_number(number)
  list() -- Load saved entries even if this shortcut is the first Harpoon action.
  local item = M.items()[number]
  if item then M.select(item.index) end
end

function M.clear()
  list():clear()
  plugin():sync() -- Harpoon's clear() does not emit its usual change event.
  M.refresh()
end

function M.mount(win)
  plugin() -- Lazy-load and configure Harpoon before creating the panel.
  local buf = api.nvim_create_buf(false, true)
  vim.bo[buf].filetype, vim.bo[buf].bufhidden = "autovim_harpoon", "wipe"
  api.nvim_win_set_buf(win, buf)
  api.nvim_set_current_win(win)
  vim.wo.number, vim.wo.relativenumber, vim.wo.cursorline = false, false, true
  vim.wo.signcolumn, vim.wo.wrap = "no", false
  local function select()
    local row = api.nvim_win_get_cursor(win)[1]
    if row == 1 then M.clear()
    elseif panels[win] and panels[win][row] then M.select(panels[win][row]) end
  end
  vim.keymap.set("n", "<CR>", select, { buffer = buf, silent = true })
  vim.keymap.set("n", "d", function()
    local index = panels[win] and panels[win][api.nvim_win_get_cursor(win)[1]]
    if index then list():remove_at(index); M.refresh() end
  end, { buffer = buf, silent = true, desc = "Remove this Harpoon entry" })
  for _, key in ipairs({ "q", "<Esc>" }) do
    vim.keymap.set("n", key, function() require("autovim.sidebar").close() end, { buffer = buf, silent = true })
  end
  vim.keymap.set("n", "<LeftMouse>", function()
    local mouse = vim.fn.getmousepos()
    if mouse.winid == win and mouse.line >= 1 and mouse.line <= api.nvim_buf_line_count(buf) then
      api.nvim_win_set_cursor(win, { mouse.line, 0 })
      select()
    elseif api.nvim_win_is_valid(mouse.winid) then api.nvim_set_current_win(mouse.winid) end
  end, { buffer = buf, silent = true })
  render(win)
end

return M
