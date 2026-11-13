import QtQuick
import Quickshell
import Quickshell.Bluetooth

BarIcon {
  id: root
  readonly property var adapter: Bluetooth.defaultAdapter
  readonly property bool on: adapter !== null && adapter.enabled
  readonly property bool panelOpen: Panels.open === "bluetooth" && Panels.owner === root
  readonly property var devices: {
    var all = Bluetooth.devices ? Bluetooth.devices.values.slice() : []
    all = all.filter(function(d) { return d.paired || d.connected || root.title(d) !== "" })
    all.sort(function(a, b) {
      if (a.connected !== b.connected) return a.connected ? -1 : 1
      if (a.paired !== b.paired) return a.paired ? -1 : 1
      return root.title(a).localeCompare(root.title(b))
    })
    return all
  }
  function title(device) {
    var name = (device.name || device.deviceName || "").trim()
    return /^([0-9A-F]{2}-){5}[0-9A-F]{2}$/i.test(name) ? "" : name
  }

  property string forgetting: ""

  readonly property bool connected: devices.some(function(d) { return d.connected })

  height: Theme.barHeight
  visible: adapter !== null
  text: !on ? "󰂲" : (connected ? "󰂱" : "󰂯")

  onPanelOpenChanged: {
    forgetting = ""
    if (adapter && on) adapter.discovering = panelOpen
  }
  onOnChanged: if (adapter && on && panelOpen) adapter.discovering = true

  MouseArea {
    anchors.fill: parent
    onClicked: Panels.toggle("bluetooth", root)
  }

  Panel {
    name: "bluetooth"
    anchorItem: root

    PanelRow {
      icon: root.on ? "󰂯" : "󰂲"
      label: "Bluetooth"
      note: root.on ? "on" : "off"
      onClicked: Quickshell.execDetached(["rfkill", root.on ? "block" : "unblock", "bluetooth"])
    }

    Repeater {
      model: root.on ? root.devices.slice(0, 10) : []
      PanelRow {
        id: row
        required property var modelData
        icon: modelData.connected ? "󰂱" : (modelData.paired ? "󰂯" : "󰐕")
        label: root.title(modelData) || modelData.address
        strong: modelData.connected
        note: {
          if (root.forgetting === modelData.address) return "forget?"
          if (modelData.pairing) return "pairing…"
          if (modelData.state === BluetoothDeviceState.Connecting) return "connecting…"
          if (modelData.state === BluetoothDeviceState.Disconnecting) return "disconnecting…"
          if (modelData.connected) return modelData.batteryAvailable ? Math.round(modelData.battery * 100) + "%" : "connected"
          return modelData.paired ? "" : "new"
        }
        onRightClicked: root.forgetting = modelData.paired && root.forgetting !== modelData.address ? modelData.address : ""
        onClicked: {
          if (root.forgetting === modelData.address) {
            root.forgetting = ""
            modelData.forget()
            return
          }
          root.forgetting = ""
          if (modelData.connected) modelData.disconnect()
          else if (modelData.paired) modelData.connect()
          else {
            modelData.trusted = true
            modelData.pair()
          }
        }
      }
    }

    PanelRow {
      clickable: false
      visible: root.on && root.devices.length === 0
      label: "Looking for devices…"
    }
  }
}
