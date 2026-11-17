import QtQuick
import Quickshell
import Quickshell.Io

BarIcon {
  id: root
  property bool echo: false
  property bool isolate: false
  property bool testing: false
  property bool listening: false
  readonly property bool busy: change.running

  height: Theme.barHeight
  text: "󰍬"
  opacity: echo || isolate ? 1 : 0.45

  function read(text) {
    echo = /^echo on$/m.test(text)
    isolate = /^isolate on$/m.test(text)
  }

  function flip(name) {
    if (busy) return
    change.command = ["mic-mode", name, "toggle"]
    change.running = true
  }

  Process {
    id: status
    command: ["mic-mode", "status"]
    running: true
    stdout: StdioCollector { onStreamFinished: root.read(String(text)) }
  }

  Process {
    id: change
    stdout: StdioCollector { onStreamFinished: root.read(String(text)) }
  }

  Process {
    id: test
    command: ["mic-test", "record"]
    onExited: root.testing = false
  }

  Process {
    id: playback
    command: ["mic-test", "listen"]
    onExited: root.listening = false
  }

  IpcHandler {
    target: "mic"
    function refresh(): void { status.running = true }
  }

  MouseArea {
    anchors.fill: parent
    onClicked: Panels.toggle("microphone", root)
  }

  Panel {
    name: "microphone"
    anchorItem: root

    PanelRow {
      icon: "󱄠"
      label: "Echo cancellation"
      strong: root.echo
      note: root.echo ? "on" : "off"
      onClicked: root.flip("echo")
    }

    PanelRow {
      icon: "󰗋"
      label: "Voice isolation"
      strong: root.isolate
      note: root.isolate ? "on" : "off"
      onClicked: root.flip("isolate")
    }

    PanelRow {
      icon: "󰑊"
      label: "Record a test"
      note: root.testing ? "recording…" : ""
      onClicked: {
        if (root.testing || root.listening) return
        root.testing = true
        test.running = true
      }
    }

    PanelRow {
      icon: "󰐊"
      label: "Play the test back"
      note: root.listening ? "raw, then processed…" : ""
      onClicked: {
        if (root.testing || root.listening) return
        root.listening = true
        playback.running = true
      }
    }
  }
}
