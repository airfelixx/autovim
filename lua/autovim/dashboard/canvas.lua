-- Drawing primitives use braille: 2 x 4 dots per terminal character.
-- Only functions on M are public; local helpers stay private to this module.
local M = {}

local dot_bits = { { 1, 8 }, { 2, 16 }, { 4, 32 }, { 64, 128 } }
local bitlib = require("bit") -- LuaJIT's built-in bit operations.
function M.new(width, height)
  local cells = {}
  local function dot(x, y, colour, erase)
    x, y = math.floor(x + 0.5), math.floor(y + 0.5)
    if x < 0 or y < 0 or x >= width * 2 or y >= height * 4 then return end
    local row, col = math.floor(y / 4) + 1, math.floor(x / 2) + 1
    cells[row] = cells[row] or {}
    local cell = cells[row][col] or { bits = 0 }
    local bit = dot_bits[y % 4 + 1][x % 2 + 1]
    if erase then
      cell.bits = bitlib.band(cell.bits, bitlib.bnot(bit))
    else
      cell.bits = bitlib.bor(cell.bits, bit)
      cell.colour = colour
    end
    cells[row][col] = cell
  end
  local function line(x1, y1, x2, y2, colour)
    local steps = math.max(1, math.ceil(math.max(math.abs(x2 - x1), math.abs(y2 - y1)) * 1.8))
    for i = 0, steps do
      local t = i / steps
      dot(x1 + (x2 - x1) * t, y1 + (y2 - y1) * t, colour)
    end
  end
  local function circle(x, y, radius, colour)
    local steps = math.max(24, math.ceil(radius * 10))
    for i = 0, steps do
      local angle = i / steps * math.pi * 2
      dot(x + radius * math.cos(angle), y + radius * math.sin(angle), colour)
    end
  end
  return { cells = cells, dot = dot, line = line, circle = circle }
end

function M.eye(c, x, y, r, blink, colour)
  local opening = 1 - 0.94 * blink
  for i = 0, 160 do
    local u = -1 + i / 80
    local curve = (1 - u * u) * r * 0.49 * opening
    c.dot(x + u * r, y - curve, colour)
    c.dot(x + u * r, y + curve, colour)
  end
  if opening > 0.25 then
    -- Clip the iris and pupil to the closing eyelids.
    for py = -math.ceil(r * 0.40), math.ceil(r * 0.40) do
      for px = -math.ceil(r * 0.40), math.ceil(r * 0.40) do
        local d = math.sqrt(px * px + py * py)
        local lid = (1 - (px / r) ^ 2) * r * 0.49 * opening
        if math.abs(py) < lid - 0.6 and
          (math.abs(d - r * 0.34) < 0.65 or d < r * 0.13) then
          c.dot(x + px, y + py, colour)
        end
      end
    end
    c.dot(x - r * 0.12, y - r * 0.13, colour)
  end
  -- Short corner accents give the eye a sensor-like silhouette.
  c.line(x - r * 1.14, y, x - r * 1.05, y, colour)
  c.line(x + r * 1.05, y, x + r * 1.14, y, colour)
end

function M.gear(c, x, y, r, angle, colour)
  -- Eight teeth, with a real outline and a hollow hub.
  local points = {}
  for tooth = 0, 7 do
    for _, corner in ipairs({ { 0.00, 0.77 }, { 0.16, 0.77 }, { 0.23, 1.0 },
      { 0.64, 1.0 }, { 0.71, 0.77 }, { 1.00, 0.77 } }) do
      local a = angle + (tooth + corner[1]) * math.pi / 4
      points[#points + 1] = { x + r * corner[2] * math.cos(a), y + r * corner[2] * math.sin(a) }
    end
  end
  for i, p in ipairs(points) do
    local q = points[i % #points + 1]
    c.line(p[1], p[2], q[1], q[2], colour)
  end
  c.circle(x, y, r * 0.31, colour)
  c.circle(x, y, r * 0.46, colour)
  for i = 0, 3 do
    local a = angle + i * math.pi / 2
    c.line(x + r * 0.48 * math.cos(a), y + r * 0.48 * math.sin(a),
      x + r * 0.69 * math.cos(a), y + r * 0.69 * math.sin(a), colour)
  end
end

return M
