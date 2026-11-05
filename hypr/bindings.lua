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
for _, b in ipairs({
  { "XF86MonBrightnessUp", "Brightness up", "+5%" },
  { "XF86MonBrightnessDown", "Brightness down", "5%-" },
  { "SHIFT + XF86MonBrightnessUp", "Brightness maximum", "100%" },
  { "SHIFT + XF86MonBrightnessDown", "Brightness minimum", "1%" },
  { "ALT + XF86MonBrightnessUp", "Brightness up precise", "+1%" },
  { "ALT + XF86MonBrightnessDown", "Brightness down precise", "1%-" },
}) do
  hl.unbind(b[1])
  o.bind(b[1], b[2], "hdr-brightness " .. b[3], { locked = true, repeating = true })
end


-- Dictation keys from before Alt + Space and Right Alt became the defaults.
-- Remove these lines to give the keys back to applications.
if o.dictation_installed and o.dictation_installed() then
  o.bind("SUPER + CTRL + X", "Toggle dictation", "omarchy-dictation toggle")
  o.bind_hold("F9", "Start dictation (push-to-talk)", "omarchy-dictation start", "Stop dictation (push-to-talk)", "omarchy-dictation stop")
end
