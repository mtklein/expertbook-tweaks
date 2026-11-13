import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Pipewire

Scope {
  id: root
  required property var osd
  readonly property var sink: Pipewire.defaultAudioSink
  readonly property var source: Pipewire.defaultAudioSource

  function report() {
    if (!sink || !sink.audio) return
    var percent = Math.round(sink.audio.volume * 100)
    osd.show(sink.audio.muted ? "muted" : "volume", percent, percent + "%")
  }

  function step(amount) {
    if (!sink || !sink.audio) return
    sink.audio.muted = false
    sink.audio.volume = Math.max(0, Math.min(1, Math.round((sink.audio.volume + amount) * 20) / 20))
    report()
  }

  PwObjectTracker {
    objects: [root.sink, root.source]
  }

  GlobalShortcut {
    appid: "shell"
    name: "volume-up"
    description: "Volume up"
    onPressed: root.step(0.05)
  }

  GlobalShortcut {
    appid: "shell"
    name: "volume-down"
    description: "Volume down"
    onPressed: root.step(-0.05)
  }

  GlobalShortcut {
    appid: "shell"
    name: "mute"
    description: "Mute"
    onPressed: {
      if (!root.sink || !root.sink.audio) return
      root.sink.audio.muted = !root.sink.audio.muted
      root.report()
    }
  }

  GlobalShortcut {
    appid: "shell"
    name: "microphone-mute"
    description: "Mute microphone"
    onPressed: {
      if (!root.source || !root.source.audio) return
      root.source.audio.muted = !root.source.audio.muted
      root.osd.show(root.source.audio.muted ? "microphone-muted" : "microphone", -1, root.source.audio.muted ? "Microphone off" : "Microphone on")
    }
  }
}
