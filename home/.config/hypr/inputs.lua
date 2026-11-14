hl.config({
  input = {
    kb_layout = "us",
    kb_options = "ctrl:nocaps,shift:both_capslock_cancel",
    follow_mouse = 1,
    sensitivity = 0,
    repeat_rate = 40,
    repeat_delay = 250,
    numlock_by_default = true,
    touchpad = {
      natural_scroll = true,
      clickfinger_behavior = true,
      scroll_factor = 0.4,
    },
  },
  misc = {
    key_press_enables_dpms = true,
    mouse_move_enables_dpms = true,
  },
})

local function touchpad_curve()
  local units_per_mm = 31
  local step = 0.2
  local gain = 2.1
  local exponent = 0.55
  local points = {}
  for i = 0, 63 do
    local mm_per_s = i * step * 1000 / units_per_mm
    local px_per_mm = gain * mm_per_s ^ exponent
    points[#points + 1] = string.format("%.4f", px_per_mm * i * step / units_per_mm)
  end
  return string.format("custom %g %s", step, table.concat(points, " "))
end

hl.device({
  name = "ascp1d80:00-093a:4f05-touchpad",
  accel_profile = touchpad_curve(),
})

o.window("(foot|console)", { scroll_touchpad = 2.0 })
o.window({ class = "TUI\\..*", initial_title = "foot" }, { scroll_touchpad = 2.0 })
