import QtQuick
import Quickshell.Io
import "NightlightModel.js" as NightlightModel
import qs.Commons

Item {
  id: root

  // Injected by omarchy-shell (the first-party service loader).
  property var shell: null

  // 3300 K, in real kelvin (the patched Hyprland applies the white point in
  // linear light). Matches NIGHT_TEMP in ~/expertbook-tweaks/bin/ambient-display;
  // 6600 K is its neutral.
  readonly property int nightTemperature: 3300
  readonly property int dayTemperature: 6600

  property bool stateLoaded: false
  property var temperature: null
  readonly property bool enabled: stateLoaded && NightlightModel.isNightlight(temperature)

  function refresh() {
    if (!statusProbe.running) statusProbe.running = true
  }

  // ~/expertbook-tweaks/bin/ambient-display owns the white point; a manual toggle
  // records an override it honours until the room next changes dark <-> lit.
  function setNightlight(value) {
    overrideProcess.command = ["sh", "-c",
      "mkdir -p \"${XDG_STATE_HOME:-$HOME/.local/state}\" && printf %s " + (value ? "night" : "day") +
      " > \"${XDG_STATE_HOME:-$HOME/.local/state}/ambient-white.override\""]
    overrideProcess.running = true
    root.temperature = value ? nightTemperature : dayTemperature
    root.stateLoaded = true
  }

  function toggle() {
    setNightlight(!enabled)
  }

  Process {
    id: statusProbe
    command: ["sh", "-c", "cat \"${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/white-point\""]
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

  // ~/expertbook-tweaks/bin/ambient-display changes the white point on its own
  // (dark room -> night light), so re-read it every 30 s.
  Timer {
    interval: 30000
    running: true
    repeat: true
    onTriggered: root.refresh()
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
