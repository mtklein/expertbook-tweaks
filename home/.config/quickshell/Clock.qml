import QtQuick
import Quickshell

BarText {
  height: Theme.barHeight
  text: Qt.formatDateTime(clock.date, "ddd h:mm AP")
  SystemClock {
    id: clock
    precision: SystemClock.Minutes
  }
}
