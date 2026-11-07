-- Keep only your personal keybinding overrides here. Add new bindings or
-- unbind defaults before replacing them.

-- See current bindings and descriptions:
--   omarchy menu keybindings --print

-- To disable every Omarchy default binding, set this in
-- ~/.config/hypr/hyprland.lua before require("default.hypr.omarchy"), then add
-- only the bindings you want below:
--   omarchy_default_bindings = false

-- To disable all preinstalled app/webapp bindings, set:
--   omarchy_preinstalled_bindings = false

-- Add a new binding.
-- o.bind("SUPER + SHIFT + R", "SSH", "alacritty -e ssh your-server")

-- Change an existing binding by unbinding it first, then binding the key again.
-- This example changes SUPER+SPACE from the launcher to the Omarchy root menu.
-- hl.unbind("SUPER + SPACE")
-- o.bind("SUPER + SPACE", "Omarchy menu", "omarchy-menu toggle root")

-- Disable a default binding without replacing it.
-- hl.unbind("SUPER + SHIFT + B")

-- Logitech MX Keys examples:
-- o.bind("SUPER + SHIFT + S", nil, "omarchy-capture-screenshot")
-- o.bind("SUPER + H", nil, "voxtype record toggle")
-- o.bind("SUPER + PERIOD", nil, "omarchy-shell shell toggle omarchy.emojis")

-- Brightness keys that also work with HDR on (see ~/.local/bin/hdr-brightness).
-- With HDR off or an external monitor focused they behave exactly like Omarchy's defaults.
-- Shift + the same keys moves the white point (dim = warmer, bright = cooler;
-- ~/.local/bin/white-point). ambient-display learns from both.
for _, b in ipairs({
  { "XF86MonBrightnessUp", "Brightness up", "hdr-brightness +5%" },
  { "XF86MonBrightnessDown", "Brightness down", "hdr-brightness 5%-" },
  { "ALT + XF86MonBrightnessUp", "Brightness up precise", "hdr-brightness +1%" },
  { "ALT + XF86MonBrightnessDown", "Brightness down precise", "hdr-brightness 1%-" },
  { "SHIFT + XF86MonBrightnessUp", "White point cooler", "white-point +200" },
  { "SHIFT + XF86MonBrightnessDown", "White point warmer", "white-point -200" },
}) do
  hl.unbind(b[1])
  o.bind(b[1], b[2], b[3], { locked = true, repeating = true })
end


-- Workspace layout cycling without Omarchy's notification on every change.
for _, b in ipairs({
  { "SUPER + L", "Cycle workspace layout", "workspace-layout-toggle" },
  { "SUPER + ALT + L", "Cycle workspace layout back", "workspace-layout-toggle back" },
}) do
  hl.unbind(b[1])
  o.bind(b[1], b[2], b[3])
end

-- Super alone: tap toggles the Quake console, hold peeks it (hypr/super-console.lua).
dofile(os.getenv("HOME") .. "/expertbook-tweaks/hypr/super-console.lua")

-- Dictation keys from before Alt + Space and Right Alt became the defaults.
-- Remove these lines to give the keys back to applications.
if o.dictation_installed and o.dictation_installed() then
  o.bind("SUPER + CTRL + X", "Toggle dictation", "omarchy-dictation toggle")
  o.bind_hold("F9", "Start dictation (push-to-talk)", "omarchy-dictation start", "Stop dictation (push-to-talk)", "omarchy-dictation stop")
end
