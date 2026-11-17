import QtQuick

Flickable {
  id: root
  default property alias content: column.data
  property int rows: 10

  function reveal(item) {
    var bottom = item.mapToItem(column, 0, 0).y + item.height
    if (bottom > contentY + height) contentY = bottom - height
  }

  width: parent ? parent.width : 0
  height: Math.min(column.height, rows * Theme.rowHeight)
  contentHeight: column.height
  clip: true
  boundsBehavior: Flickable.StopAtBounds

  Column {
    id: column
    width: root.width
  }

  Rectangle {
    parent: root
    visible: root.visibleArea.heightRatio < 1
    x: root.width - width
    y: root.visibleArea.yPosition * root.height
    width: 2
    height: root.visibleArea.heightRatio * root.height
    radius: 1
    color: Theme.dimText
  }
}
