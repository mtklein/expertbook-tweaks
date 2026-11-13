o = {}

function o.launch(command)
  return "uwsm-app -- " .. command
end

function o.bind(keys, description, action, options)
  local opts = options or {}
  opts.description = description
  if type(action) == "string" then
    action = hl.dsp.exec_cmd(action)
  end
  hl.bind(keys, action, opts)
end

function o.bind_hold(keys, press_description, press, release_description, release)
  local held = false
  o.bind(keys, press_description, function()
    held = true
    hl.exec_cmd(press)
  end, { ignore_mods = true })
  o.bind(keys, release_description, function()
    if held then
      held = false
      hl.exec_cmd(release)
    end
  end, { release = true, transparent = true, ignore_mods = true, non_consuming = true })
end

function o.window(match, rules)
  rules.match = type(match) == "string" and { class = match } or match
  hl.window_rule(rules)
end
