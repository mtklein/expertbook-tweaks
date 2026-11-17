local config = os.getenv("HYPR_CONFIG_ROOT") or (os.getenv("HOME") .. "/.config")
package.path = config .. "/?.lua;" .. package.path

local stale = {}
for module in pairs(package.loaded) do
  if module:sub(1, 5) == "hypr." then table.insert(stale, module) end
end
for _, module in ipairs(stale) do
  package.loaded[module] = nil
end

require("hypr.helpers")
require("hypr.env")
require("hypr.display")
require("hypr.inputs")
require("hypr.look")
require("hypr.windows")
require("hypr.console")
require("hypr.keys")
require("hypr.start")
