import QtQuick
import Quickshell
import Quickshell.Wayland

Variants {
  model: Quickshell.screens

  PanelWindow {
    required property var modelData
    screen: modelData
    anchors {
      left: true
      right: true
      top: true
      bottom: true
    }
    color: "#000000"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "shell-wallpaper"

    Image {
      anchors.fill: parent
      source: Theme.wallpaper
      fillMode: Image.PreserveAspectCrop
      sourceSize.width: parent.width * 2
      sourceSize.height: parent.height * 2
    }

    Rectangle {
      id: nudge
      width: 1
      height: 1
      color: "#000000"
    }

    Timer {
      property int left: 3
      interval: 2500
      running: left > 0
      repeat: true
      onTriggered: {
        left -= 1
        nudge.color = left % 2 ? "#000001" : "#000000"
      }
    }
  }
}
