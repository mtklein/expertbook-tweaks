import QtQuick
import Quickshell
import Quickshell.Services.Polkit
import Quickshell.Wayland

PanelWindow {
  id: root
  readonly property var flow: agent.flow
  readonly property bool fingerWaiting: flow !== null && !flow.supplementaryIsError && !flow.failed && /finger/i.test(flow.supplementaryMessage)

  visible: agent.isActive
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.namespace: "shell-polkit"
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
  implicitWidth: 380
  implicitHeight: card.height

  onVisibleChanged: {
    answer.text = ""
    if (visible) answer.forceActiveFocus()
  }

  PolkitAgent {
    id: agent
    path: "/org/expertbook/PolkitAgent"
    onIsRegisteredChanged: if (!isRegistered) console.warn("permission prompt is not registered; another agent may be running")
  }

  Rectangle {
    id: card
    width: parent.width
    height: column.height + 2 * 16
    color: Theme.panelBackground
    radius: Theme.radius

    Column {
      id: column
      x: 16
      y: 16
      width: parent.width - 32
      spacing: 10

      BarText {
        width: parent.width
        font.pixelSize: 13
        wrapMode: Text.WordWrap
        text: root.flow ? root.flow.message : ""
      }

      BarText {
        width: parent.width
        visible: text !== ""
        wrapMode: Text.WordWrap
        color: root.flow && (root.flow.supplementaryIsError || root.flow.failed) ? Theme.active : Theme.dimText
        text: {
          if (!root.flow || root.fingerWaiting) return ""
          if (root.flow.supplementaryMessage !== "") return root.flow.supplementaryMessage
          return root.flow.failed ? "That did not work. Try again." : ""
        }
      }

      Rectangle {
        width: parent.width
        height: 32
        radius: 4
        color: Theme.hover
        opacity: root.flow && (root.flow.isResponseRequired || root.fingerWaiting) ? 1 : 0.4

        TextInput {
          id: answer
          anchors.fill: parent
          anchors.leftMargin: 8
          anchors.rightMargin: 8
          verticalAlignment: TextInput.AlignVCenter
          clip: true
          focus: true
          echoMode: root.flow && root.flow.responseVisible ? TextInput.Normal : TextInput.Password
          color: Theme.barText
          font.family: Theme.textFont
          font.pixelSize: 13
          onAccepted: {
            if (!root.flow || !root.flow.isResponseRequired) return
            var typed = text
            text = ""
            root.flow.submit(typed)
          }
          Keys.onEscapePressed: if (root.flow) root.flow.cancelAuthenticationRequest()
        }

        BarIcon {
          anchors.right: parent.right
          anchors.rightMargin: 4
          anchors.verticalCenter: parent.verticalCenter
          text: "󰈷"
          color: Theme.dimText
          font.pixelSize: 16
          opacity: root.fingerWaiting && answer.text.length === 0 ? 1 : 0
          Behavior on opacity { NumberAnimation { duration: 120 } }
        }

        BarText {
          anchors.fill: answer
          visible: answer.text.length === 0
          color: Theme.dimText
          text: root.flow && root.flow.inputPrompt !== "" ? root.flow.inputPrompt.replace(/:\s*$/, "") : "Password"
        }
      }
    }
  }
}
