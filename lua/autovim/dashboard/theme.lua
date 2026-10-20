local M = {}
local api = vim.api
local settings = require("autovim.dashboard.config")

local function mix(a, b, amount)
  local out = "#"
  for i = 2, 6, 2 do
    local x, y = tonumber(a:sub(i, i + 1), 16), tonumber(b:sub(i, i + 1), 16)
    out = out .. string.format("%02x", math.floor(x + (y - x) * amount + 0.5))
  end
  return out
end

local function colours()
  local definitions = {
    AVNormal = { fg = settings.foreground, bg = settings.background },
    AVTitle = { fg = settings.eye, bg = settings.background, bold = true },
    AVText = { fg = settings.foreground, bg = settings.background },
    AVMuted = { fg = "#7e929f", bg = settings.background },
    AVFaint = { fg = "#3a4b59", bg = settings.background },
    AVSelected = { fg = settings.eye, bg = "#192a32", bold = true },
    AVDisabled = { fg = "#627481", bg = settings.background },
    AVTrack = { fg = "#354a59", bg = settings.background },
    AVGear = { fg = settings.gear, bg = settings.background },
  }
  for name, value in pairs(definitions) do api.nvim_set_hl(0, name, value) end
  for level = 1, 10 do
    for name, colour in pairs({ Eye = settings.eye, Gear = settings.gear }) do
      api.nvim_set_hl(0, "AV" .. name .. level, {
        fg = mix(settings.background, colour, 0.22 + 0.078 * level),
        bg = settings.background,
      })
    end
  end
end
function M.setup(group)
  colours()
  api.nvim_create_autocmd("ColorScheme", { group = group, callback = colours })
end

return M
