local home = os.getenv("HOME") or ""
local state = home .. "/.local/state/"
local SCALES = { 1.25, 1.5 }
local PANEL = "eDP-1"
local RIGHT_SIDE_UP = 3

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

hl.env("QSG_DISTANCEFIELD_ANTIALIASING", "gray")
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })

local edp_scale = read_number(state .. "edp-scale", 1.5)

local function panel()
  hl.monitor({
    output = PANEL, mode = "1080x1920@120", position = "auto", scale = edp_scale,
    transform = RIGHT_SIDE_UP, bitdepth = 8, cm = "srgb",
  })
end

hl.config({ input = { touchdevice = { transform = RIGHT_SIDE_UP, output = PANEL } } })

function edp_cycle_scale()
  local following = SCALES[1]
  for i, scale in ipairs(SCALES) do
    if math.abs(scale - edp_scale) < 0.01 then following = SCALES[i % #SCALES + 1] end
  end
  edp_scale = following
  write_number(state .. "edp-scale", edp_scale)
  panel()
  hl.exec_cmd(string.format("qs ipc call osd pop scale -1 '%gx'", edp_scale))
end

local function external()
  local ok, monitors = pcall(hl.get_monitors)
  for _, monitor in ipairs(ok and monitors or {}) do
    if monitor.name ~= PANEL then return true end
  end
  return false
end

function edp_lid(closed)
  if closed and external() then
    hl.monitor({ output = PANEL, disabled = true })
  else
    hl.monitor({ output = PANEL, disabled = false })
    panel()
  end
end

panel()

hl.on("monitor.removed", function()
  if not external() then edp_lid(false) end
end)
