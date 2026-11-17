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

function o.window(match, rules)
  rules.match = type(match) == "string" and { class = match } or match
  hl.window_rule(rules)
end
