import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import qs.Commons
import qs.Ui

// Centered modal overlay for capturing a new note or editing an existing note.
// Opened or toggled via IPC `omarchy-shell golgor.notes capture` or from the dropdown.
PanelWindow {
  id: root

  property QtObject bar: null
  property var hostWidget: null
  property bool opened: false
  property string currentPath: ""
  readonly property bool isEditing: currentPath !== ""

  readonly property color fg: bar ? bar.foreground : Color.foreground
  readonly property color bg: Color.popups.background
  readonly property color dim: Qt.darker(fg, 1.3)
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family
  readonly property string scriptPath: String(Qt.resolvedUrl("bin/notes")).replace("file://", "")

  signal saved()

  function open(path) {
    confirmDialog.opened = false
    if (path && String(path).trim().length > 0) {
      currentPath = String(path)
      opened = true
      inputArea.text = ""
      readProc.command = [root.scriptPath, "read", currentPath]
      readProc.running = true
    } else {
      currentPath = ""
      opened = true
      inputArea.text = ""
      Qt.callLater(function() { inputArea.forceActiveFocus() })
    }
  }

  function close() {
    confirmDialog.opened = false
    opened = false
    currentPath = ""
  }

  function toggle() {
    if (opened) close()
    else open()
  }

  function saveNote() {
    var content = inputArea.text.trim()
    if (root.isEditing) {
      if (content.length === 0) {
        confirmDialog.message = "Note is empty. Move to trash?"
        confirmDialog.selectedIndex = 1
        confirmDialog.opened = true
        return
      }
      writeProc.command = [root.scriptPath, "write", root.currentPath, inputArea.text]
      writeProc.running = true
      root.close()
    } else {
      if (content.length > 0) {
        saveProc.command = [root.scriptPath, "capture", content]
        saveProc.running = true
      }
      root.close()
    }
  }

  function requestDelete() {
    if (!root.isEditing) return
    confirmDialog.message = "Move this note to trash?"
    confirmDialog.selectedIndex = 1
    confirmDialog.opened = true
  }

  function performDelete() {
    confirmDialog.opened = false
    if (root.currentPath !== "") {
      deleteProc.command = [root.scriptPath, "delete", root.currentPath]
      deleteProc.running = true
    }
    root.close()
  }

  function cancelDelete() {
    confirmDialog.opened = false
    Qt.callLater(function() { inputArea.forceActiveFocus() })
  }

  Process {
    id: saveProc
    onExited: function(code) {
      if (code === 0) root.saved()
    }
  }

  Process {
    id: writeProc
    onExited: function(code) {
      if (code === 0) root.saved()
    }
  }

  Process {
    id: deleteProc
    onExited: function(code) {
      if (code === 0) root.saved()
    }
  }

  Process {
    id: readProc
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        inputArea.text = text || ""
        Qt.callLater(function() {
          inputArea.cursorPosition = inputArea.text.length
          inputArea.forceActiveFocus()
        })
      }
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
      onClicked: {
        if (confirmDialog.opened) root.cancelDelete()
        else root.close()
      }
    }
  }

  // Centered dialog card
  BorderSurface {
    id: card
    width: Style.space(680)
    height: Style.space(480)
    radius: Style.cornerRadius
    anchors.centerIn: parent
    color: root.bg
    borderSpec: Border.controlSpec("focus", root.fg, Color.accent)
    padding: Style.space(18)

    MouseArea {
      anchors.fill: parent
      onClicked: {} // Prevents background click from closing
    }

    Item {
      anchors.fill: parent
      anchors.topMargin: card.contentTopInset
      anchors.rightMargin: card.contentRightInset
      anchors.bottomMargin: card.contentBottomInset
      anchors.leftMargin: card.contentLeftInset

      Column {
        id: mainCol
        anchors.fill: parent
        spacing: Style.space(12)

        // Header row
        Row {
          id: headerRow
          width: parent.width
          spacing: Style.space(10)

          Text {
            text: root.isEditing ? "󰏫" : "󰅌"
            color: Color.accent
            font.family: root.fontFamily
            font.pixelSize: Style.font.title
            anchors.verticalCenter: parent.verticalCenter
          }

          Text {
            text: root.isEditing ? "Edit Note" : "New Note"
            color: root.fg
            font.family: root.fontFamily
            font.pixelSize: Style.font.title
            font.bold: true
            anchors.verticalCenter: parent.verticalCenter
          }
        }

        PanelSeparator {
          id: separator
          width: parent.width
          foreground: root.fg
        }

        // Input area container
        BorderSurface {
          width: parent.width
          height: mainCol.height - headerRow.height - separator.height - footerRow.height - (mainCol.spacing * 3)
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
                if (confirmDialog.opened) {
                  if (event.text === "x" || event.text === "X") {
                    root.performDelete()
                    event.accepted = true
                    return
                  }
                  if (confirmDialog.handleKey(event)) {
                    event.accepted = true
                    return
                  }
                }
                if (event.key === Qt.Key_Escape) {
                  root.close()
                  event.accepted = true
                } else if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && (event.modifiers & Qt.ControlModifier)) {
                  root.saveNote()
                  event.accepted = true
                } else if (root.isEditing && (event.key === Qt.Key_Delete || event.key === Qt.Key_Backspace) && (event.modifiers & Qt.ControlModifier)) {
                  root.requestDelete()
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
            text: root.isEditing
              ? "Ctrl+Enter save   ·   Ctrl+Delete delete   ·   Esc cancel"
              : "Ctrl+Enter save   ·   Esc cancel"
            color: root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            anchors.verticalCenter: parent.verticalCenter
          }

          Item {
            width: Math.max(0, parent.width - parent.children[0].width - buttonRow.width)
            height: 1
          }

          Row {
            id: buttonRow
            spacing: Style.space(8)

            Rectangle {
              id: deleteBtn
              visible: root.isEditing
              width: Style.space(80)
              height: Style.space(30)
              radius: Style.cornerRadius
              color: deleteMouse.containsMouse ? Util.alpha(Color.urgent, 0.25) : Util.alpha(Color.urgent, 0.15)
              border.color: Color.urgent
              border.width: 1

              Text {
                anchors.centerIn: parent
                text: "Delete"
                color: Color.urgent
                font.family: root.fontFamily
                font.pixelSize: Style.font.bodySmall
                font.bold: true
              }

              MouseArea {
                id: deleteMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.requestDelete()
              }
            }

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

    ConfirmDialog {
      id: confirmDialog
      anchors.fill: parent
      fontFamily: root.fontFamily
      confirmText: "Delete"
      cancelText: "Cancel"
      message: "Move this note to trash?"
      onConfirmed: root.performDelete()
      onCanceled: root.cancelDelete()
    }
  }
}
