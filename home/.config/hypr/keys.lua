local function shell(name)
  return hl.dsp.global("shell:" .. name)
end

local function terminal()
  local window = hl.get_active_window()
  hl.exec_cmd(o.launch("terminal-here" .. (window and window.pid and " " .. window.pid or "")))
end

local function tap(mods, key)
  hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "down" }))
  hl.timer(function()
    hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "up" }))
  end, { timeout = 50, type = "oneshot" })
end

local function in_terminal()
  local window = hl.get_active_window()
  for _, tag in ipairs(window and window.tags or {}) do
    if tag:gsub("%*$", "") == "terminal" then return true end
  end
  return false
end

o.bind("SUPER + RETURN", "Terminal", terminal)
o.bind("SUPER + SHIFT + RETURN", "Browser", o.launch("chromium"))
o.bind("SUPER + SHIFT + code:201", "Menu", shell("menu"))

o.bind("SUPER + W", "Close window", hl.dsp.window.close())
o.bind("SUPER + Q", "Close window", hl.dsp.window.close())
o.bind("SUPER + mouse:272", "Move window", hl.dsp.window.drag(), { mouse = true })
o.bind("SUPER + F", "Full screen", hl.dsp.window.fullscreen({ mode = "fullscreen" }))

for workspace = 1, 3 do
  local key = "code:" .. (workspace + 9)
  o.bind("SUPER + " .. key, "Workspace " .. workspace, hl.dsp.focus({ workspace = tostring(workspace) }))
  o.bind("SUPER + SHIFT + " .. key, "Send window to workspace " .. workspace, hl.dsp.window.move({ workspace = tostring(workspace) }))
end

o.bind("SUPER + C", "Copy", function() tap(in_terminal() and "CTRL SHIFT" or "CTRL", "C") end)
o.bind("SUPER + V", "Paste", function() tap(in_terminal() and "CTRL SHIFT" or "CTRL", "V") end)

local held = { locked = true, repeating = true }
o.bind("XF86AudioRaiseVolume", "Volume up", shell("volume-up"), held)
o.bind("XF86AudioLowerVolume", "Volume down", shell("volume-down"), held)
o.bind("XF86AudioMute", "Mute", shell("mute"), { locked = true })
o.bind("XF86AudioMicMute", "Mute microphone", shell("microphone-mute"), { locked = true })
o.bind("F14", "Dictate to Claude", function() console_dictate() end)

o.bind("XF86MonBrightnessUp", "Brightness up", "hdr-brightness +10%", held)
o.bind("XF86MonBrightnessDown", "Brightness down", "hdr-brightness 10%-", held)
o.bind("ALT + XF86MonBrightnessUp", "Brightness up precise", "hdr-brightness +1%", held)
o.bind("ALT + XF86MonBrightnessDown", "Brightness down precise", "hdr-brightness 1%-", held)
o.bind("SHIFT + XF86MonBrightnessUp", "White point cooler", "white-point cooler", held)
o.bind("SHIFT + XF86MonBrightnessDown", "White point warmer", "white-point warmer", held)

o.bind("XF86KbdLightOnOff", "Keyboard backlight", "keyboard-backlight cycle", { locked = true })
o.bind("XF86KbdBrightnessUp", "Keyboard backlight up", "keyboard-backlight up", held)
o.bind("XF86KbdBrightnessDown", "Keyboard backlight down", "keyboard-backlight down", held)

o.bind("switch:on:Lid Switch", nil, function() edp_lid(true) end, { locked = true })
o.bind("switch:off:Lid Switch", nil, function() edp_lid(false) end, { locked = true })

o.bind("SUPER + P", "Cycle display scale", function() edp_cycle_scale() end)
