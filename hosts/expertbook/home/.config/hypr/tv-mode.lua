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

tv_panel_off = read("panel-off") ~= nil
if tv_panel_off then
  hl.monitor({ output = "eDP-1", disabled = true })
end

local active = read("active")
if active and not active:find('"dry": true', 1, true) then
  hl.config({ cursor = { inactive_timeout = 3 } })
end
