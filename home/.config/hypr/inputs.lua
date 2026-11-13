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

o.window("(foot|console)", { scroll_touchpad = 2.0 })
o.window({ class = "(org\\.omarchy\\..*|TUI\\..*)", initial_title = "foot" }, { scroll_touchpad = 2.0 })
