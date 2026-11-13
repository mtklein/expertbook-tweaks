import QtQuick
import Quickshell

Variants {
  model: Quickshell.screens

  PanelWindow {
    id: bar
    required property var modelData
    screen: modelData
    anchors {
      left: true
      right: true
      bottom: true
    }
    implicitHeight: Theme.barHeight
    color: Theme.barBackground

    Workspaces {
      anchors.left: parent.left
      anchors.leftMargin: 8
      screen: bar.modelData
    }

    Dictation {
      anchors.horizontalCenter: parent.horizontalCenter
    }

    Row {
      anchors.right: parent.right
      anchors.rightMargin: 12
      height: Theme.barHeight
      spacing: 4
      Weather {}
      Battery {}
      Item { width: 6; height: 1 }
      Clock {}
    }
  }
}
