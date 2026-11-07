import QtQuick
import Quickshell
import Quickshell.Io
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

  // A slow app launch (one whose window takes over 2 s): mtklein.osd raises this
  // flag instead of showing Omarchy's "Launching <app>…" box.
  property bool launching: false
  FileView {
    path: Quickshell.env("XDG_RUNTIME_DIR") + "/omarchy-launching"
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: root.launching = text().trim() === "1"
    onLoadFailed: root.launching = false
  }
  Timer {  // in case the launcher never says it's done
    running: root.launching
    interval: 20000
    onTriggered: root.launching = false
  }

  readonly property real spinnerSize: Math.round(Style.font.body * 1.15)
  readonly property real spinnerExtent: launching ? spinnerSize + Style.space(6) : 0

  visible: (title !== "" || launching) && !vertical
  implicitWidth: visible ? Math.min(maxLabelWidth, labelText.implicitWidth) + spinnerExtent + Style.spacing.controlPaddingX * 2 : 0
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
      width: parent.width - root.spinnerExtent
      text: root.title
      color: root.bar ? root.bar.barForeground : Commons.Color.foreground
      font.family: "Luxi Sans"   // Lucida Grande's free sibling, as in Tiger's menu bar
      font.pixelSize: Style.font.body
      elide: Text.ElideRight
      font.bold: true
    }

    // Tiger's progress spinner: twelve spokes fading round the dial, stepping
    // a spoke at a time.
    Canvas {
      id: spinner
      visible: root.launching
      width: root.spinnerSize
      height: root.spinnerSize
      anchors.verticalCenter: parent.verticalCenter
      anchors.right: parent.right
      property color ink: root.bar ? root.bar.barForeground : Commons.Color.foreground
      onInkChanged: requestPaint()
      onPaint: {
        var ctx = getContext("2d")
        ctx.reset()
        var c = width / 2
        ctx.lineCap = "round"
        ctx.lineWidth = Math.max(1.5, width * 0.11)
        for (var i = 0; i < 12; i++) {
          var a = i * Math.PI / 6
          ctx.globalAlpha = 0.15 + 0.85 * (i / 11)
          ctx.strokeStyle = ink
          ctx.beginPath()
          ctx.moveTo(c + Math.sin(a) * c * 0.45, c - Math.cos(a) * c * 0.45)
          ctx.lineTo(c + Math.sin(a) * c * 0.92, c - Math.cos(a) * c * 0.92)
          ctx.stroke()
        }
      }
      Timer {
        running: spinner.visible && Style.duration(1000) > 0
        interval: 83          // a spoke per tick: one turn a second
        repeat: true
        onTriggered: spinner.rotation = (spinner.rotation + 30) % 360
      }
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
