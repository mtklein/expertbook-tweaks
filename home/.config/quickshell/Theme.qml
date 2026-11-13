pragma Singleton
import QtQuick
import Quickshell

Singleton {
  readonly property color barBackground: "#000000"
  readonly property color barText: "#d8d8d8"
  readonly property color active: "#ff5f57"
  readonly property color panelBackground: "#161618"
  readonly property color panelBorder: "#d3e3fd"
  readonly property color dimText: "#8e8e93"
  readonly property color selected: "#6aa8ff"
  readonly property color hover: "#2a2a2e"
  readonly property int barHeight: 26
  readonly property string textFont: "DejaVu Sans"
  readonly property string iconFont: "DejaVuSansM Nerd Font"
  readonly property int textSize: 12
  readonly property int iconSize: 13
  readonly property int slot: 27
  readonly property int pad: 10
  readonly property int radius: 6
  readonly property int rowHeight: 28
  readonly property string wallpaper: "/usr/share/sddm/themes/tiger/background.jpg"
}
