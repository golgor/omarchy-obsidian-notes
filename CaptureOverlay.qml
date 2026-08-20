import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import qs.Commons
import qs.Ui

// Centered modal overlay for capturing a multi-line note.
// Opened via IPC `omarchy-shell golgor.notes capture` or SUPER+N.
PanelWindow {
  id: root

  property QtObject bar: null
  property var hostWidget: null
  property bool opened: false

  readonly property color fg: bar ? bar.foreground : Color.foreground
  readonly property color bg: Color.popups.background
  readonly property color dim: Qt.darker(fg, 1.3)
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family
  readonly property string scriptPath: String(Qt.resolvedUrl("bin/notes")).replace("file://", "")

  signal saved()

  function open() {
    opened = true
    inputArea.text = ""
    Qt.callLater(function() { inputArea.forceActiveFocus() })
  }

  function close() {
    opened = false
  }

  function saveNote() {
    var content = inputArea.text.trim()
    if (content.length > 0) {
      saveProc.command = [root.scriptPath, "capture", content]
      saveProc.running = true
    }
    close()
  }

  Process {
    id: saveProc
    onExited: function(code) {
      if (code === 0) root.saved()
    }
  }

  visible: opened
  anchors { top: true; bottom: true; left: true; right: true }
  color: "transparent"

  WlrLayershell.namespace: "golgor-notes-capture"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: opened ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
  exclusionMode: ExclusionMode.Ignore

  // Background dark scrim
  Rectangle {
    anchors.fill: parent
    color: Util.alpha(Color.background, 0.7)

    MouseArea {
      anchors.fill: parent
      onClicked: root.close()
    }
  }

  // Centered dialog card
  BorderSurface {
    id: card
    width: Style.space(520)
    height: Style.space(340)
    radius: Style.cornerRadius
    anchors.centerIn: parent
    color: root.bg
    borderSpec: Border.controlSpec("focus", root.fg, Color.accent)
    padding: Style.space(16)

    MouseArea {
      anchors.fill: parent
      onClicked: {} // Prevents background click from closing
    }

    Column {
      anchors.fill: parent
      spacing: Style.space(12)

      // Header row
      Row {
        id: headerRow
        width: parent.width
        spacing: Style.space(10)

        Text {
          text: "󰅌"
          color: Color.accent
          font.family: root.fontFamily
          font.pixelSize: Style.font.title
          anchors.verticalCenter: parent.verticalCenter
        }

        Text {
          text: "New Note"
          color: root.fg
          font.family: root.fontFamily
          font.pixelSize: Style.font.title
          font.bold: true
          anchors.verticalCenter: parent.verticalCenter
        }
      }

      PanelSeparator {
        width: parent.width
        foreground: root.fg
      }

      // Input area container
      BorderSurface {
        width: parent.width
        height: parent.height - headerRow.height - footerRow.height - Style.space(48)
        color: Style.controlFill(inputArea.activeFocus, inputArea.hovered, root.fg, Color.accent)
        borderSpec: Border.controlSpec(inputArea.activeFocus ? "focus" : "normal", root.fg, Color.accent)
        radius: Style.cornerRadius

        ScrollView {
          anchors.fill: parent
          anchors.margins: Style.space(4)
          clip: true

          TextArea {
            id: inputArea
            placeholderText: "Type note here..."
            font.family: root.fontFamily
            font.pixelSize: Style.font.body
            color: root.fg
            placeholderTextColor: Qt.darker(root.fg, 1.6)
            selectionColor: Style.selectionFillFor(root.fg, Color.accent)
            selectedTextColor: root.fg
            wrapMode: TextEdit.Wrap
            selectByMouse: true
            padding: Style.space(10)
            background: null

            Keys.onPressed: function(event) {
              if (event.key === Qt.Key_Escape) {
                root.close()
                event.accepted = true
              } else if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && (event.modifiers & Qt.ControlModifier)) {
                root.saveNote()
                event.accepted = true
              }
            }
          }
        }
      }

      // Footer row
      Row {
        id: footerRow
        width: parent.width

        Text {
          text: "Ctrl+Enter save   ·   Esc cancel"
          color: root.dim
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          anchors.verticalCenter: parent.verticalCenter
        }

        Item { width: parent.width - parent.children[0].width - saveBtn.width; height: 1 }

        Rectangle {
          id: saveBtn
          width: Style.space(80)
          height: Style.space(30)
          radius: Style.cornerRadius
          color: saveMouse.containsMouse ? Util.alpha(Color.accent, 0.25) : Util.alpha(Color.accent, 0.15)
          border.color: Color.accent
          border.width: 1

          Text {
            anchors.centerIn: parent
            text: "Save"
            color: Color.accent
            font.family: root.fontFamily
            font.pixelSize: Style.font.bodySmall
            font.bold: true
          }

          MouseArea {
            id: saveMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.saveNote()
          }
        }
      }
    }
  }
}
