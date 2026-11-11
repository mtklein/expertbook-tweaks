import QtQuick
import QtQuick.Effects
import SddmComponents 2.0

Rectangle {
  id: root
  width: 1800
  height: 1125
  color: "#000000"

  readonly property string fontFamily: "DejaVuSansM Nerd Font"
  readonly property int fieldWidth: 381
  readonly property int fieldHeight: 67
  readonly property int outlineThickness: 3
  readonly property int cornerRadius: 6
  readonly property int fieldFontSize: 18
  readonly property int passwordDotFontSize: 21
  readonly property int passwordDotLetterSpacing: 3
  readonly property color fieldColor: Qt.rgba(0x16 / 255, 0x16 / 255, 0x18 / 255, 0.8)
  readonly property color textColor: "#d8d8d8"
  readonly property color placeholderColor: "#8e8e93"
  readonly property color errorColor: "#ff5f57"
  readonly property color borderColor: "#d3e3fd"
  readonly property color selectionColor: Qt.rgba(0x6a / 255, 0xa8 / 255, 0xff / 255, 0.45)

  property string currentUser: userModel.lastUser
  property int failedAttempts: 0
  property string failureMessage: ""
  property int sessionIndex: {
    for (var i = 0; i < sessionModel.rowCount(); i++) {
      var name = (sessionModel.data(sessionModel.index(i, 0), Qt.DisplayRole) || "").toString()
      if (name.indexOf("uwsm") !== -1)
        return i
    }
    return sessionModel.lastIndex
  }
  readonly property real passwordDotScale: dotMetrics.advanceWidth > 0
    ? Math.min(1, (passwordInput.width - 4) / dotMetrics.advanceWidth)
    : 1
  readonly property real fingerprintReserve: Math.round(fingerprintIcon.implicitWidth + 12)

  readonly property bool canCancel: sddm.canCancelLogin === true
  property bool fingerprintAvailable: true
  property bool idle: false
  property bool authenticating: false
  property bool listening: false
  property bool readerLive: false
  property double listeningSince: 0
  property double ignoreFailuresUntil: 0

  readonly property bool wantFinger: canCancel && fingerprintAvailable && !idle && !authenticating
    && passwordInput.text.length === 0 && currentUser !== ""

  onWantFingerChanged: syncFingerprint()

  function syncFingerprint() {
    if (wantFinger && !listening && !settle.running) {
      listening = true
      listeningSince = Date.now()
      sddm.login(currentUser, "", sessionIndex)
    } else if (!wantFinger && listening) {
      listening = false
      readerLive = false
      sddm.cancelLogin()
    }
  }

  function submitPassword(password) {
    authenticating = true
    passwordWatchdog.restart()
    sddm.login(currentUser, password, sessionIndex)
  }

  function noteActivity() {
    idle = false
    idleAfter.restart()
  }

  Timer {
    id: settle
    interval: 60
    onTriggered: root.syncFingerprint()
  }

  Timer {
    id: idleAfter
    interval: 5 * 60 * 1000
    running: true
    onTriggered: root.idle = true
  }

  Timer {
    id: passwordWatchdog
    interval: 15000
    onTriggered: root.authenticating = false
  }

  Connections {
    target: sddm
    function onInformationMessage(message) {
      if (root.listening && message.indexOf("Place") === 0) root.readerLive = true
    }
    function onLoginFailed() {
      if (Date.now() < root.ignoreFailuresUntil) return
      root.ignoreFailuresUntil = Date.now() + 50
      settle.restart()
      if (root.authenticating) {
        passwordWatchdog.stop()
        root.authenticating = false
        root.failedAttempts += 1
        root.failureMessage = "Authentication failed (" + root.failedAttempts + ")"
        passwordInput.text = ""
        passwordInput.forceActiveFocus()
      } else if (root.listening) {
        root.listening = false
        root.readerLive = false
        if (Date.now() - root.listeningSince < 500) root.fingerprintAvailable = false
      }
    }
    function onLoginSucceeded() {
      passwordWatchdog.stop()
      root.readerLive = false
      root.failureMessage = ""
    }
  }

  Repeater {
    model: userModel
    Item {
      Component.onCompleted: if (root.currentUser === "") root.currentUser = model.name
    }
  }

  TextMetrics {
    id: dotMetrics
    font.family: root.fontFamily
    font.pixelSize: root.passwordDotFontSize
    font.letterSpacing: root.passwordDotLetterSpacing
    text: "●".repeat(passwordInput.text.length)
  }

  Image {
    id: wallpaper
    anchors.fill: parent
    source: "background.jpg"
    fillMode: Image.PreserveAspectCrop
    asynchronous: false
  }

  MultiEffect {
    anchors.fill: wallpaper
    source: wallpaper
    autoPaddingEnabled: false
    blurEnabled: wallpaper.status === Image.Ready
    blur: 1.0
    blurMax: 128
    blurMultiplier: 1.25
    contrast: -0.08
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    onClicked: { root.noteActivity(); passwordInput.forceActiveFocus() }
    onPositionChanged: root.noteActivity()
  }

  Rectangle {
    id: inputField
    width: root.fieldWidth
    height: root.fieldHeight
    anchors.centerIn: parent
    color: root.fieldColor
    radius: root.cornerRadius
    border.width: root.outlineThickness
    border.color: root.failureMessage.length > 0 ? root.errorColor : root.borderColor
    clip: true

    TextInput {
      id: passwordInput
      anchors.fill: parent
      anchors.margins: root.outlineThickness
      anchors.leftMargin: root.outlineThickness + 18 + root.fingerprintReserve
      anchors.rightMargin: root.outlineThickness + 18 + root.fingerprintReserve
      verticalAlignment: TextInput.AlignVCenter
      horizontalAlignment: TextInput.AlignHCenter
      clip: true
      focus: true
      enabled: !root.authenticating
      echoMode: TextInput.Password
      passwordCharacter: "●"
      passwordMaskDelay: 0
      color: root.textColor
      selectionColor: root.selectionColor
      selectedTextColor: root.textColor
      font.family: root.fontFamily
      font.pixelSize: text.length > 0 ? Math.max(1, Math.floor(root.passwordDotFontSize * root.passwordDotScale)) : root.fieldFontSize
      font.letterSpacing: text.length > 0 ? root.passwordDotLetterSpacing * root.passwordDotScale : 0
      cursorVisible: activeFocus && !root.authenticating && root.failureMessage.length === 0 && text.length > 0
      cursorDelegate: Rectangle {
        width: 2
        color: root.textColor
        visible: passwordInput.cursorVisible
      }

      onTextChanged: {
        if (text.length > 0 && root.failureMessage.length > 0) root.failureMessage = ""
        root.noteActivity()
      }

      onAccepted: {
        var submitted = text
        if (submitted.length === 0) return
        root.authenticating = true
        text = ""
        root.submitPassword(submitted)
      }

      Keys.onPressed: function(event) {
        root.noteActivity()
        if (event.key === Qt.Key_Escape || (event.modifiers & Qt.ControlModifier && event.key === Qt.Key_U)) {
          text = ""
          event.accepted = true
        }
      }
    }

    Text {
      textFormat: Text.PlainText
      anchors.fill: passwordInput
      visible: passwordInput.text.length === 0
      text: root.authenticating ? "Checking…" : (root.failureMessage.length > 0 ? root.failureMessage : "Enter Password")
      color: root.authenticating ? root.textColor : (root.failureMessage.length > 0 ? root.errorColor : root.placeholderColor)
      font.family: root.fontFamily
      font.pixelSize: root.fieldFontSize
      font.italic: !root.authenticating && root.failureMessage.length > 0
      horizontalAlignment: Text.AlignHCenter
      verticalAlignment: Text.AlignVCenter
      elide: Text.ElideRight
    }

    Text {
      id: fingerprintIcon
      textFormat: Text.PlainText
      anchors.right: parent.right
      anchors.rightMargin: root.outlineThickness + 18
      anchors.verticalCenter: parent.verticalCenter
      text: "󰈷"
      color: root.placeholderColor
      opacity: root.readerLive && passwordInput.text.length === 0 ? 1 : 0
      Behavior on opacity { NumberAnimation { duration: 120 } }
      font.family: root.fontFamily
      font.pixelSize: Math.round(root.fieldFontSize * 1.1)
    }
  }

  onAuthenticatingChanged: if (!authenticating) passwordInput.forceActiveFocus()
  Component.onCompleted: passwordInput.forceActiveFocus()
}
