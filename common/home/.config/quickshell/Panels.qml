pragma Singleton
import QtQuick
import Quickshell

Singleton {
  property string open: ""
  property var owner: null

  function close() { open = "" }

  function toggle(name, item) {
    if (open === name && owner === item) {
      open = ""
    } else {
      owner = item
      open = name
    }
  }
}
