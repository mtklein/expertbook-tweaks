-- A tap of Super on its own toggles Omarchy's Quake console (special:qconsole,
-- also on Super + `): press and release within TAP_MS with no other key in
-- between. A longer press, or Super with any other key, does nothing here, so
-- pausing on Super before a shortcut never toggles the console.
--
-- Hyprland hands every key to Lua as input.keyboard.key(keycode, ?, state),
-- state 1 = press, 0 = release. Super is matched by its evdev (125/126) and
-- xkb (133/134) codes, whichever this build reports.

local TAP_MS = 300
local CONSOLE = "qconsole"

local SUPER = { [125] = true, [126] = true, [133] = true, [134] = true }

local super_down = false
local chord = false      -- another key went down during this Super press
local too_long = false   -- TAP_MS passed with Super still down
local generation = 0     -- invalidates timers from earlier presses

hl.on("input.keyboard.key", function(code, _, state)
  if SUPER[code] then
    if state == 1 then
      if super_down then return end          -- repeats / a duplicate report
      super_down, chord, too_long = true, false, false
      generation = generation + 1
      local mine = generation
      hl.timer(function()
        if mine == generation and super_down then too_long = true end
      end, { timeout = TAP_MS, type = "oneshot" })
    elseif state == 0 then
      if not super_down then return end
      super_down = false
      generation = generation + 1
      if not chord and not too_long then
        hl.dispatch(hl.dsp.workspace.toggle_special(CONSOLE))
      end
    end
  elseif state == 1 and super_down then
    chord = true
  end
end)
