dofile("/usr/share/sddm/hyprland.lua")

local function desktop(name)
  local f = io.open("/var/lib/expertbook-tweaks/greeter-" .. name)
  if not f then return nil end
  local value = tonumber(f:read("l") or "")
  f:close()
  return value
end

pcall(function()
  hl.monitor({
    output = "eDP-1", mode = "preferred", position = "auto", scale = desktop("scale") or "auto",
    bitdepth = 10, cm = "hdr",
    sdr_max_luminance = math.floor(math.max(8, math.min(600, desktop("nits") or 200)) + 0.5),
    sdr_min_luminance = 0,
  })
end)
