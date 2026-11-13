import QtQuick

Rectangle {
  id: root
  property string icon: ""
  property string label: ""
  property string note: ""
  property bool strong: false
  property bool clickable: true
  signal clicked()
  signal rightClicked()

  width: parent ? parent.width : 0
  height: Theme.rowHeight
  radius: 4
  color: clickable && area.containsMouse ? Theme.hover : "transparent"

  BarIcon {
    id: glyph
    anchors.verticalCenter: parent.verticalCenter
    text: root.icon
    visible: root.icon !== ""
  }

  BarText {
    anchors.left: parent.left
    anchors.leftMargin: root.icon !== "" ? Theme.slot + 2 : 8
    anchors.right: noteText.left
    anchors.rightMargin: 8
    anchors.verticalCenter: parent.verticalCenter
    text: root.label
    color: root.strong ? Theme.selected : Theme.barText
    elide: Text.ElideRight
  }

  BarText {
    id: noteText
    anchors.right: parent.right
    anchors.rightMargin: 8
    anchors.verticalCenter: parent.verticalCenter
    text: root.note
    color: Theme.dimText
  }

  MouseArea {
    id: area
    anchors.fill: parent
    hoverEnabled: true
    enabled: root.clickable
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    onClicked: function(mouse) {
      if (mouse.button === Qt.RightButton) root.rightClicked()
      else root.clicked()
    }
  }
}
