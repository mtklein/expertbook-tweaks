import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
  id: root
  required property Item anchorItem
  required property string name
  default property alias content: body.data
  property int panelWidth: 280
  readonly property int gap: 8
  readonly property bool open: Panels.open === name && Panels.owner === anchorItem
  property real centre: 0

  onOpenChanged: if (open) centre = anchorItem.mapToItem(null, anchorItem.width / 2, 0).x

  screen: anchorItem.QsWindow.window ? anchorItem.QsWindow.window.screen : null
  visible: open
  color: "transparent"
  anchors {
    left: true
    right: true
    top: true
    bottom: true
  }
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.namespace: "shell-panel"
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.AllButtons
    onClicked: Panels.close()
  }

  Rectangle {
    x: Math.max(root.gap, Math.min(root.width - width - root.gap, root.centre - width / 2))
    y: root.height - Theme.barHeight - root.gap - height
    width: root.panelWidth
    height: body.implicitHeight + 2 * Theme.pad
    color: Theme.panelBackground
    border.color: Theme.panelBorder
    border.width: 1
    radius: Theme.radius

    MouseArea {
      anchors.fill: parent
      acceptedButtons: Qt.AllButtons
    }

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
