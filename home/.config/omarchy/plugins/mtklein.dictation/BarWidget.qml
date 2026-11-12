import QtQuick
import Quickshell.Io
import qs.Ui
import qs.Commons

BarWidget {
  id: root
  moduleName: "mtklein.dictation"

  property string dictation: "idle"
  readonly property bool recording: dictation === "recording"
  readonly property bool busy: recording || dictation === "transcribing"

  function read(line) {
    var s = String(line).trim()
    if (s.charAt(0) === "{") {
      try {
        var o = JSON.parse(s)
        s = String(o.class || o.alt || o.state || "")
      } catch (e) {
        s = ""
      }
    }
    dictation = (s === "recording" || s === "transcribing") ? s : "idle"
  }

  visible: busy
  implicitWidth: busy ? button.implicitWidth : 0
  implicitHeight: button.implicitHeight

  Process {
    id: follow
    command: ["voxtype", "status", "--follow"]
    running: true
    stdout: SplitParser { onRead: function(line) { root.read(line) } }
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

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "󰍬"
    active: root.recording
    tooltipText: root.recording ? "Recording" : "Transcribing"
  }
}
