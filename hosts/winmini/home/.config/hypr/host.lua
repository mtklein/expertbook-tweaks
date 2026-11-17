o.bind("Menu", "Menu", hl.dsp.global("shell:menu"))

local L4, R4 = "code:198", "code:199"
local streak, held = {}, {}

local function once(key, command)
  return function()
    local n = (streak[key] or 0) + 1
    streak[key] = n
    if not held[key] then
      held[key] = true
      hl.exec_cmd(command)
    end
    hl.timer(function()
      if streak[key] == n then held[key] = false end
    end, { timeout = 300, type = "oneshot" })
  end
end

pcall(hl.unbind, "XF86AudioMicMute")
o.bind(L4, "Spoken replies on or off", once(L4, "speak-replies toggle"), { locked = true })
o.bind(R4, "Next power mode", once(R4, "power-mode next"), { locked = true })
