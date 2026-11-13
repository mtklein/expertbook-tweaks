import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam
import Quickshell.Wayland

Scope {
  id: root
  property bool checking: false
  property int failures: 0
  property string failure: ""
  property bool readerLive: false
  property int quickFailures: 0
  property double fingerStarted: 0
  property string pending: ""
  property bool dark: false

  readonly property string flag: Quickshell.env("XDG_RUNTIME_DIR") + "/shell-locked"

  function lock() {
    if (session.locked) return
    Quickshell.execDetached(["touch", flag])
    failures = 0
    failure = ""
    quickFailures = 0
    session.locked = true
    startFinger()
  }

  function unlock() {
    dark = false
    Quickshell.execDetached(["rm", "-f", flag])
    session.locked = false
    checking = false
    readerLive = false
    retry.stop()
    if (finger.active) finger.abort()
    if (password.active) password.abort()
  }

  function submit(text) {
    if (password.active || text.length === 0) return
    pending = text
    checking = true
    password.start()
  }

  function startFinger() {
    if (!session.locked || finger.active) return
    fingerStarted = Date.now()
    readerLive = false
    finger.start()
  }

  function fingerEnded() {
    readerLive = false
    if (!session.locked) return
    quickFailures = Date.now() - fingerStarted < 1000 ? quickFailures + 1 : 0
    retry.interval = quickFailures <= 1 ? 100 : 1500
    if (quickFailures < 5) retry.restart()
  }

  function nudge() {
    if (!session.locked || finger.active || retry.running) return
    quickFailures = 0
    startFinger()
  }

  Process {
    command: ["test", "-e", root.flag]
    running: true
    onExited: function(code) { if (code === 0) root.lock() }
  }

  Timer {
    id: retry
    interval: 1500
    onTriggered: root.startFinger()
  }

  IpcHandler {
    target: "lock"
    function lock(): void { root.lock() }
    function blank(): void {
      root.dark = true
      root.lock()
    }
    function reveal(): void { root.dark = false }
    function locked(): bool { return session.locked && session.secure }
  }

  PamContext {
    id: password
    configDirectory: "pam"
    config: "password"
    onResponseRequiredChanged: {
      if (responseRequired) {
        respond(root.pending)
        root.pending = ""
      }
    }
    onCompleted: function(result) {
      root.pending = ""
      root.checking = false
      if (result === PamResult.Success) {
        root.unlock()
      } else if (session.locked) {
        root.failures += 1
        root.failure = "Authentication failed (" + root.failures + ")"
      }
    }
    onError: function(error) {
      root.pending = ""
      root.checking = false
      root.failure = "Authentication failed"
    }
  }

  PamContext {
    id: finger
    configDirectory: "pam"
    config: "fingerprint"
    onPamMessage: if (!messageIsError) root.readerLive = true
    onCompleted: function(result) {
      if (result === PamResult.Success) root.unlock()
      else root.fingerEnded()
    }
    onError: function(error) { root.fingerEnded() }
  }

  WlSessionLock {
    id: session

    WlSessionLockSurface {
      id: surface
      color: "#000000"

      readonly property int fieldFontSize: 18
      readonly property int dotFontSize: 21

      Image {
        id: wallpaper
        anchors.fill: parent
        source: Theme.wallpaper
        fillMode: Image.PreserveAspectCrop
        asynchronous: false
        sourceSize.width: 1800
        visible: false
      }

      MultiEffect {
        anchors.fill: wallpaper
        source: wallpaper
        autoPaddingEnabled: false
        blurEnabled: true
        blur: 1.0
        blurMax: 128
        blurMultiplier: 1.25
        contrast: -0.08
      }

      MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onClicked: {
          root.nudge()
          input.forceActiveFocus()
        }
      }

      Rectangle {
        width: 381
        height: 67
        anchors.centerIn: parent
        color: Qt.rgba(0x16 / 255, 0x16 / 255, 0x18 / 255, 0.8)
        radius: Theme.radius
        border.width: root.failure !== "" ? 3 : 0
        border.color: Theme.active
        clip: true

        TextInput {
          id: input
          anchors.fill: parent
          anchors.leftMargin: 21 + 34
          anchors.rightMargin: 21 + 34
          verticalAlignment: TextInput.AlignVCenter
          horizontalAlignment: TextInput.AlignHCenter
          clip: true
          focus: true
          enabled: !root.checking
          echoMode: TextInput.Password
          passwordCharacter: "●"
          passwordMaskDelay: 0
          color: Theme.barText
          font.family: Theme.iconFont
          font.pixelSize: surface.dotFontSize
          font.letterSpacing: 3
          cursorVisible: false

          onTextChanged: if (text.length > 0) root.failure = ""
          onEnabledChanged: if (enabled) forceActiveFocus()
          onAccepted: {
            var typed = text
            text = ""
            root.submit(typed)
          }
          Keys.onPressed: function(event) {
            root.dark = false
            root.nudge()
            if (event.key === Qt.Key_Escape || (event.modifiers & Qt.ControlModifier && event.key === Qt.Key_U)) {
              text = ""
              event.accepted = true
            }
          }
          Component.onCompleted: forceActiveFocus()
        }

        Text {
          textFormat: Text.PlainText
          anchors.fill: input
          visible: input.text.length === 0
          text: root.checking ? "Checking…" : (root.failure !== "" ? root.failure : "Enter Password")
          color: root.checking ? Theme.barText : (root.failure !== "" ? Theme.active : Theme.dimText)
          font.family: Theme.iconFont
          font.pixelSize: surface.fieldFontSize
          font.italic: !root.checking && root.failure !== ""
          horizontalAlignment: Text.AlignHCenter
          verticalAlignment: Text.AlignVCenter
          elide: Text.ElideRight
        }

        Text {
          textFormat: Text.PlainText
          anchors.right: parent.right
          anchors.rightMargin: 21
          anchors.verticalCenter: parent.verticalCenter
          text: "󰈷"
          color: Theme.dimText
          opacity: root.readerLive && input.text.length === 0 ? 1 : 0
          Behavior on opacity { NumberAnimation { duration: 120 } }
          font.family: Theme.iconFont
          font.pixelSize: 20
        }
      }

      Rectangle {
        anchors.fill: parent
        visible: root.dark
        color: "#000000"

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.BlankCursor
          onPressed: root.dark = false
        }
      }
    }
  }
}
