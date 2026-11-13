import QtQuick
import Quickshell
import Quickshell.Hyprland

PopupWindow {
  id: root
  required property Item anchorItem
  required property string name
  default property alias content: body.data
  property int panelWidth: 280
  readonly property int gap: 8
  readonly property bool open: Panels.open === name && Panels.owner === anchorItem

  visible: open
  color: "transparent"
  implicitWidth: panelWidth + 2 * gap
  implicitHeight: body.implicitHeight + 2 * Theme.pad + 2 * gap

  anchor.item: anchorItem
  anchor.edges: Edges.Top
  anchor.gravity: Edges.Top
  anchor.adjustment: PopupAdjustment.SlideX

  HyprlandFocusGrab {
    active: root.open
    windows: [root, root.anchorItem.QsWindow.window]
    onCleared: if (root.open) Panels.open = ""
  }

  Rectangle {
    anchors.fill: parent
    anchors.margins: root.gap
    color: Theme.panelBackground
    border.color: Theme.panelBorder
    border.width: 1
    radius: Theme.radius

    FocusScope {
      anchors.fill: parent
      focus: true
      Keys.onEscapePressed: Panels.open = ""

      Column {
        id: body
        x: Theme.pad
        y: Theme.pad
        width: parent.width - 2 * Theme.pad
      }
    }
  }
}
