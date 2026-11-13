import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets

PanelWindow {
  id: root
  property bool open: false
  readonly property var power: [
    { name: "Sleep", words: "sleep suspend", glyph: "󰒲", command: ["systemctl", "suspend-then-hibernate"] },
    { name: "Log Out", words: "log out logout", glyph: "󰍃", command: ["uwsm", "stop"] },
    { name: "Restart", words: "restart reboot", glyph: "󰜉", command: ["systemctl", "reboot"] },
    { name: "Shut Down", words: "shut down shutdown power off poweroff", glyph: "󰐥", command: ["systemctl", "poweroff"] }
  ]
  readonly property var entries: {
    var needle = filter.text.trim().toLowerCase()
    var apps = []
    var all = DesktopEntries.applications.values
    for (var i = 0; i < all.length; i++) {
      var e = all[i]
      if (e.noDisplay) continue
      var name = e.name.toLowerCase()
      var rank = needle === "" ? 1 : (name.indexOf(needle) === 0 ? 0 : (name.indexOf(needle) > 0 ? 1 : ((e.genericName || "").toLowerCase().indexOf(needle) >= 0 ? 2 : -1)))
      if (rank < 0) continue
      apps.push({ name: e.name, rank: rank, entry: e })
    }
    apps.sort(function(a, b) { return a.rank - b.rank || a.name.localeCompare(b.name) })
    for (var j = 0; j < power.length; j++) {
      if (needle === "" || power[j].words.indexOf(needle) >= 0) apps.push(power[j])
    }
    return apps
  }

  function show() {
    if (open) {
      open = false
      return
    }
    filter.text = ""
    list.currentIndex = 0
    open = true
  }

  function run(item) {
    if (!item) return
    open = false
    if (item.command) Quickshell.execDetached(item.command)
    else Quickshell.execDetached(["uwsm-app", "--", item.entry.id + ".desktop"])
  }

  visible: open
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.namespace: "shell-menu"
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
  anchors.top: true
  margins.top: 140
  implicitWidth: 360
  implicitHeight: 2 * Theme.pad + 11 * Theme.rowHeight + 6

  onOpenChanged: if (open) filter.forceActiveFocus()

  HyprlandFocusGrab {
    active: root.open
    windows: [root]
    onCleared: root.open = false
  }

  GlobalShortcut {
    appid: "shell"
    name: "menu"
    description: "Menu"
    onPressed: root.show()
  }

  IpcHandler {
    target: "menu"
    function open(): void { root.show() }
  }

  MouseArea {
    anchors.fill: parent
    onClicked: root.open = false
  }

  Rectangle {
    id: card
    width: parent.width
    height: column.height + 2 * Theme.pad
    color: Theme.panelBackground
    radius: Theme.radius
    clip: true
    Behavior on height { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }

    MouseArea {
      anchors.fill: parent
    }

    Column {
      id: column
      x: Theme.pad
      y: Theme.pad
      width: parent.width - 2 * Theme.pad
      spacing: 6

      Item {
        width: parent.width
        height: Theme.rowHeight

        TextInput {
          id: filter
          anchors.fill: parent
          anchors.leftMargin: 8
          anchors.rightMargin: 8
          verticalAlignment: TextInput.AlignVCenter
          clip: true
          color: Theme.barText
          font.family: Theme.textFont
          font.pixelSize: 14
          onTextChanged: list.currentIndex = 0
          onAccepted: root.run(root.entries[list.currentIndex])
          Keys.onEscapePressed: root.open = false
          Keys.onDownPressed: list.currentIndex = Math.min(list.count - 1, list.currentIndex + 1)
          Keys.onUpPressed: list.currentIndex = Math.max(0, list.currentIndex - 1)
        }

        BarText {
          anchors.fill: filter
          visible: filter.text.length === 0
          font.pixelSize: 14
          text: "Search"
          color: Theme.dimText
        }
      }

      ListView {
        id: list
        width: parent.width
        height: Math.min(count, 10) * Theme.rowHeight
        clip: true
        model: root.entries
        boundsBehavior: Flickable.StopAtBounds
        highlightMoveDuration: 0
        delegate: Rectangle {
          id: row
          required property var modelData
          required property int index
          width: list.width
          height: Theme.rowHeight
          radius: 4
          color: ListView.isCurrentItem ? Theme.hover : "transparent"

          IconImage {
            x: 6
            anchors.verticalCenter: parent.verticalCenter
            implicitSize: 18
            visible: !row.modelData.glyph
            source: row.modelData.entry ? Quickshell.iconPath(row.modelData.entry.icon, true) : ""
          }

          BarIcon {
            x: 2
            anchors.verticalCenter: parent.verticalCenter
            visible: !!row.modelData.glyph
            text: row.modelData.glyph || ""
          }

          BarText {
            anchors.left: parent.left
            anchors.leftMargin: 34
            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            font.pixelSize: 13
            text: row.modelData.name
            elide: Text.ElideRight
          }

          MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onPositionChanged: list.currentIndex = row.index
            onClicked: root.run(row.modelData)
          }
        }
      }
    }
  }
}
