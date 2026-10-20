local M = {}
local settings = require("autovim.dashboard.config")
local canvas = require("autovim.dashboard.canvas")

-- The angle always increases: both exchanges travel anticlockwise.
function M.motion(seconds)
  local hold, travel = settings.hold_seconds, settings.travel_seconds
  local t = seconds % (2 * (hold + travel))
  local theta, active
  local function ease(v) return v * v * (3 - 2 * v) end
  if t < hold then theta, active = 0, "eye"
  elseif t < hold + travel then theta = math.pi * ease((t - hold) / travel)
  elseif t < 2 * hold + travel then theta, active = math.pi, "gear"
  else theta = math.pi * (1 + ease((t - 2 * hold - travel) / travel)) end
  return theta, active, t
end

function M.draw(width, height, state)
  local c = canvas.new(width, height)
  local theta, active, phase = M.motion(state.elapsed)
  local cx, cy = width - 1, height * 2 - 1
  local rx, ry = width * 0.49, height * 0.90
  local function orbit(a)
    -- Tilt the ellipse so foreground sits low and left, background high/right.
    return cx + rx * math.sin(a) - width * 0.22 * math.cos(a), cy + ry * math.cos(a)
  end
  local previous
  for i = 0, 220 do
    local a = i / 220 * math.pi * 2
    local x, y = orbit(a)
    if previous and i % 9 < 6 then c.line(previous[1], previous[2], x, y, "AVTrack") end
    previous = { x, y }
  end
  -- Two arrowheads keep the closed loop legible while the objects are still.
  for _, a in ipairs({ math.pi / 2, math.pi * 1.5 }) do
    local x, y = orbit(a)
    local px, py = orbit(a - 0.08)
    local dx, dy = x - px, y - py
    local length = math.sqrt(dx * dx + dy * dy)
    dx, dy = dx / length, dy / length
    c.line(x, y, x - dx * 3 - dy * 2, y - dy * 3 + dx * 2, "AVTrack")
    c.line(x, y, x - dx * 3 + dy * 2, y - dy * 3 - dx * 2, "AVTrack")
  end
  local objects = {}
  for i, kind in ipairs({ "eye", "gear" }) do
    local a = theta + (i - 1) * math.pi
    local x, y = orbit(a)
    local depth = (math.cos(a) + 1) / 2
    local radius = math.min(width * 0.28, height * 0.61) * (0.49 + 0.51 * depth)
    objects[#objects + 1] = { kind = kind, x = x, y = y, r = radius, depth = depth }
  end
  table.sort(objects, function(a, b) return a.depth < b.depth end)
  for _, object in ipairs(objects) do
    local o = object
    -- Erase track dots behind the silhouette before painting the object.
    for y = math.floor(o.y - o.r - 2), math.ceil(o.y + o.r + 2) do
      for x = math.floor(o.x - o.r * 1.2), math.ceil(o.x + o.r * 1.2) do
        if ((x - o.x) / (o.r * 1.2)) ^ 2 + ((y - o.y) / (o.r + 2)) ^ 2 < 1 then
          c.dot(x, y, nil, true)
        end
      end
    end
    local level = math.floor(1 + o.depth * 9)
    local colour = "AV" .. (o.kind == "eye" and "Eye" or "Gear") .. level
    if o.kind == "eye" then
      local blink = 0
      if active == "eye" then
        -- Two quick blinks during the acquisition hold, then rest.
        for _, centre in ipairs({ 0.75, 1.95 }) do
          blink = math.max(blink, math.max(0, 1 - math.abs(phase - centre) / 0.16))
        end
      end
      canvas.eye(c, o.x, o.y, o.r, blink, colour)
    else canvas.gear(c, o.x, o.y, o.r, state.spin, colour) end
  end
  return c.cells, active
end

return M
