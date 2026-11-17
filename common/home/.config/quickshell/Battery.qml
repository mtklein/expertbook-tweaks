import QtQuick
import Quickshell
import Quickshell.Services.UPower

BarIcon {
  id: root
  readonly property var battery: UPower.displayDevice
  readonly property real level: battery ? battery.percentage : 1
  readonly property bool plugged: !UPower.onBattery
  readonly property real rate: battery ? Math.abs(battery.changeRate) : 0
  readonly property bool charging: battery && battery.state === UPowerDeviceState.Charging
  readonly property bool discharging: battery && battery.state === UPowerDeviceState.Discharging

  function duration(seconds) {
    var minutes = Math.round(seconds / 60)
    var hours = Math.floor(minutes / 60)
    minutes -= hours * 60
    return hours > 0 ? hours + " h " + (minutes < 10 ? "0" : "") + minutes + " min" : minutes + " min"
  }

  height: Theme.barHeight
  text: {
    var plain = ["󰂎", "󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"]
    var powered = ["󰢟", "󰢜", "󰂆", "󰂇", "󰂈", "󰢝", "󰂉", "󰢞", "󰂊", "󰂋", "󰂅"]
    var i = Math.max(0, Math.min(10, Math.round(level * 10)))
    return plugged ? powered[i] : plain[i]
  }
  color: !plugged && level <= 0.1 ? Theme.active : Theme.barText

  MouseArea {
    anchors.fill: parent
    onClicked: Panels.toggle("battery", root)
  }

  Panel {
    name: "battery"
    anchorItem: root
    panelWidth: 220

    PanelRow {
      clickable: false
      label: Math.round(root.level * 100) + "%"
      note: root.charging ? "charging" : (root.discharging ? "on battery" : "plugged in")
    }
    PanelRow {
      clickable: false
      visible: root.rate >= 0.05 && (root.charging || root.discharging)
      label: root.rate.toFixed(1) + " W"
      note: root.charging ? "in" : "out"
    }
    PanelRow {
      clickable: false
      readonly property real seconds: root.battery ? (root.charging ? root.battery.timeToFull : root.battery.timeToEmpty) : 0
      visible: seconds > 0 && (root.charging || root.discharging)
      label: root.duration(seconds)
      note: root.charging ? "until full" : "left"
    }
  }
}
