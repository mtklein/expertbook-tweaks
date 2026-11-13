import QtQuick
import Quickshell
import Quickshell.Bluetooth

BarIcon {
  readonly property var adapter: Bluetooth.defaultAdapter
  readonly property bool connected: {
    var devices = Bluetooth.devices ? Bluetooth.devices.values : []
    for (var i = 0; i < devices.length; i++) {
      if (devices[i].connected) return true
    }
    return false
  }
  height: Theme.barHeight
  visible: adapter !== null
  text: !adapter || !adapter.enabled ? "󰂲" : (connected ? "󰂱" : "󰂯")
}
