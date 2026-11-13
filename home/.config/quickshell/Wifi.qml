import QtQuick
import Quickshell
import Quickshell.Networking

BarIcon {
  id: root
  readonly property var device: {
    var all = Networking.devices ? Networking.devices.values : []
    for (var i = 0; i < all.length; i++) {
      if (all[i].type === DeviceType.Wifi) return all[i]
    }
    return null
  }
  readonly property bool on: Networking.wifiEnabled
  readonly property bool panelOpen: Panels.open === "wifi" && Panels.owner === root
  readonly property var networks: {
    var all = device && device.networks ? device.networks.values.slice() : []
    var best = {}
    for (var i = 0; i < all.length; i++) {
      var n = all[i]
      if (!n.name) continue
      var seen = best[n.name]
      if (!seen || (n.connected && !seen.connected) || (n.connected === seen.connected && n.signalStrength > seen.signalStrength)) best[n.name] = n
    }
    var list = Object.keys(best).map(function(k) { return best[k] })
    list.sort(function(a, b) {
      if (a.connected !== b.connected) return a.connected ? -1 : 1
      if (a.known !== b.known) return a.known ? -1 : 1
      return b.signalStrength - a.signalStrength
    })
    return list
  }
  readonly property var current: {
    for (var i = 0; i < networks.length; i++) {
      if (networks[i].connected) return networks[i]
    }
    return null
  }
  property string asking: ""
  property string failed: ""
  property string forgetting: ""

  function bars(strength) {
    var glyphs = ["󰤯", "󰤟", "󰤢", "󰤥", "󰤨"]
    return glyphs[Math.max(0, Math.min(4, Math.round(strength * 4)))]
  }

  function open(network) {
    return network.security === WifiSecurityType.Open || network.security === WifiSecurityType.Owe
  }

  function syncScanner() {
    if (device) device.scannerEnabled = panelOpen && on
  }

  height: Theme.barHeight
  text: !on ? "󰤭" : (current ? bars(current.signalStrength) : "󰤮")

  onPanelOpenChanged: {
    asking = ""
    forgetting = ""
    failed = ""
    syncScanner()
  }
  onOnChanged: syncScanner()
  onDeviceChanged: syncScanner()

  MouseArea {
    anchors.fill: parent
    onClicked: Panels.toggle("wifi", root)
  }

  Panel {
    name: "wifi"
    anchorItem: root

    PanelRow {
      icon: root.on ? "󰤨" : "󰤭"
      label: "Wi-Fi"
      note: root.on ? "on" : "off"
      onClicked: Networking.wifiEnabled = !Networking.wifiEnabled
    }

    Repeater {
      model: root.on ? root.networks.slice(0, 12) : []
      Column {
        id: entry
        required property var modelData
        width: parent.width

        Connections {
          target: entry.modelData
          function onConnectionFailed(reason) {
            root.failed = entry.modelData.name
            if (!root.open(entry.modelData)) root.asking = entry.modelData.name
          }
          function onConnectedChanged() {
            if (entry.modelData.connected && root.failed === entry.modelData.name) root.failed = ""
          }
        }

        PanelRow {
          icon: root.bars(entry.modelData.signalStrength)
          label: entry.modelData.name
          strong: entry.modelData.connected
          note: {
            if (root.forgetting === entry.modelData.name) return "forget?"
            if (entry.modelData.stateChanging) return entry.modelData.connected ? "leaving…" : "joining…"
            if (entry.modelData.connected) return "connected"
            if (root.failed === entry.modelData.name) return "could not join"
            return root.open(entry.modelData) ? "open" : (entry.modelData.known ? "" : "󰌾")
          }
          onRightClicked: {
            root.asking = ""
            root.forgetting = entry.modelData.known && root.forgetting !== entry.modelData.name ? entry.modelData.name : ""
          }
          onClicked: {
            if (root.forgetting === entry.modelData.name) {
              root.forgetting = ""
              entry.modelData.forget()
              return
            }
            root.forgetting = ""
            if (entry.modelData.connected) return
            root.failed = ""
            if (entry.modelData.known || root.open(entry.modelData)) {
              root.asking = ""
              entry.modelData.connect()
            } else {
              root.asking = root.asking === entry.modelData.name ? "" : entry.modelData.name
            }
          }
        }

        Rectangle {
          visible: root.asking === entry.modelData.name
          width: parent.width
          height: Theme.rowHeight
          radius: 4
          color: Theme.hover
          onVisibleChanged: if (visible) password.forceActiveFocus()

          TextInput {
            id: password
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            verticalAlignment: TextInput.AlignVCenter
            clip: true
            echoMode: TextInput.Password
            color: Theme.barText
            font.family: Theme.textFont
            font.pixelSize: Theme.textSize
            onAccepted: {
              if (text.length === 0) return
              root.failed = ""
              root.asking = ""
              entry.modelData.connectWithPsk(text)
              text = ""
            }
          }

          BarText {
            anchors.fill: password
            visible: password.text.length === 0
            text: "Password"
            color: Theme.dimText
          }
        }
      }
    }

    PanelRow {
      clickable: false
      visible: root.on && root.networks.length === 0
      label: "Looking for networks…"
    }
  }
}
