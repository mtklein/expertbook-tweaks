import QtQuick
import Quickshell
import Quickshell.Io

Row {
  id: root
  property string temperature: ""
  property string condition: ""
  visible: temperature !== ""
  height: Theme.barHeight
  spacing: 2

  function glyph(text) {
    var t = text.toLowerCase()
    if (t.indexOf("thunder") !== -1) return "󰖓"
    if (t.indexOf("snow") !== -1 || t.indexOf("sleet") !== -1 || t.indexOf("ice") !== -1) return "󰖘"
    if (t.indexOf("rain") !== -1 || t.indexOf("drizzle") !== -1 || t.indexOf("shower") !== -1) return "󰖗"
    if (t.indexOf("fog") !== -1 || t.indexOf("mist") !== -1 || t.indexOf("haze") !== -1) return "󰖑"
    if (t.indexOf("overcast") !== -1 || t.indexOf("cloudy") !== -1) return t.indexOf("partly") !== -1 ? "󰖕" : "󰖐"
    return "󰖨"
  }

  Process {
    id: fetch
    command: ["curl", "-fsS", "--max-time", "8", "https://wttr.in/?format=%t|%C"]
    running: true
    stdout: StdioCollector {
      onStreamFinished: {
        var parts = String(text).trim().split("|")
        if (parts.length === 2 && /^[+-]?\d+°/.test(parts[0])) {
          root.temperature = parts[0].replace(/^\+/, "").replace(/°.*/, "°")
          root.condition = parts[1]
        }
      }
    }
  }

  Timer {
    interval: 30 * 60 * 1000
    running: true
    repeat: true
    onTriggered: fetch.running = true
  }

  BarIcon {
    height: Theme.barHeight
    width: 20
    text: root.glyph(root.condition)
  }
  BarText {
    height: Theme.barHeight
    text: root.temperature
  }
}
