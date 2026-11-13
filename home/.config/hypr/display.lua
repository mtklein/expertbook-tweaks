local home = os.getenv("HOME") or ""
local state = home .. "/.local/state/"
local SCALES = { 1.5, 1.6, 1.8, 2 }

local function read_number(path, fallback)
  local f = io.open(path)
  if not f then return fallback end
  local value = tonumber(f:read("l") or "")
  f:close()
  return value or fallback
end

local function write_number(path, value)
  local f = io.open(path, "w")
  if f then f:write(string.format("%g\n", value)); f:close() end
end

hl.env("GDK_SCALE", "2")
hl.env("QSG_DISTANCEFIELD_ANTIALIASING", "gray")
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 2 })

local edp_scale = read_number(state .. "edp-scale", 1.6)

edp_sdr_white = 600
edp_brightness_gamma = 2.2

local function saved_level()
  return read_number(state .. "hdr-brightness", 1.0)
end

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

function edp_cycle_scale()
  local following = SCALES[1]
  for i, scale in ipairs(SCALES) do
    if math.abs(scale - edp_scale) < 0.01 then following = SCALES[i % #SCALES + 1] end
  end
  edp_scale = following
  write_number(state .. "edp-scale", edp_scale)
  write_number("/var/lib/expertbook-tweaks/greeter-scale", edp_scale)
  edp_hdr_level(saved_level())
end

write_number(state .. "hdr-sdr-white", edp_sdr_white)
write_number(state .. "hdr-brightness-gamma", edp_brightness_gamma)
write_number("/var/lib/expertbook-tweaks/greeter-scale", edp_scale)
edp_hdr_level(saved_level())

dofile(home .. "/.config/hypr/tv-mode.lua")
