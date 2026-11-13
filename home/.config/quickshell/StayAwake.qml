import QtQuick
import Quickshell
import Quickshell.Io

BarIcon {
  id: root
  readonly property string flag: Quickshell.env("HOME") + "/.local/state/stay-awake"
  property bool on: false
  height: Theme.barHeight
  text: "󰅶"
  opacity: on ? 1 : 0.45

  Process {
    id: check
    command: ["test", "-e", root.flag]
    running: true
    onExited: function(code) { root.on = code === 0 }
  }

  IpcHandler {
    target: "stayawake"
    function refresh(): void { check.running = true }
  }

  MouseArea {
    anchors.fill: parent
    onClicked: Quickshell.execDetached(["stay-awake", "toggle"])
  }
}
