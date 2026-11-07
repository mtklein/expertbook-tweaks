import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Commons as Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "omarchy.active-window"


  readonly property var toplevel: ToplevelManager.activeToplevel
  // Mac menu bar style: the focused app's name in bold, not its window title
  // (which still shows as the tooltip).
  readonly property string windowTitle: toplevel ? (toplevel.title || "") : ""
  readonly property var entry: toplevel && toplevel.appId ? DesktopEntries.heuristicLookup(toplevel.appId) : null
  readonly property string title: {
    if (!toplevel) return ""
    if (entry && entry.name) return entry.name
    var id = String(toplevel.appId || "")
    id = id.split(".").pop()
    return id ? id.charAt(0).toUpperCase() + id.slice(1) : windowTitle
  }
  readonly property int maxLabelWidth: Number(setting("maxWidth", 280))

  visible: title !== "" && !vertical
  implicitWidth: visible ? Math.min(maxLabelWidth, labelText.implicitWidth) + Style.spacing.controlPaddingX * 2 : 0
  implicitHeight: barSize

  Behavior on implicitWidth {
    NumberAnimation { duration: Style.duration(180); easing.type: Easing.OutCubic }
  }

  Item {
    anchors.fill: parent
    anchors.leftMargin: Style.space(8)
    anchors.rightMargin: Style.space(8)
    clip: true

    Text {
      id: labelText
      textFormat: Text.PlainText
      anchors.verticalCenter: parent.verticalCenter
      anchors.left: parent.left
      width: parent.width
      text: root.title
      color: root.bar ? root.bar.barForeground : Commons.Color.foreground
      font.family: "Luxi Sans"   // Lucida Grande's free sibling, as in Tiger's menu bar
      font.pixelSize: Style.font.body
      elide: Text.ElideRight
      font.bold: true
    }
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
    cursorShape: Qt.PointingHandCursor

    onClicked: function(mouse) {
      if (!root.toplevel) return
      if (mouse.button === Qt.MiddleButton) {
        root.toplevel.close()
      } else if (mouse.button === Qt.RightButton) {
        root.toplevel.close()
      } else {
        root.toplevel.activate()
      }
    }
    onEntered: if (root.bar) root.bar.showTooltip(root, root.windowTitle || root.title)
    onExited: if (root.bar) root.bar.hideTooltip(root)
  }
}
