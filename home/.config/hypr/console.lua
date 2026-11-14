local CONSOLE = "qconsole"
local SPECIAL = "special:" .. CONSOLE
local CONSOLE_APPS = { ["console"] = true }
local AFTER_RELEASE_MS = 20
local share = 0.5
local box = 2

hl.on("workspace.created", function(ws)
  if ws and ws.name == SPECIAL and ws.is_empty then
    hl.exec_cmd(o.launch("foot --app-id=console claude --permission-mode auto"), { workspace = SPECIAL .. " silent" })
  end
end)

hl.config({ decoration = { dim_special = 0.6 } })

local beside, below = nil, nil
local function cover(side, bottom)
  if beside == side and below == bottom then
    return false
  end
  beside, below = side, bottom
  hl.workspace_rule({
    workspace = SPECIAL,
    gaps_in = 0,
    gaps_out = { top = 0, right = side, bottom = bottom, left = side },
    no_border = true,
  })
  return true
end

local function alone()
  local tiled = 0
  for _, window in ipairs(hl.get_workspace_windows(SPECIAL)) do
    if not window.floating then
      tiled = tiled + 1
    end
  end
  return tiled <= 1
end

local function fit(monitor)
  if not monitor or not monitor.scale or monitor.scale <= 0 then
    return false
  end
  local width, height = monitor.width, monitor.height
  if monitor.transform % 2 == 1 then
    width, height = height, width
  end
  local reserved = monitor.reserved
  height = height / monitor.scale - reserved.top - reserved.bottom
  width = width / monitor.scale - reserved.left - reserved.right
  local tall = math.floor(height * share)
  local wide = width
  if alone() then
    wide = math.min(width, tall * box)
  end
  return cover(math.floor((width - wide) / 2), math.floor(height - tall))
end

local function console_monitor()
  local ws = hl.get_workspace(SPECIAL)
  local mon = ws and ws.visible and ws.monitor
  if mon and mon.scale and mon.scale > 0 then
    return mon
  end
  return hl.get_active_monitor()
end

local function refit(monitor)
  if fit(monitor or console_monitor()) then
    hl.exec_scheduled_prop_refresh_immediately()
  end
end

cover(0, 0)
fit(console_monitor())

hl.on("monitor.layout_changed", function() refit() end)
hl.on("monitor.focused", function() refit() end)
hl.on("workspace.special_active", function(ws, mon)
  if ws and ws.name == SPECIAL then refit(mon) end
end)
hl.on("workspace.move_to_monitor", function(ws, mon)
  if ws and ws.name == SPECIAL then refit(mon) end
end)

local function recount()
  local ws = hl.get_workspace(SPECIAL)
  if ws and ws.visible then refit() end
end
hl.on("window.destroy", recount)
hl.on("window.move_to_workspace", recount)
hl.on("window.update_rules", recount)

hl.animation({ leaf = "specialWorkspaceIn", enabled = true, speed = 3, bezier = "easeOutQuint", style = "slide top" })
hl.animation({ leaf = "specialWorkspaceOut", enabled = true, speed = 2, bezier = "easeInOutCubic", style = "slide bottom" })

hl.on("window.open", function(window)
  recount()
  if not window or not window.workspace or window.workspace.name ~= SPECIAL then return end
  if CONSOLE_APPS[window.class] then return end
  local monitor = hl.get_active_monitor()
  local ws = monitor and monitor.active_workspace
  if not ws then return end
  local target = "address:" .. window.address
  hl.dispatch(hl.dsp.window.move({ window = target, workspace = tostring(ws.id), follow = false }))
  hl.dispatch(hl.dsp.workspace.toggle_special(CONSOLE))
  hl.dispatch(hl.dsp.focus({ window = target }))
end)

local function console_window()
  for _, window in ipairs(hl.get_workspace_windows(SPECIAL)) do
    if CONSOLE_APPS[window.class] then return "address:" .. window.address end
  end
end

local function voice_key(target)
  hl.dispatch(hl.dsp.send_shortcut({ mods = "ALT", key = "K", window = target }))
end

function console_dictate()
  local ws = hl.get_workspace(SPECIAL)
  if not (ws and ws.visible) then
    hl.dispatch(hl.dsp.workspace.toggle_special(CONSOLE))
  end
  local target = ws and console_window()
  if not target then return false end
  hl.timer(function()
    hl.dispatch(hl.dsp.focus({ window = target }))
    voice_key(target)
  end, { timeout = 60, type = "oneshot" })
  return true
end

local RIGHT_ALT = 108
local TALK_AFTER_MS = 200
local alt_held, alt_chord, alt_press, talking = false, false, 0, false

hl.on("input.keyboard.key", function(code, _, state)
  if code ~= RIGHT_ALT then
    if state == 1 and alt_held then alt_chord = true end
    return
  end
  if state == 1 then
    if alt_held then return end
    alt_held, alt_chord = true, false
    alt_press = alt_press + 1
    local mine = alt_press
    hl.timer(function()
      if mine == alt_press and alt_held and not alt_chord then talking = console_dictate() end
    end, { timeout = TALK_AFTER_MS, type = "oneshot" })
  elseif state == 0 then
    if not alt_held then return end
    alt_held = false
    alt_press = alt_press + 1
    if talking then
      talking = false
      local target = console_window()
      if not target then return end
      hl.timer(function() voice_key(target) end, { timeout = 150, type = "oneshot" })
    elseif not alt_chord then
      hl.timer(function()
        hl.dispatch(hl.dsp.workspace.toggle_special(CONSOLE))
      end, { timeout = AFTER_RELEASE_MS, type = "oneshot" })
    end
  end
end)
