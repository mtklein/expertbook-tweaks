import QtQuick
import Quickshell
import Quickshell.Hyprland

Row {
  id: root
  property var screen: null
  readonly property var monitor: screen ? Hyprland.monitorFor(screen) : Hyprland.focusedMonitor
  readonly property int activeId: monitor && monitor.activeWorkspace ? monitor.activeWorkspace.id : -1
  readonly property var ids: {
    var out = []
    var all = Hyprland.workspaces.values
    for (var i = 0; i < all.length; i++) {
      var ws = all[i]
      if (ws.id <= 0) continue
      if (ws.monitor && root.monitor && ws.monitor.name !== root.monitor.name) continue
      if (ws.id === root.activeId || ws.toplevels.values.length > 0) out.push(ws.id)
    }
    out.sort(function(a, b) { return a - b })
    return out
  }
  visible: ids.length > 1
  height: Theme.barHeight

  Connections {
    target: Hyprland
    function onRawEvent(event) {
      var name = event ? String(event.name) : ""
      if (name === "workspacev2" || name === "moveworkspacev2" || name === "openwindow" || name === "closewindow" || name === "movewindowv2") {
        Hyprland.refreshMonitors()
        Hyprland.refreshWorkspaces()
      }
    }
  }

  Repeater {
    model: root.ids
    Item {
      required property int modelData
      width: 20
      height: Theme.barHeight
      BarText {
        anchors.centerIn: parent
        text: String(parent.modelData)
        opacity: parent.modelData === root.activeId ? 1 : 0.5
      }
    }
  }
}
