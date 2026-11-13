o.window(".*", { suppress_event = "maximize" })
o.window({ class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false }, { no_focus = true })

o.window("(foot|console|org\\.codeberg\\.dnkl\\.foot|org\\.omarchy\\..*|TUI\\..*)", { tag = "+terminal" })

o.window({ tag = "floating-window" }, { float = true, center = true, size = { 875, 600 } })
o.window("(org.omarchy.btop|org.omarchy.terminal|org.omarchy.bash|org.gnome.NautilusPreviewer|org.gnome.Evince|Omarchy|About|TUI.float|imv|mpv)", { tag = "+floating-window" })
o.window("xdg-desktop-portal-gtk", { tag = "+floating-window" })
o.window({
  class = "org.gnome.Nautilus",
  title = "^(Open.*Files?|Open [F|f]older.*|Save.*Files?|Save.*As|Save|All Files|.*wants to [open|save].*|[C|c]hoose.*)",
}, { tag = "+floating-window" })
o.window({ tag = "noidle" }, { idle_inhibit = "always" })

o.window("((google-)?[cC]hrom(e|ium))", { tag = "+chromium-based-browser" })
o.window({ tag = "chromium-based-browser" }, { tile = true })
o.window({ title = "(Picture.?in.?[Pp]icture)" }, {
  float = true,
  pin = true,
  size = { 600, 338 },
  keep_aspect_ratio = true,
  move = { "(monitor_w-window_w-40)", "(monitor_h*0.04)" },
})

o.window("steam", { float = true, idle_inhibit = "fullscreen" })
o.window({ class = "steam", title = "Steam" }, { tile = true })
o.window({ class = "steam", title = "Friends List" }, { size = { 460, 800 } })
hl.on("window.close", function(window)
  if window and window.class == "steam" then
    hl.exec_cmd("steam-quit-when-closed")
  end
end)

o.window("GeForceNOW", { idle_inhibit = "fullscreen", tag = "+wheel_scroll" })
o.window({ class = "GeForceNOW", fullscreen = true }, { tag = "+touch_mouse" })

hl.layer_rule({ match = { namespace = "^shell-.*$" }, no_anim = true, animation = "none" })
