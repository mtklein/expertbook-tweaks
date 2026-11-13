pragma Singleton
import QtQuick
import Quickshell

Singleton {
  property string open: ""
  property var owner: null
  property string closed: ""
  property double closedAt: 0

  function close() {
    closed = open
    closedAt = Date.now()
    open = ""
  }

  function toggle(name, item) {
    if (open === name && owner === item) {
      close()
    } else if (!(closed === name && owner === item && Date.now() - closedAt < 250)) {
      owner = item
      open = name
    }
  }
}
