hl.config({ general = { border_size = 0 } })
hl.config({ misc = { vrr = 2 } })
hl.config({ render = { keep_unmodified_copy = 0 } })
o.window({ class = "steam", title = "Steam" }, { tile = true })
o.window("GeForceNOW", { tag = "+wheel_scroll" })
o.window({ class = "GeForceNOW", fullscreen = true }, { tag = "+touch_mouse" })
hl.on("window.close", function(window)
  if window and window.class == "steam" then
    hl.exec_cmd("steam-quit-when-closed")
  end
end)
