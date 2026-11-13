import QtQuick
import Quickshell
import Quickshell.Io

BarIcon {
  id: root
  property string dictation: "idle"
  visible: dictation === "recording" || dictation === "transcribing"
  text: "󰍬"
  color: dictation === "recording" ? Theme.active : Theme.barText
  height: Theme.barHeight

  Process {
    id: follow
    command: [Quickshell.env("HOME") + "/.local/bin/voxtype-patched", "status", "--follow"]
    running: true
    stdout: SplitParser {
      onRead: function(line) {
        var s = String(line).trim()
        root.dictation = (s === "recording" || s === "transcribing") ? s : "idle"
      }
    }
    onExited: function() {
      root.dictation = "idle"
      retry.start()
    }
  }

  Timer {
    id: retry
    interval: 5000
    onTriggered: follow.running = true
  }
}
