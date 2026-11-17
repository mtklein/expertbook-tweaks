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
  }
}
