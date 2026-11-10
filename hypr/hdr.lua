-- Internal OLED HDR and brightness for the ASUS ExpertBook Ultra.
-- Loaded from ~/.config/hypr/monitors.lua (which Omarchy owns and edits) with
--   dofile(os.getenv("HOME") .. "/expertbook-tweaks/hypr/hdr.lua")(omarchy_monitor_scale)
-- Remove that line to turn HDR off.
return function(omarchy_monitor_scale)

-- Greyscale text antialiasing for Qt Quick apps (the Omarchy shell/bar). Their
-- default subpixel AA gives glyph edges per-channel coverage above the pixel's
-- alpha: clipped invisibly in SDR, but rendered brighter than white in HDR
-- (stray bright pixels on bar icons). Pointless on this OLED anyway. The
-- fontconfig half is fontconfig/60-grayscale-antialias.conf.
hl.env("QSG_DISTANCEFIELD_ANTIALIASING", "gray")

-- Internal Samsung OLED: HDR (needs asus-expertbook-linux hdr-fix so aquamarine sees the PQ/BT.2020 EDID data).
-- In HDR the panel ignores its backlight, so brightness is done in the compositor
-- by scaling the SDR white level (sdr_max_luminance). ~/.local/bin/hdr-brightness (bound to the brightness keys)
-- calls edp_hdr_monitor() and saves the level to ~/.local/state/hdr-brightness.

-- Luminance (nits) that SDR white maps to in HDR, i.e. what "100%" means.
-- Hyprland's default is 80; BT.2408 reference white is 203; macOS XDR goes to ~500.
-- 500 gives a bright ceiling (run brightness lower); the panel peaks at 1600.
-- Try others live: hyprctl eval 'edp_sdr_white = N; edp_hdr_monitor(<0-1>)'
edp_sdr_white = 500

-- The level meter is perceptual: equal steps of level look like equal steps
-- of brightness. nits = edp_sdr_white * level ^ edp_brightness_gamma, so 50%
-- is ~109 nits, 25% ~24, 10% ~3.
edp_brightness_gamma = 2.2

function edp_hdr_monitor(level)
  local nits = edp_sdr_white * level ^ edp_brightness_gamma
  -- sdr_max_luminance is a whole number of nits. Above a few nits that's fine
  -- enough; below, the fraction rides on sdrbrightness (which the patched
  -- Hyprland applies to every surface), so the dim end isn't a staircase.
  -- 0% is "off": sdr_max_luminance can't go below 1 (0 means default), so
  -- scale the picture to black instead. (Exactly 0 would also mean default.)
  local whole, scale
  if level <= 0 then
    whole, scale = 1, 0.0001
  elseif nits >= 8 then
    whole, scale = math.floor(nits + 0.5), 1
  else
    whole = math.max(1, math.ceil(nits - 1e-6))
    scale = math.max(0.0001, math.min(1, nits / whole))
  end
  hl.monitor({
    output = "eDP-1", mode = "preferred", position = "auto", scale = omarchy_monitor_scale,
    bitdepth = 10, cm = "hdr",
    -- Brightness is the SDR white level itself rather than sdrbrightness, so
    -- colour-managed clients (Chromium, Electron) follow it too; that needs
    -- the patched Hyprland in hyprland-patched/. Stock Hyprland still dims
    -- everything else the same way.
    sdr_max_luminance = whole,
    sdrbrightness = scale,
    -- SDR black defaults to 0.2 nits, which glows on the OLED.
    sdr_min_luminance = 0,
  })
  -- Publish the curve's two numbers, so ambient-display can turn nits into percent.
  local f = io.open((os.getenv("HOME") or "") .. "/.local/state/hdr-sdr-white", "w")
  if f then f:write(string.format("%g\n", edp_sdr_white)); f:close() end
  f = io.open((os.getenv("HOME") or "") .. "/.local/state/hdr-brightness-gamma", "w")
  if f then f:write(string.format("%g\n", edp_brightness_gamma)); f:close() end
end

local function saved_hdr_brightness()
  local f = io.open((os.getenv("HOME") or "") .. "/.local/state/hdr-brightness")
  if not f then return 1.0 end
  local v = tonumber(f:read("l"))
  f:close()
  return v or 1.0
end

edp_hdr_monitor(saved_hdr_brightness())

-- The hardware cursor plane bypasses Hyprland's final colour conversion; the
-- patched Hyprland (hyprland-patched/05) renders the cursor in the output's
-- encoding at the SDR white level, so the hardware cursor is fine in HDR.
-- On an unpatched Hyprland it renders far too bright: put this back then.
-- hl.config({ cursor = { no_hardware_cursors = true } })

end
