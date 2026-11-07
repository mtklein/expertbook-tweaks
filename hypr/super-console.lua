-- Super on its own drives Omarchy's Quake console (special:qconsole, also on
-- Super + `):
--   tap  (press and release within HOLD_MS, no other key)  -> toggle it
--   hold (past HOLD_MS, no other key)                     -> show it while held,
--                                                            hide it on release
-- Any other key pressed while Super is down makes it a chord: nothing toggles,
-- and a peek already showing is put away at once so the shortcut lands on the
-- window you were in.
--
-- Hyprland hands every key to Lua as input.keyboard.key(keycode, ?, state),
-- state 1 = press, 0 = release. Super is matched by its evdev (125/126) and
-- xkb (133/134) codes, whichever this build reports.

local HOLD_MS = 300
local CONSOLE = "qconsole"

local SUPER = { [125] = true, [126] = true, [133] = true, [134] = true }

local super_down = false
local chord = false      -- another key went down during this Super press
local held = false       -- HOLD_MS passed with Super still down
local peeking = false    -- the console is showing because of a hold
local generation = 0     -- invalidates hold timers from earlier presses

local function console_open()
  for _, m in ipairs(hl.get_monitors() or {}) do
    local sw = m.active_special_workspace
    if sw and sw.name == "special:" .. CONSOLE then return true end
  end
  return false
end

local function toggle()
  hl.dispatch(hl.dsp.workspace.toggle_special(CONSOLE))
end

hl.on("input.keyboard.key", function(code, _, state)
  if SUPER[code] then
    if state == 1 then
      if super_down then return end          -- repeats / a duplicate report
      super_down, chord, held = true, false, false
      generation = generation + 1
      local mine = generation
      hl.timer(function()
        if mine ~= generation or not super_down or chord then return end
        held = true
        if not console_open() then
          peeking = true
          toggle()
        end
      end, { timeout = HOLD_MS, type = "oneshot" })
    elseif state == 0 then
      if not super_down then return end
      super_down = false
      generation = generation + 1
      if peeking then
        peeking = false
        if console_open() then toggle() end
      elseif not chord and not held then
        toggle()
      end
    end
  elseif state == 1 and super_down and not chord then
    chord = true
    if peeking then
      peeking = false
      if console_open() then toggle() end
    end
  end
end)
