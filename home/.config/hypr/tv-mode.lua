-- TV mode's Hyprland half (bin/tv-mode does the rest). Loaded from
-- ~/.config/hypr/monitors.lua so it survives config reloads, and re-run by
-- tv-mode with `hyprctl eval 'dofile(...)'` whenever what it reads changes:
--   $XDG_RUNTIME_DIR/tv-mode/tv      "<connector> <mode>" while a 1080p TV is
--                                    connected: 1080p, scale 1, sRGB, 8 bit
--   $XDG_RUNTIME_DIR/tv-mode/active  while TV mode is on: hide the mouse
--                                    pointer after 3 s, it's a controller now
-- The laptop panel's off state is Omarchy's internal-monitor-disable toggle.
local dir = (os.getenv("XDG_RUNTIME_DIR") or "/tmp") .. "/tv-mode/"

local function read(name)
  local f = io.open(dir .. name)
  if not f then return nil end
  local s = f:read("a")
  f:close()
  return s
end

local tv = read("tv")
local name, mode = (tv or ""):match("^(%S+)%s+(%S+)")
if name then
  hl.monitor({ output = name, mode = mode, position = "auto", scale = 1, cm = "srgb", bitdepth = 8 })
end

local active = read("active")
if active and not active:find('"dry": true', 1, true) then
  hl.config({ cursor = { inactive_timeout = 3 } })
end
