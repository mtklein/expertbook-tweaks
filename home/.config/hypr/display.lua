local home = os.getenv("HOME") or ""
local state = home .. "/.local/state/"
local SCALES = { 1, 1.5, 1.8, 2 }

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

local edp_scale = read_number(state .. "edp-scale", 1.8)
local override_file = (os.getenv("XDG_RUNTIME_DIR") or "/tmp") .. "/edp-scale-override"
local edp_override = read_number(override_file, nil)

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
    output = "eDP-1", mode = "preferred", position = "auto", scale = edp_override or edp_scale,
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
  edp_override = nil
  os.remove(override_file)
  write_number(state .. "edp-scale", edp_scale)
  edp_hdr_level(saved_level())
  hl.exec_cmd(string.format("qs ipc call osd pop scale -1 '%gx'", edp_scale))
end

function edp_override_scale(scale)
  edp_override = scale
  if scale then write_number(override_file, scale) else os.remove(override_file) end
  edp_hdr_level(saved_level())
end

write_number(state .. "hdr-sdr-white", edp_sdr_white)
write_number(state .. "hdr-brightness-gamma", edp_brightness_gamma)
edp_hdr_level(saved_level())

dofile(home .. "/.config/hypr/tv-mode.lua")

local function external()
  local ok, monitors = pcall(hl.get_monitors)
  for _, monitor in ipairs(ok and monitors or {}) do
    if monitor.name ~= "eDP-1" then return true end
  end
  return false
end

local function lid_closed()
  local pipe = io.popen("cat /proc/acpi/button/lid/*/state 2>/dev/null")
  local text = pipe and pipe:read("a") or ""
  if pipe then pipe:close() end
  return text:find("closed", 1, true) ~= nil
end

function edp_lid(closed)
  if closed and external() then
    hl.monitor({ output = "eDP-1", disabled = true })
  elseif not tv_panel_off then
    hl.monitor({ output = "eDP-1", disabled = false })
    edp_hdr_level(saved_level())
  end
end

if lid_closed() and external() then edp_lid(true) end

hl.on("monitor.removed", function()
  if not external() then edp_lid(false) end
end)
