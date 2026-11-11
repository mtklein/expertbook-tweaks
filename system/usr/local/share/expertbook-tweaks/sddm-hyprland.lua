dofile("/usr/share/sddm/hyprland.lua")

local function desktop_white_nits()
  local f = io.open("/var/lib/expertbook-tweaks/greeter-nits")
  if not f then return 200 end
  local nits = tonumber(f:read("l") or "")
  f:close()
  return nits or 200
end

pcall(function()
  hl.monitor({
    output = "eDP-1", mode = "preferred", position = "auto",
    bitdepth = 10, cm = "hdr",
    sdr_max_luminance = math.floor(math.max(8, math.min(600, desktop_white_nits())) + 0.5),
    sdr_min_luminance = 0,
  })
end)
