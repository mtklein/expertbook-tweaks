import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets

Item {
  id: root
  property bool revealed: hover.hovered || linger.running || Panels.open === "bluetooth"
  height: Theme.barHeight
  width: Math.max(row.width, Theme.slot)

  HoverHandler {
    id: hover
    onHoveredChanged: if (!hovered) linger.restart()
  }

  Timer {
    id: linger
    interval: 600
  }

  Row {
    id: row
    anchors.right: parent.right
    height: Theme.barHeight

    Row {
      height: Theme.barHeight
      visible: root.revealed
      Repeater {
        model: SystemTray.items
        Item {
          id: entry
          required property var modelData
          width: Theme.slot
          height: Theme.barHeight
          IconImage {
            anchors.centerIn: parent
            implicitSize: 14
            source: entry.modelData.icon
          }
          MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: function(mouse) {
              if (mouse.button === Qt.RightButton && entry.modelData.hasMenu) {
                var point = entry.mapToItem(null, 0, 0)
                entry.modelData.display(entry.QsWindow.window, point.x, point.y)
              } else {
                entry.modelData.activate()
              }
            }
          }
        }
      }
      BluetoothIcon {}
      StayAwake {}
    }
  }
}
