import QtQuick
import Quickshell
import Quickshell.Services.UPower

BarIcon {
  readonly property var battery: UPower.displayDevice
  readonly property real level: battery ? battery.percentage : 1
  readonly property bool charging: battery && (battery.state === UPowerDeviceState.Charging || battery.state === UPowerDeviceState.FullyCharged || battery.state === UPowerDeviceState.PendingCharge)
  height: Theme.barHeight
  text: {
    var plain = ["󰂎", "󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"]
    var plugged = ["󰢟", "󰢜", "󰂆", "󰂇", "󰂈", "󰢝", "󰂉", "󰢞", "󰂊", "󰂋", "󰂅"]
    var i = Math.max(0, Math.min(10, Math.round(level * 10)))
    return charging ? plugged[i] : plain[i]
  }
  color: !charging && level <= 0.1 ? Theme.active : Theme.barText
}
