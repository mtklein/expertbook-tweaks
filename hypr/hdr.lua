-- Internal OLED HDR, brightness, and border dimming for the ASUS ExpertBook Ultra.
-- Loaded from ~/.config/hypr/monitors.lua (which Omarchy owns and edits) with
--   dofile(os.getenv("HOME") .. "/expertbook-tweaks/hypr/hdr.lua")(omarchy_monitor_scale)
-- Remove that line to turn HDR off.
return function(omarchy_monitor_scale)

-- Internal Samsung OLED: HDR (needs asus-expertbook-linux hdr-fix so aquamarine sees the PQ/BT.2020 EDID data).
-- In HDR the panel ignores its backlight, so brightness is done in the compositor
-- by scaling the SDR white level (sdr_max_luminance). ~/.local/bin/hdr-brightness (bound to the brightness keys)
-- calls edp_hdr_monitor() and saves the level to ~/.local/state/hdr-brightness.
-- The SDR white level doesn't reach window borders, so dim the theme's border colours
-- by the same factor (in linear light). Colours are re-read from the current
-- theme each time, so theme switches keep working.
local function theme_border_colors()
  local f = io.open((os.getenv("HOME") or "") .. "/.local/state/omarchy/current/theme/hyprland.lua")
  if not f then return nil end
  local src = f:read("a")
  f:close()
  local function value(name)
    local expr = src:match("local%s+" .. name .. "%s*=%s*(.-)\n")
    local chunk = expr and load("return " .. expr, name, "t", {})
    local ok, v = pcall(chunk or error)
    return ok and v or nil
  end
  return value("active_border_color"), value("inactive_border_color")
end

local function dim_color(c, factor)
  if type(c) == "table" then
    local out = {}
    for k, v in pairs(c) do out[k] = (k == "colors") and dim_color(v, factor) or v end
    if c[1] then for i, v in ipairs(c) do out[i] = dim_color(v, factor) end end
    return out
  end
  if type(c) ~= "string" then return c end
  local hex = c:match("^#(%x+)$") or c:match("^rgba?%((%x+)%)$")
  if not hex or (#hex ~= 6 and #hex ~= 8) then return c end
  local function channel(i)
    local s = tonumber(hex:sub(i, i + 1), 16) / 255
    local lin = s <= 0.04045 and s / 12.92 or ((s + 0.055) / 1.055) ^ 2.4
    lin = lin * factor
    s = lin <= 0.0031308 and lin * 12.92 or 1.055 * lin ^ (1 / 2.4) - 0.055
    return string.format("%02x", math.floor(s * 255 + 0.5))
  end
  return "rgba(" .. channel(1) .. channel(3) .. channel(5) .. (#hex == 8 and hex:sub(7, 8) or "ff") .. ")"
end

-- Luminance (nits) that SDR white maps to in HDR, i.e. what "100%" means.
-- Hyprland's default is 80; 203 is the ITU-R BT.2408 HDR reference (graphics)
-- white, used as 100%; the panel peaks at 1600.
-- Try others live: hyprctl eval 'edp_sdr_white = N; edp_hdr_monitor(<0-1>)'
edp_sdr_white = 203

function edp_hdr_monitor(sdr_brightness)
  hl.monitor({
    output = "eDP-1", mode = "preferred", position = "auto", scale = omarchy_monitor_scale,
    bitdepth = 10, cm = "hdr",
    -- Brightness is the SDR white level itself rather than sdrbrightness, so
    -- colour-managed clients (Chromium, Electron) follow it too; that needs
    -- the patched Hyprland in hyprland-patched/. Stock Hyprland still dims
    -- everything else the same way.
    sdr_max_luminance = math.max(1, math.floor(edp_sdr_white * sdr_brightness + 0.5)),
  })
  local active, inactive = theme_border_colors()
  if active and inactive then
    active, inactive = dim_color(active, sdr_brightness), dim_color(inactive, sdr_brightness)
    hl.config({
      general = { col = { active_border = active, inactive_border = inactive } },
      group = { col = { border_active = active, border_inactive = inactive } },
    })
  end
end

local function saved_hdr_brightness()
  local f = io.open((os.getenv("HOME") or "") .. "/.local/state/hdr-brightness")
  if not f then return 1.0 end
  local v = tonumber(f:read("l"))
  f:close()
  return v or 1.0
end

edp_hdr_monitor(saved_hdr_brightness())

-- Hardware cursor planes bypass color management, so in HDR the cursor's white
-- renders at peak panel brightness. A software cursor goes through the HDR pipeline.
hl.config({ cursor = { no_hardware_cursors = true } })

end
