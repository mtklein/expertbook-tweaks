-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
-- List current monitors and supported resolutions with: hyprctl monitors all

local omarchy_gdk_scale = 2
local omarchy_monitor_scale = 2

hl.env("GDK_SCALE", tostring(omarchy_gdk_scale))
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = omarchy_monitor_scale })

-- Internal Samsung OLED: HDR (needs asus-expertbook-linux hdr-fix so aquamarine sees the PQ/BT.2020 EDID data).
-- In HDR the panel ignores its backlight, so brightness is done in the compositor
-- via sdrbrightness. ~/.local/bin/hdr-brightness (bound to the brightness keys)
-- calls edp_hdr_monitor() and saves the level to ~/.local/state/hdr-brightness.
-- To turn HDR off, comment out the edp_hdr_monitor(...) call at the bottom of this block.
function edp_hdr_monitor(sdr_brightness)
  hl.monitor({
    output = "eDP-1", mode = "preferred", position = "auto", scale = omarchy_monitor_scale,
    bitdepth = 10, cm = "hdr", sdrbrightness = sdr_brightness,
  })
end

local function saved_hdr_brightness()
  local f = io.open((os.getenv("HOME") or "") .. "/.local/state/hdr-brightness")
  if not f then return 1.0 end
  local v = tonumber(f:read("l"))
  f:close()
  return v or 1.0
end

edp_hdr_monitor(saved_hdr_brightness())

-- Configure a specific monitor.
-- hl.monitor({ output = "DP-2", mode = "2560x1440@144", position = "0x0", scale = 1 })

-- Portrait/rotated secondary monitor (transform: 1 = 90°, 3 = 270°).
-- hl.monitor({ output = "DP-2", mode = "preferred", position = "auto", scale = 1, transform = 1 })

-- Hardware cursor planes bypass color management, so in HDR the cursor's white
-- renders at peak panel brightness. A software cursor goes through the HDR pipeline.
hl.config({ cursor = { no_hardware_cursors = true } })
