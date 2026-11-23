import QtQuick
import Quickshell
import Quickshell.Hyprland

Row {
  id: root
  property var screen: null
  property real maxWidth: 0
  readonly property var monitor: screen ? Hyprland.monitorFor(screen) : Hyprland.focusedMonitor
  readonly property int activeId: monitor && monitor.activeWorkspace ? monitor.activeWorkspace.id : -1
  readonly property int numberWidth: 20
  readonly property int nameGap: 10
  readonly property int rowTolerance: 24

  function label(toplevel) {
    var ipc = toplevel.lastIpcObject || {}
    var appId = String(ipc["class"] || (toplevel.wayland ? toplevel.wayland.appId : "") || "")
    var entry = appId !== "" ? DesktopEntries.heuristicLookup(appId) : null
    var name = entry ? String(entry.name || "") : ""
    if (name === "" && appId !== "" && !/^steam_app_/.test(appId)) {
      var parts = appId.split(".")
      name = parts[parts.length - 1]
    }
    if (name === "") name = String(toplevel.title || "")
    return name.length > 24 ? name.slice(0, 23) + "…" : name
  }

  function place(toplevel) {
    var at = (toplevel.lastIpcObject || {}).at
    return at && at.length === 2 ? at : [1e9, 1e9]
  }

  readonly property var spaces: {
    var out = []
    DesktopEntries.applications.values.length
    var all = Hyprland.workspaces.values
    for (var i = 0; i < all.length; i++) {
      var ws = all[i]
      if (ws.id <= 0) continue
      if (ws.monitor && root.monitor && ws.monitor.name !== root.monitor.name) continue
      var windows = ws.toplevels.values.slice()
      if (ws.id !== root.activeId && windows.length === 0) continue
      windows.sort(function(a, b) {
        var pa = root.place(a)
        var pb = root.place(b)
        return Math.abs(pa[1] - pb[1]) > root.rowTolerance ? pa[1] - pb[1] : pa[0] - pb[0]
      })
      var names = []
      for (var j = 0; j < windows.length; j++) {
        var name = root.label(windows[j])
        if (name !== "") names.push({ name: name, address: String(windows[j].address || ""), focused: ws.id === root.activeId && windows[j].activated })
      }
      out.push({ id: ws.id, names: names })
    }
    out.sort(function(a, b) { return a.id - b.id })
    return out
  }

  readonly property bool numbered: spaces.length > 1
  readonly property int nameCount: {
    var n = 0
    for (var i = 0; i < spaces.length; i++) n += spaces[i].names.length
    return n
  }
  readonly property real fullWidth: {
    var w = numbered ? spaces.length * numberWidth : 0
    for (var i = 0; i < spaces.length; i++)
      for (var j = 0; j < spaces[i].names.length; j++)
        w += Math.ceil(metrics.advanceWidth(spaces[i].names[j].name)) + nameGap
    return w
  }
  readonly property bool named: nameCount > 0 && fullWidth <= maxWidth

  visible: numbered || named
  height: Theme.barHeight
  leftPadding: numbered ? 0 : 6

  function go(target) {
    Quickshell.execDetached(["hyprctl", "eval", "hl.dispatch(hl.dsp.focus({ " + target + " }))"])
  }

  FontMetrics {
    id: metrics
    font.family: Theme.textFont
    font.pixelSize: Theme.textSize
  }

  Timer {
    id: refresh
    interval: 150
    onTriggered: {
      Hyprland.refreshMonitors()
      Hyprland.refreshWorkspaces()
      Hyprland.refreshToplevels()
    }
  }

  Component.onCompleted: refresh.restart()

  Connections {
    target: Hyprland
    function onRawEvent(event) {
      var name = event ? String(event.name) : ""
      if (name === "workspacev2" || name === "moveworkspacev2" || name === "openwindow" || name === "closewindow"
          || name === "movewindowv2" || name === "activewindowv2" || name === "changefloatingmode" || name === "fullscreen") {
        refresh.restart()
      }
    }
  }

  Repeater {
    model: root.spaces
    Row {
      id: space
      required property var modelData
      height: Theme.barHeight

      Item {
        visible: root.numbered
        width: root.numberWidth
        height: Theme.barHeight
        opacity: space.modelData.id === root.activeId ? 1 : 0.5
        BarText {
          anchors.centerIn: parent
          text: String(space.modelData.id)
        }
        MouseArea {
          anchors.fill: parent
          onClicked: root.go("workspace = \"" + space.modelData.id + "\"")
        }
      }

      Repeater {
        model: root.named ? space.modelData.names : []
        BarText {
          required property var modelData
          text: modelData.name
          opacity: modelData.focused ? 1 : 0.5
          height: Theme.barHeight
          width: implicitWidth + root.nameGap
          MouseArea {
            anchors.fill: parent
            enabled: parent.modelData.address !== ""
            onClicked: root.go("window = \"address:0x" + parent.modelData.address + "\"")
          }
        }
      }
    }
  }
}
