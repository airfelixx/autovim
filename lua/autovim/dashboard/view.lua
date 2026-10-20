local M = {}
local api = vim.api
local settings = require("autovim.dashboard.config")
local menus = settings.menu
local animation = require("autovim.dashboard.animation")
local ns = api.nvim_create_namespace("autovim")

-- Rendering receives state explicitly; it does not own timers or commands.
local logo = {
  "   ▄▀█ █ █ ▀█▀ █▀█ █ █ █ █▀▄▀█",
  "   █▀█ █▄█  █  █▄█ ▀▄▀ █ █ ▀ █",
}
function M.render(state)
  if not state.buf or not api.nvim_buf_is_valid(state.buf) or
    not state.win or not api.nvim_win_is_valid(state.win) then return end
  local width, height = api.nvim_win_get_width(state.win), api.nvim_win_get_height(state.win)
  local rows, spans = {}, {}
  for y = 1, height do rows[y] = {}; for x = 1, width do rows[y][x] = { " ", "AVNormal" } end end
  local function put(row, col, text, hl)
    if row < 1 or row > height then return end
    for _, ch in ipairs(vim.fn.split(text, "\\zs")) do
      if col >= 1 and col <= width then rows[row][col] = { ch, hl or "AVText" } end
      col = col + 1
    end
  end
  local wide = width >= 105 and height >= 26
  local compact = height < 25 or width < 60
  local art_width = wide and math.floor(width * 0.49) or math.max(4, math.min(width - 4, 58))
  local art_height = wide and math.min(height - 8, 30)
    or (compact and math.max(0, math.min(5, height - 16)) or math.max(5, math.min(11, height - 23)))
  local art_row = wide and math.max(2, math.floor((height - art_height) / 2)) or 1
  local art_col = wide and 2 or math.max(1, math.floor((width - art_width) / 2))
  local cells = {}
  if art_height > 0 then cells = animation.draw(art_width, art_height, state) end
  for y, row in pairs(cells) do for x, cell in pairs(row) do
    if cell.bits ~= 0 then put(art_row + y - 1, art_col + x - 1, vim.fn.nr2char(0x2800 + cell.bits), cell.colour) end
  end end
  local menu_col = wide and (math.floor(width * 0.54) + 1) or math.max(2, math.floor((width - 48) / 2))
  local menu_width = math.min(48, width - menu_col - 1)
  state.menu_col, state.menu_end = menu_col, menu_col + menu_width - 1
  local top = wide and math.max(2, math.floor((height - 23) / 2)) or art_row + art_height + 1
  if wide then
    local divider = math.floor(width * 0.515)
    for y = top, math.min(height - 3, top + 23) do put(y, divider, "│", "AVFaint") end
  end
  if menu_width >= 32 and not compact then
    put(top, menu_col, logo[1], "AVTitle")
    put(top + 1, menu_col, logo[2], "AVTitle")
  else put(top, menu_col, "AutoVim", "AVTitle") end
  if menu_width >= vim.fn.strdisplaywidth(settings.greeting) then
    put(top + 4, menu_col, settings.greeting, "AVText")
  else
    put(top + 3, menu_col, "Welcome back, Félix.", "AVText")
    put(top + 4, menu_col, "What shall we build today?", "AVText")
  end
  state.menu_rows = {}
  for i, menu in ipairs(menus) do
    local row = top + (compact and 5 or 7) + (i - 1) * (compact and 2 or 3)
    local selected = i == state.selected
    local hl = menu.disabled and "AVDisabled" or (selected and "AVSelected" or "AVText")
    if selected then put(row, menu_col, string.rep(" ", menu_width), "AVSelected") end
    put(row, menu_col, (selected and "› " or "  ") .. "[" .. menu.key .. "]  " .. menu.label, hl)
    local detail = menu.disabled and "Coming soon" or menu.detail
    if not compact then put(row + 1, menu_col + 7, detail, menu.disabled and "AVFaint" or "AVMuted") end
    state.menu_rows[i] = row
  end
  if height >= 25 then
    local hint = "j/k navigate · enter open · space space pause · q quit"
    put(height - 1, math.max(2, math.floor((width - vim.fn.strdisplaywidth(hint)) / 2)), hint, "AVMuted")
  end
  local lines = {}
  for y, row in ipairs(rows) do
    local parts, byte, last_hl, start = {}, 0, nil, 0
    for _, cell in ipairs(row) do
      if cell[2] ~= last_hl then
        if last_hl then spans[#spans + 1] = { y - 1, start, byte, last_hl } end
        start, last_hl = byte, cell[2]
      end
      parts[#parts + 1], byte = cell[1], byte + #cell[1]
    end
    spans[#spans + 1] = { y - 1, start, byte, last_hl }
    lines[y] = table.concat(parts)
  end
  vim.bo[state.buf].modifiable = true
  api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)
  api.nvim_buf_clear_namespace(state.buf, ns, 0, -1)
  for _, span in ipairs(spans) do
    if span[4] ~= "AVNormal" then
      api.nvim_buf_add_highlight(state.buf, ns, span[4], span[1], span[2], span[3])
    end
  end
  vim.bo[state.buf].modifiable = false
  api.nvim_win_set_cursor(state.win, { math.min(height, state.menu_rows[state.selected]), math.min(width - 1, menu_col - 1) })
  -- Resizing must not leave the dashboard scrolled past its heading.
  api.nvim_win_call(state.win, function() vim.fn.winrestview({ topline = 1, leftcol = 0 }) end)
end

return M
