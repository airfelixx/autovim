-- Editor chrome. Rendering returns statusline syntax, never executes a filename.
local M = {}
local api = vim.api

local function escape(text)
  return text:gsub("[\r\n]", " "):gsub("%%", "%%%%")
end

local function colours()
  local definitions = {
    AVBar = { fg = "#d4dfe5", bg = "#19232e" },
    AVBarMuted = { fg = "#91a4b2", bg = "#19232e" },
    AVBarAccent = { fg = "#10151c", bg = "#79d9cf", bold = true },
    AVBarWarn = { fg = "#e8b779", bg = "#19232e" },
    AVRail = { fg = "#7e929f", bg = "#10151c" },
    AVRailMuted = { fg = "#7e929f", bg = "#10151c" },
    AVRailActive = { fg = "#79d9cf", bg = "#192a32", bold = true },
    AVTabActive = { fg = "#79d9cf", bg = "#29404b", bold = true },
    AVTab = { fg = "#91a4b2", bg = "#19232e" },
    TabLineFill = { bg = "#19232e" },
    StatusLine = { fg = "#d4dfe5", bg = "#19232e" },
  }
  for name, value in pairs(definitions) do api.nvim_set_hl(0, name, value) end
end

function M.topline()
  local text = "%#AVBarAccent#  AutoVim  %#AVBarMuted# │ %<"
  local pins = require("autovim.harpoon").items()
  local duplicates = {}
  for _, item in ipairs(pins) do
    local name = vim.fs.basename(item.path)
    duplicates[name] = (duplicates[name] or 0) + 1
  end
  local current = require("autovim.workspace").file()
  for _, item in ipairs(pins) do
    local name = vim.fs.basename(item.path)
    if duplicates[name] > 1 then name = vim.fs.basename(vim.fs.dirname(item.path)) .. "/" .. name end
    text = text .. (item.path == current and "%#AVTabActive#" or "%#AVTab#")
      .. "%" .. item.index .. "@v:lua.AutoVimHarpoonSelect@ " .. item.number .. " " .. escape(name) .. " %X"
  end
  return text .. "%#AVBarMuted#%="
end

function M.statusline()
  local sidebar = require("autovim.sidebar")
  local win = api.nvim_get_current_win()
  if sidebar.is_tool(win) then win = sidebar.editor() or win end
  local buf = api.nvim_win_get_buf(win)
  local name, bo = api.nvim_buf_get_name(buf), vim.bo[buf]
  local root = require("autovim.workspace").root()
  local file = bo.buftype == "" and bo.filetype ~= "netrw" and name ~= "" and vim.fn.isdirectory(name) ~= 1
  local path
  if file then
    local prefix = root and (root == "/" and "/" or root .. "/")
    path = prefix and name:sub(1, #prefix) == prefix and name:sub(#prefix + 1) or vim.fn.fnamemodify(name, ":~")
  else path = root and (vim.fs.basename(root) or root) or "[No file]" end
  local modes = { n = "NORMAL", i = "INSERT", v = "VISUAL", V = "V-LINE", ["\022"] = "V-BLOCK", c = "COMMAND", t = "TERMINAL", R = "REPLACE" }
  local mode = vim.fn.mode():sub(1, 1)
  local text = "%#AVBarAccent# " .. (modes[mode] or "NORMAL") .. " %#AVBar# %<" .. escape(path)
  if bo.modified then text = text .. "%#AVBarWarn# [+]%#AVBar#" end
  if bo.readonly then text = text .. " [RO]" end
  text = text .. "%=%#AVBarMuted#"
  if file then
    local errors = #vim.diagnostic.get(buf, { severity = vim.diagnostic.severity.ERROR })
    local warnings = #vim.diagnostic.get(buf, { severity = vim.diagnostic.severity.WARN })
    if errors + warnings > 0 then text = text .. " E:" .. errors .. " W:" .. warnings .. "  " end
    if vim.o.columns >= 110 then
      local clients = vim.lsp.get_clients({ bufnr = buf })
      if #clients > 0 then
        local names = vim.tbl_map(function(client) return client.name end, clients)
        table.sort(names)
        text = text .. "LSP:" .. table.concat(names, ",") .. "  "
      end
    end
    local cursor = api.nvim_win_get_cursor(win)
    local percent = math.floor(cursor[1] / math.max(1, api.nvim_buf_line_count(buf)) * 100)
    text = text .. escape(bo.filetype ~= "" and bo.filetype or "text") .. "  "
    if vim.o.columns >= 90 then text = text .. escape(bo.fileencoding ~= "" and bo.fileencoding or vim.o.encoding) .. " · " .. bo.fileformat .. "  " end
    text = text .. cursor[1] .. ":" .. (cursor[2] + 1) .. "  " .. percent .. "%% "
  else text = text .. (root and "WORKSPACE " or "STANDALONE ") end
  return text
end

function M.setup()
  _G.AutoVimHarpoonSelect = function(index) require("autovim.harpoon").select(index) end
  vim.o.laststatus, vim.o.showtabline = 3, 2
  vim.o.showmode, vim.o.ruler = false, false
  vim.o.tabline = "%!v:lua.require'autovim.ui'.topline()"
  vim.o.statusline = "%!v:lua.require'autovim.ui'.statusline()"
  colours()
  local group = api.nvim_create_augroup("AutoVimUI", { clear = true })
  api.nvim_create_autocmd("ColorScheme", { group = group, callback = colours })
  api.nvim_create_autocmd({ "ModeChanged", "DiagnosticChanged", "BufModifiedSet", "DirChanged", "LspAttach", "LspDetach" }, {
    group = group, callback = function() vim.cmd("redrawstatus | redrawtabline") end,
  })
end

return M
