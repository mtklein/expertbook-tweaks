import QtQuick
import Quickshell
import Quickshell.Io

BarText {
  id: root
  property bool on: false
  visible: on
  height: Theme.barHeight
  width: Theme.slot
  horizontalAlignment: Text.AlignHCenter
  color: Theme.attention
  font.bold: true
  font.pixelSize: Theme.textSize + 3
  text: "?"

  Process {
    id: check
    command: ["sh", "-c", "test -e ~/.config/attention-bar && attention status"]
    running: true
    stdout: StdioCollector { onStreamFinished: root.on = /^on$/m.test(String(text)) }
  }

  IpcHandler {
    target: "attention"
    function refresh(): void { check.running = true }
  }
}
