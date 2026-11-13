local CONSOLE = "qconsole"
local SPECIAL = "special:" .. CONSOLE
local CONSOLE_APPS = { ["console"] = true }
local CAPS_LOCK = 66
local TAP_MS = 300
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

local held, chord, too_long, generation = false, false, false, 0

hl.on("input.keyboard.key", function(code, _, state)
  if code == CAPS_LOCK then
    if state == 1 then
      if held then return end
      held, chord, too_long = true, false, false
      generation = generation + 1
      local mine = generation
      hl.timer(function()
        if mine == generation and held then too_long = true end
      end, { timeout = TAP_MS, type = "oneshot" })
    elseif state == 0 then
      if not held then return end
      held = false
      generation = generation + 1
      if not chord and not too_long then
        hl.timer(function()
          hl.dispatch(hl.dsp.workspace.toggle_special(CONSOLE))
        end, { timeout = AFTER_RELEASE_MS, type = "oneshot" })
      end
    end
  elseif state == 1 and held then
    chord = true
  end
end)

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

function console_dictate()
  local ws = hl.get_workspace(SPECIAL)
  if not (ws and ws.visible) then
    hl.dispatch(hl.dsp.workspace.toggle_special(CONSOLE))
  end
  if not ws then return end
  local target
  for _, window in ipairs(hl.get_workspace_windows(SPECIAL)) do
    if CONSOLE_APPS[window.class] then target = "address:" .. window.address end
  end
  if not target then return end
  hl.timer(function()
    hl.dispatch(hl.dsp.focus({ window = target }))
    hl.dispatch(hl.dsp.send_shortcut({ mods = "CTRL", key = "X", window = target }))
    hl.timer(function()
      hl.dispatch(hl.dsp.send_shortcut({ mods = "", key = "V", window = target }))
    end, { timeout = 60, type = "oneshot" })
  end, { timeout = 60, type = "oneshot" })
end
