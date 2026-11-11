return function(omarchy_monitor_scale)

hl.env("QSG_DISTANCEFIELD_ANTIALIASING", "gray")

local home = os.getenv("HOME") or ""
local state = home .. "/.local/state/"

local function publish(name, value)
  local f = io.open(state .. name, "w")
  if f then f:write(string.format("%g\n", value)); f:close() end
end

local function saved_level()
  local f = io.open(state .. "hdr-brightness")
  if not f then return 1.0 end
  local level = tonumber(f:read("l") or "")
  f:close()
  return level or 1.0
end

local function scale_omarchy_set_for_edp()
  local scale = omarchy_monitor_scale
  local f = io.open(home .. "/.config/hypr/monitors.lua")
  if f then
    for line in f:lines() do
      if not line:match("^%s*%-%-") and line:match('output%s*=%s*"eDP%-1"') then
        scale = tonumber(line:match("scale%s*=%s*([%d%.]+)")) or scale
      end
    end
    f:close()
  end
  return scale
end

local edp_scale = scale_omarchy_set_for_edp()

local greeter_scale = io.open("/var/lib/expertbook-tweaks/greeter-scale", "w")
if greeter_scale then greeter_scale:write(string.format("%g\n", edp_scale)); greeter_scale:close() end

edp_sdr_white = 600
edp_brightness_gamma = 2.2

function edp_hdr_level(level)
  local nits = edp_sdr_white * level ^ edp_brightness_gamma
  local whole_nits, remainder
  if level <= 0 then
    whole_nits, remainder = 1, 0.0001
  else
    whole_nits = math.max(1, math.ceil(nits - 1e-6))
    remainder = math.max(0.0001, math.min(1, nits / whole_nits))
  end
  hl.monitor({
    output = "eDP-1", mode = "preferred", position = "auto", scale = edp_scale,
    bitdepth = 10, cm = "hdr",
    sdr_max_luminance = whole_nits,
    sdrbrightness = remainder,
    sdr_min_luminance = 0,
  })
end

publish("hdr-sdr-white", edp_sdr_white)
publish("hdr-brightness-gamma", edp_brightness_gamma)
edp_hdr_level(saved_level())

end
