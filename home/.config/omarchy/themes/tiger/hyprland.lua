-- Tiger: Chromium's pale frame blue on the focused window's border (it runs
-- into a Chromium window's tab strip), soft grey on the rest, and
-- Aqua-style drop shadows (big and soft under the focused window, smaller and
-- fainter under the others). Borders are off in ~/.config/hypr/looknfeel.lua; the colours
-- stay for anything that still draws one (window groups).
local active_border_color = "rgba(d3e3fdff)"
local inactive_border_color = "rgba(b4b4b4aa)"

hl.config({
  general = {
    col = {
      active_border = active_border_color,
      inactive_border = inactive_border_color,
    },
  },

  group = {
    col = {
      border_active = active_border_color,
      border_inactive = inactive_border_color,
    },
  },

  decoration = {
    shadow = {
      enabled = true,
      range = 22,
      render_power = 3,
      offset = "0 6",
      color = "rgba(00000055)",
      color_inactive = "rgba(00000028)",
    },
  },
})
