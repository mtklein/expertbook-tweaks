import QtQuick
import Quickshell.Io
import "NightlightModel.js" as NightlightModel
import qs.Commons

Item {
  id: root

  // Injected by omarchy-shell (the first-party service loader).
  property var shell: null

  // Keep in sync with bin/omarchy-toggle-nightlight, which sets the same
  // temperatures for callers outside the shell (keybindings, menu, ssh).
  // 3300 K, in real kelvin (the patched Hyprland applies the white point in
  // linear light). Matches NIGHT_TEMP in ~/expertbook-tweaks/bin/ambient-display;
  // 6600 K is its neutral.
  readonly property int nightTemperature: 3300
  readonly property int dayTemperature: 6600

  property bool stateLoaded: false
  property var temperature: null
  readonly property bool enabled: stateLoaded && NightlightModel.isNightlight(temperature)

  property bool hasPendingTemperature: false
  property int pendingTemperature: 0

  function refresh() {
    if (!statusProbe.running) statusProbe.running = true
  }

  // ~/expertbook-tweaks/bin/ambient-display owns the white point; a manual toggle
  // records an override it honours until the room next changes dark <-> lit.
  // The temperature is also applied here so the toggle feels instant.
  function setNightlight(value) {
    overrideProcess.command = ["sh", "-c",
      "mkdir -p \"${XDG_STATE_HOME:-$HOME/.local/state}\" && printf %s " + (value ? "night" : "day") +
      " > \"${XDG_STATE_HOME:-$HOME/.local/state}/ambient-white.override\""]
    overrideProcess.running = true
    applyTemperature(value ? nightTemperature : dayTemperature)
  }

  function toggle() {
    setNightlight(!enabled)
  }

  function applyTemperature(temp) {
    root.temperature = temp
    root.stateLoaded = true

    if (applyProcess.running) {
      root.pendingTemperature = temp
      root.hasPendingTemperature = true
      return
    }

    runApply(temp)
  }

  function runApply(temp) {
    applyProcess.command = ["bash", "-lc",
      "pgrep -x hyprsunset >/dev/null || { setsid uwsm-app -- hyprsunset >/dev/null 2>&1 & sleep 1; }; " +
      "hyprctl hyprsunset temperature " + Number(temp) +
      // Even daylight tints the screen, so off also restores the identity matrix
      (temp === dayTemperature ? " && hyprctl hyprsunset identity" : "")]
    applyProcess.running = true
  }

  Process {
    id: statusProbe
    command: ["hyprctl", "hyprsunset", "temperature"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        root.temperature = NightlightModel.temperatureFromOutput(text)
        root.stateLoaded = true
      }
    }
    onExited: function(exitCode) {
      if (exitCode !== 0) {
        root.temperature = null
        root.stateLoaded = true
      }
    }
  }

  Process {
    id: overrideProcess
  }

  Process {
    id: applyProcess
    onExited: function() {
      if (root.hasPendingTemperature) {
        root.hasPendingTemperature = false
        root.runApply(root.pendingTemperature)
        return
      }

      root.refresh()
    }
  }

  // ~/expertbook-tweaks/bin/ambient-display changes hyprsunset's temperature on
  // its own (dark room -> night light) without telling the bar, so re-read it
  // every 30 s to keep the indicator honest.
  Timer {
    interval: 30000
    running: true
    repeat: true
    onTriggered: if (!applyProcess.running) root.refresh()
  }

  Component.onCompleted: refresh()

  ShellIpc {
    target: "nightlight"

    function status(): string {
      return JSON.stringify({ enabled: root.enabled, temperature: root.temperature })
    }

    function refresh(): void {
      root.refresh()
    }

    function enable(): string {
      root.setNightlight(true)
      return "enabled"
    }

    function disable(): string {
      root.setNightlight(false)
      return "disabled"
    }

    function toggle(): string {
      var enabling = !root.enabled
      root.setNightlight(enabling)
      return enabling ? "enabled" : "disabled"
    }
  }
}
