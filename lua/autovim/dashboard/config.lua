-- Settings belong to the dashboard scope; editor-wide options live in core.
local config = {
  greeting = "Welcome back, Félix. What shall we build today?",
  frame_ms = 65, -- Lower = smoother; higher = less work for your computer.
  hold_seconds = 2.6,
  travel_seconds = 2.2,
  background = "#10151c",
  foreground = "#dbe6ee",
  eye = "#79d9cf",
  gear = "#e8b779",
}

config.menu = {
  { key = "f", label = "Open files", action = "files", detail = "Browse to a file or directory" },
  { key = "w", label = "Container workspace", disabled = true },
  { key = "p", label = "PlatformIO project", disabled = true },
  { key = "c", label = "Open config", action = "config", detail = "Make AutoVim your own" },
}

return config
