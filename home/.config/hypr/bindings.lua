for _, b in ipairs({
  { "XF86MonBrightnessUp", "Brightness up", "hdr-brightness +10%" },
  { "XF86MonBrightnessDown", "Brightness down", "hdr-brightness 10%-" },
  { "ALT + XF86MonBrightnessUp", "Brightness up precise", "hdr-brightness +1%" },
  { "ALT + XF86MonBrightnessDown", "Brightness down precise", "hdr-brightness 1%-" },
  { "SHIFT + XF86MonBrightnessUp", "White point cooler", "white-point cooler" },
  { "SHIFT + XF86MonBrightnessDown", "White point warmer", "white-point warmer" },
}) do
  hl.unbind(b[1])
  o.bind(b[1], b[2], b[3], { locked = true, repeating = true })
end

for _, b in ipairs({
  { "SUPER + L", "Cycle workspace layout", "workspace-layout-toggle" },
  { "SUPER + ALT + L", "Cycle workspace layout back", "workspace-layout-toggle back" },
}) do
  hl.unbind(b[1])
  o.bind(b[1], b[2], b[3])
end

dofile(os.getenv("HOME") .. "/.config/hypr/console-tap.lua")

if o.dictation_installed and o.dictation_installed() then
  o.bind("SUPER + CTRL + X", "Toggle dictation", "omarchy-dictation toggle")
  o.bind_hold("F9", "Start dictation (push-to-talk)", "omarchy-dictation start", "Stop dictation (push-to-talk)", "omarchy-dictation stop")
end
