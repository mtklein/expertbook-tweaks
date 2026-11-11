import QtQuick 2.15
import SddmComponents 2.0

Rectangle {
  id: root
  width: 1440
  height: 900
  color: "#3b6ea5"

  readonly property string sans: "Luxi Sans"
  readonly property color ink: "#1d1d1f"
  readonly property color muted: "#6e6e73"
  readonly property color accent: "#0b57d0"
  readonly property color hairline: "#b4b4b4"

  property string currentUser: userModel.lastUser
  property string realName: ""
  property bool loginFailed: false
  property int sessionIndex: {
    for (var i = 0; i < sessionModel.rowCount(); i++) {
      var name = (sessionModel.data(sessionModel.index(i, 0), Qt.DisplayRole) || "").toString()
      if (name.indexOf("uwsm") !== -1)
        return i
    }
    return sessionModel.lastIndex
  }

  function logIn() {
    sddm.login(root.currentUser, password.text, root.sessionIndex)
  }

  Connections {
    target: sddm
    function onLoginFailed() {
      root.loginFailed = true
      password.text = ""
      password.forceActiveFocus()
      shake.restart()
    }
    function onLoginSucceeded() {
      root.loginFailed = false
    }
  }

  Repeater {
    model: userModel
    Item {
      Component.onCompleted: {
        if (root.currentUser === "") root.currentUser = model.name
        if (model.name === root.currentUser) root.realName = model.realName
      }
    }
  }

  Image {
    anchors.fill: parent
    source: "background.jpg"
    fillMode: Image.PreserveAspectCrop
    asynchronous: false
  }

  Item {
    id: panel
    width: 460
    height: content.height + 56
    x: Math.round((root.width - width) / 2)
    y: Math.round((root.height - height) / 2)

    SequentialAnimation {
      id: shake
      readonly property real home: Math.round((root.width - panel.width) / 2)
      NumberAnimation { target: panel; property: "x"; to: shake.home - 22; duration: 50 }
      NumberAnimation { target: panel; property: "x"; to: shake.home + 22; duration: 80 }
      NumberAnimation { target: panel; property: "x"; to: shake.home - 14; duration: 70 }
      NumberAnimation { target: panel; property: "x"; to: shake.home + 14; duration: 70 }
      NumberAnimation { target: panel; property: "x"; to: shake.home - 6; duration: 60 }
      NumberAnimation { target: panel; property: "x"; to: shake.home; duration: 50 }
    }

    Repeater {
      model: 6
      Rectangle {
        anchors.fill: parent
        anchors.margins: -index * 3
        anchors.topMargin: -index * 3 + 8
        anchors.bottomMargin: -index * 3 - 8
        radius: 12 + index * 3
        color: "#000000"
        opacity: 0.07 - index * 0.01
      }
    }

    Rectangle {
      anchors.fill: parent
      radius: 12
      color: "#f0f0f0"
      border.color: "#8e8e93"
      border.width: 1
    }

    Column {
      id: content
      width: parent.width - 72
      anchors.horizontalCenter: parent.horizontalCenter
      y: 28
      spacing: 18

      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: sddm.hostName
        visible: text !== ""
        font.family: root.sans
        font.pixelSize: 30
        font.bold: true
        color: root.ink
      }

      Rectangle { width: parent.width; height: 1; color: root.hairline }

      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: root.realName !== "" ? root.realName : root.currentUser
        font.family: root.sans
        font.pixelSize: 18
        color: root.ink
      }

      Rectangle {
        width: parent.width
        height: 34
        radius: 5
        color: "#ffffff"
        border.color: root.loginFailed ? "#c4261d" : (password.activeFocus ? root.accent : root.hairline)
        border.width: password.activeFocus || root.loginFailed ? 2 : 1

        TextInput {
          id: password
          anchors.fill: parent
          anchors.leftMargin: 10
          anchors.rightMargin: 10
          verticalAlignment: TextInput.AlignVCenter
          echoMode: TextInput.Password
          passwordCharacter: "•"
          font.family: root.sans
          font.pixelSize: 18
          color: root.ink
          selectionColor: "#b5d5ff"
          selectedTextColor: root.ink
          clip: true
          focus: true
          onTextChanged: root.loginFailed = false
          Keys.onPressed: function(event) {
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
              root.logIn()
              event.accepted = true
            }
          }
        }

        Text {
          anchors.fill: password
          verticalAlignment: Text.AlignVCenter
          visible: password.text === ""
          text: "Password"
          font.family: root.sans
          font.pixelSize: 16
          color: "#8e8e93"
        }
      }

      Row {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 10

        Repeater {
          model: [
            { label: "Sleep", act: function() { sddm.suspend() } },
            { label: "Restart", act: function() { sddm.reboot() } },
            { label: "Shut Down", act: function() { sddm.powerOff() } },
            { label: "Log In", act: function() { root.logIn() }, primary: true }
          ]

          Rectangle {
            readonly property bool primary: modelData.primary === true
            width: label.implicitWidth + 28
            height: 28
            radius: 14
            color: primary ? (press.pressed ? "#0842a0" : root.accent) : (press.pressed ? "#d4d4d4" : "#ffffff")
            border.color: primary ? "#0842a0" : root.hairline
            border.width: 1

            Text {
              id: label
              anchors.centerIn: parent
              text: modelData.label
              font.family: root.sans
              font.pixelSize: 14
              color: parent.primary ? "#ffffff" : root.ink
            }

            MouseArea {
              id: press
              anchors.fill: parent
              onClicked: modelData.act()
            }
          }
        }
      }
    }
  }

  Component.onCompleted: password.forceActiveFocus()
}
