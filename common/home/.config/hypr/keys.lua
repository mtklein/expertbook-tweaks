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

o.bind("SUPER + SPACE", "Terminal", terminal)
o.bind("SUPER + RETURN", "Browser", o.launch("chromium"))
o.bind("SUPER + SHIFT + code:201", "Menu", shell("menu"))

o.bind("SUPER + W", "Close window", hl.dsp.window.close())
o.bind("SUPER + Q", "Close window", hl.dsp.window.close())
o.bind("SUPER + mouse:272", "Move window", hl.dsp.window.drag(), { mouse = true })
o.bind("SUPER + F", "Full screen", hl.dsp.window.fullscreen({ mode = "fullscreen" }))

for workspace = 1, 9 do
  local key = "code:" .. (workspace + 9)
  o.bind("SUPER + " .. key, "Workspace " .. workspace, hl.dsp.focus({ workspace = tostring(workspace) }))
  o.bind("SUPER + SHIFT + " .. key, "Send window to workspace " .. workspace, hl.dsp.window.move({ workspace = tostring(workspace) }))
end

local function step_workspace(direction)
  local monitor = hl.get_active_monitor()
  local here = monitor and monitor.active_workspace
  if not here then return end
  local best
  for _, ws in ipairs(hl.get_workspaces()) do
    local id = ws.id
    local same = not ws.monitor or ws.monitor.name == monitor.name
    if same and not ws.special and not ws.is_empty and id > 0 and (id - here.id) * direction > 0 then
      if not best or (id - best) * direction < 0 then best = id end
    end
  end
  if best then hl.dispatch(hl.dsp.focus({ workspace = tostring(best) })) end
end
o.bind("SUPER + bracketleft", "Lower workspace", function() step_workspace(-1) end)
o.bind("SUPER + bracketright", "Higher workspace", function() step_workspace(1) end)

o.bind("SUPER + C", "Copy", function() tap(in_terminal() and "CTRL SHIFT" or "CTRL", "C") end)
o.bind("SUPER + V", "Paste", function() tap(in_terminal() and "CTRL SHIFT" or "CTRL", "V") end)

local held = { locked = true, repeating = true }
o.bind("XF86AudioRaiseVolume", "Volume up", shell("volume-up"), held)
o.bind("XF86AudioLowerVolume", "Volume down", shell("volume-down"), held)
o.bind("XF86AudioMute", "Mute", shell("mute"), { locked = true })
o.bind("XF86AudioMicMute", "Mute microphone", shell("microphone-mute"), { locked = true })
o.bind("SUPER + M", "Mute microphone", shell("microphone-mute"), { locked = true })
o.bind("code:192", "Spoken replies on or off", "speak-replies toggle")

o.bind("XF86MonBrightnessUp", "Brightness up", "brightness +5%", held)
o.bind("XF86MonBrightnessDown", "Brightness down", "brightness 5%-", held)
o.bind("ALT + XF86MonBrightnessUp", "Brightness up precise", "brightness +1%", held)
o.bind("ALT + XF86MonBrightnessDown", "Brightness down precise", "brightness 1%-", held)
o.bind("SHIFT + XF86MonBrightnessUp", "White point cooler", "white-point cooler", held)
o.bind("SHIFT + XF86MonBrightnessDown", "White point warmer", "white-point warmer", held)

o.bind("XF86KbdLightOnOff", "Keyboard backlight", "keyboard-backlight cycle", { locked = true })
o.bind("XF86KbdBrightnessUp", "Keyboard backlight up", "keyboard-backlight up", held)
o.bind("XF86KbdBrightnessDown", "Keyboard backlight down", "keyboard-backlight down", held)

o.bind("switch:on:Lid Switch", nil, function() edp_lid(true) end, { locked = true })
o.bind("switch:off:Lid Switch", nil, function() edp_lid(false) end, { locked = true })

o.bind("SUPER + P", "Cycle display scale", function() edp_cycle_scale() end)
