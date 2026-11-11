local TAP_MS = 300
local CONSOLE = "qconsole"
local SUPER_L, SUPER_R, CAPS_LOCK = 133, 134, 66
local TAP_KEYS = { [SUPER_L] = true, [SUPER_R] = true, [CAPS_LOCK] = true }

local held = nil
local chord = false
local too_long = false
local generation = 0

hl.on("input.keyboard.key", function(code, _, state)
  if TAP_KEYS[code] and (held == nil or held == code) then
    if state == 1 then
      if held then return end
      held, chord, too_long = code, false, false
      generation = generation + 1
      local mine = generation
      hl.timer(function()
        if mine == generation and held then too_long = true end
      end, { timeout = TAP_MS, type = "oneshot" })
    elseif state == 0 then
      if not held then return end
      held = nil
      generation = generation + 1
      if not chord and not too_long then
        hl.dispatch(hl.dsp.workspace.toggle_special(CONSOLE))
      end
    end
  elseif state == 1 and held then
    chord = true
  end
end)

local CONSOLE_APPS = { ["org.omarchy.agent"] = true }

hl.on("window.open", function(window)
  if not window or not window.workspace or window.workspace.name ~= "special:" .. CONSOLE then return end
  if CONSOLE_APPS[window.class] then return end
  local monitor = hl.get_active_monitor()
  local ws = monitor and monitor.active_workspace
  if not ws then return end
  local target = "address:" .. window.address
  hl.dispatch(hl.dsp.window.move({ window = target, workspace = tostring(ws.id), follow = false }))
  hl.dispatch(hl.dsp.workspace.toggle_special(CONSOLE))
  hl.dispatch(hl.dsp.focus({ window = target }))
end)
