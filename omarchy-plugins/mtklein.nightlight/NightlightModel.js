// Temperatures below this count as night light. Omarchy uses 6000; here
// ~/expertbook-tweaks/bin/ambient-display also warms lit rooms down to 5000 K
// (True Tone style) without that being "night light", so the line is 5000.
// The name is kept for the rest of the plugin.
var IDENTITY_TEMPERATURE = 5000

function temperatureFromOutput(output) {
  var match = String(output === undefined || output === null ? "" : output).match(/[0-9]+/)
  return match ? Number(match[0]) : null
}

function isNightlight(temperature) {
  return temperature !== null && temperature !== undefined && temperature < IDENTITY_TEMPERATURE
}

if (typeof module !== "undefined") {
  module.exports = {
    IDENTITY_TEMPERATURE: IDENTITY_TEMPERATURE,
    temperatureFromOutput: temperatureFromOutput,
    isNightlight: isNightlight
  }
}
