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

local function hdr_frame_average(blocks)
  local i = 1
  while i <= #blocks do
    local header = blocks:byte(i)
    local tag, length = math.floor(header / 32), header % 32
    if tag == 7 and length >= 5 and blocks:byte(i + 1) == 6 and blocks:byte(i + 5) > 0 then
      return 50 * 2 ^ (blocks:byte(i + 5) / 32)
    end
    i = i + 1 + length
  end
end

local function edid_full_screen_nits()
  local edid
  for card = 0, 3 do
    local f = io.open(string.format("/sys/class/drm/card%d-eDP-1/edid", card), "rb")
    if f then
      edid = f:read("a")
      f:close()
      if edid and #edid >= 256 then break end
    end
  end
  for start = 129, #(edid or "") - 127, 128 do
    local block = edid:sub(start, start + 127)
    local nits
    if block:byte(1) == 0x02 then
      nits = hdr_frame_average(block:sub(5, block:byte(3)))
    elseif block:byte(1) == 0x70 then
      local i, last = 6, 5 + block:byte(3)
      while i + 2 <= last and not nits do
        local length = block:byte(i + 2)
        if block:byte(i) == 0x81 then nits = hdr_frame_average(block:sub(i + 3, i + 2 + length)) end
        i = i + 3 + length
      end
    end
    if nits then return nits end
  end
end

edp_sdr_white = edid_full_screen_nits() or 600
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
