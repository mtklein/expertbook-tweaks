import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

PanelWindow {
  id: root
  required property Item anchorItem
  required property string name
  default property alias content: body.data
  property int panelWidth: 280
  readonly property int gap: 8
  readonly property bool open: Panels.open === name && Panels.owner === anchorItem
  property real offset: 0

  function place() {
    var bar = anchorItem.QsWindow.window
    if (!bar) return
    var centre = anchorItem.mapToItem(null, anchorItem.width / 2, 0).x
    offset = Math.max(0, bar.width - centre - implicitWidth / 2)
  }

  onOpenChanged: if (open) place()

  screen: anchorItem.QsWindow.window ? anchorItem.QsWindow.window.screen : null
  visible: open
  color: "transparent"
  anchors.bottom: true
  anchors.right: true
  margins.right: offset
  implicitWidth: panelWidth + 2 * gap
  implicitHeight: body.implicitHeight + 2 * Theme.pad + 2 * gap
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.namespace: "shell-panel"
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

  HyprlandFocusGrab {
    active: root.open
    windows: [root]
    onCleared: if (root.open) Panels.close()
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
      Keys.onEscapePressed: Panels.close()

      Column {
        id: body
        x: Theme.pad
        y: Theme.pad
        width: parent.width - 2 * Theme.pad
      }
    }
  }
}
