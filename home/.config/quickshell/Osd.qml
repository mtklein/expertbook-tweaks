import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
  id: root
  property string icon: ""
  property int value: -1
  property string label: ""

  function show(name, amount, text) {
    var glyphs = {
      "brightness": "󰃠",
      "white-point": "󰔏",
      "keyboard": "󰌌",
      "volume": amount > 66 ? "󰕾" : (amount > 33 ? "󰖀" : "󰕿"),
      "muted": "󰝟",
      "microphone": "󰍬",
      "microphone-muted": "󰍭"
    }
    icon = glyphs[name] || name
    value = amount
    label = text
    hide.restart()
  }

  visible: hide.running
  color: "transparent"
  anchors.bottom: true
  margins.bottom: 40
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.namespace: "shell-osd"
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
  mask: Region {}
  implicitWidth: card.width
  implicitHeight: card.height

  Timer {
    id: hide
    interval: 1200
  }

  IpcHandler {
    target: "osd"
    function pop(name: string, amount: int, text: string): void { root.show(name, amount, text) }
  }

  Rectangle {
    id: card
    width: row.width + 32
    height: 44
    color: Theme.panelBackground
    border.color: Theme.panelBorder
    border.width: 1
    radius: Theme.radius

    Row {
      id: row
      anchors.centerIn: parent
      spacing: 12

      BarIcon {
        anchors.verticalCenter: parent.verticalCenter
        font.pixelSize: 18
        text: root.icon
      }

      Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        visible: root.value >= 0
        width: 142
        height: 4
        radius: 2
        color: Theme.hover
        Rectangle {
          width: parent.width * Math.max(0, Math.min(100, root.value)) / 100
          height: parent.height
          radius: 2
          color: Theme.barText
        }
      }

      BarText {
        anchors.verticalCenter: parent.verticalCenter
        visible: root.label !== ""
        width: root.value >= 0 ? 44 : implicitWidth
        horizontalAlignment: root.value >= 0 ? Text.AlignRight : Text.AlignLeft
        font.pixelSize: 13
        text: root.label
      }
    }
  }
}
