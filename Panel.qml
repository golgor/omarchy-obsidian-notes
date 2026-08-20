import QtQuick
import Quickshell.Io
import qs.Commons
import qs.Ui

// Recent-notes dropdown. Runs `bin/notes list` on open, showing one row per
// note (datetime heading + ~100-char body, newest first). A row is selected
// with the mouse (hover) or the keyboard (j/k, Up/Down). Enter/Space or a
// click copies the selected note; `x` moves it to the trash after a confirm
// dialog. A footer lists the available keys.
Panel {
  id: root
  moduleName: "golgor.notes"
  ipcTarget: "golgor.notes"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null
  readonly property var barIdentity: hostWidget || root

  readonly property string scriptPath: String(Qt.resolvedUrl("bin/notes")).replace("file://", "")
  readonly property color fg: bar ? bar.foreground : Color.foreground
  readonly property color dim: Qt.darker(fg, 1.3)
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family

  property var notes: []   // [{ path, title, body }]
  property int selectedIndex: -1
  property string pendingDeletePath: ""
  property string pendingDeleteTitle: ""

  function open() { root.selectedIndex = 0; refresh(); root.controller.show() }
  function close() { root.controller.hide() }
  function toggle() { root.opened ? root.close() : root.open() }
  function switchPanel(direction) {
    if (root.bar && typeof root.bar.switchPanelFrom === "function")
      return root.bar.switchPanelFrom(root.barIdentity, direction)
    return false
  }

  function refresh() { listProc.running = true }
  function copyNote(path) {
    copyProc.command = [root.scriptPath, "copy", path]
    copyProc.running = true
  }

  function moveSelection(delta) {
    if (root.notes.length === 0) return
    var i = root.selectedIndex + delta
    if (i < 0) i = 0
    if (i > root.notes.length - 1) i = root.notes.length - 1
    root.selectedIndex = i
    root.ensureVisible(i)
  }

  function activateSelection() {
    if (root.selectedIndex < 0 || root.selectedIndex >= root.notes.length) return
    root.copyNote(root.notes[root.selectedIndex].path)
    root.close()
  }

  // Keep the selected row within the scroll viewport.
  function ensureVisible(i) {
    var it = notesRepeater.itemAt(i)
    if (!it) return
    if (it.y < scroll.contentY) scroll.contentY = it.y
    else if (it.y + it.height > scroll.contentY + scroll.height) scroll.contentY = it.y + it.height - scroll.height
  }

  function requestDelete() {
    if (root.selectedIndex < 0 || root.selectedIndex >= root.notes.length) return
    root.pendingDeletePath = root.notes[root.selectedIndex].path
    root.pendingDeleteTitle = root.notes[root.selectedIndex].title
    confirmDialog.selectedIndex = 1
    confirmDialog.opened = true
  }

  function performDelete() {
    confirmDialog.opened = false
    if (root.pendingDeletePath === "") return
    deleteProc.command = [root.scriptPath, "delete", root.pendingDeletePath]
    deleteProc.running = true
    root.pendingDeletePath = ""
    root.pendingDeleteTitle = ""
  }

  function cancelDelete() {
    confirmDialog.opened = false
    root.pendingDeletePath = ""
    root.pendingDeleteTitle = ""
  }

  Process {
    id: listProc
    command: [root.scriptPath, "list"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var rows = []
        var out = String(text || "").trim()
        if (out.length > 0) {
          var lines = out.split("\n")
          for (var i = 0; i < lines.length; i++) {
            var parts = lines[i].split("\t")
            if (parts.length >= 3) rows.push({ path: parts[0], title: parts[1], body: parts.slice(2).join("\t") })
          }
        }
        root.notes = rows
        if (rows.length === 0) root.selectedIndex = -1
        else if (root.selectedIndex < 0) root.selectedIndex = 0
        else if (root.selectedIndex > rows.length - 1) root.selectedIndex = rows.length - 1
      }
    }
  }

  Process { id: copyProc }

  Process {
    id: deleteProc
    onExited: function(code) { if (code === 0) root.refresh() }
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.barIdentity
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(420))
    contentHeight: panel.fittedContentHeight(listColumn.implicitHeight
      + (root.notes.length > 0 ? footer.implicitHeight + Style.space(6) : 0))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: { if (confirmDialog.opened) root.cancelDelete(); else root.close() }
      onTabRequested: function(direction) {
        if (confirmDialog.opened) confirmDialog.selectedIndex = confirmDialog.selectedIndex === 0 ? 1 : 0
        else root.switchPanel(direction)
      }
      onMoveRequested: function(dx, dy) {
        if (confirmDialog.opened) confirmDialog.selectedIndex = confirmDialog.selectedIndex === 0 ? 1 : 0
        else root.moveSelection(dy)
      }
      onActivateRequested: {
        if (confirmDialog.opened) { if (confirmDialog.selectedIndex === 0) root.cancelDelete(); else root.performDelete() }
        else root.activateSelection()
      }
      onDeleteRequested: { if (!confirmDialog.opened) root.requestDelete() }

      Flickable {
        id: scroll
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: footer.top
        anchors.bottomMargin: footer.visible ? Style.space(6) : 0
        contentWidth: width
        contentHeight: listColumn.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        interactive: contentHeight > height

        Column {
          id: listColumn
          width: scroll.width
          spacing: Style.space(2)

          PanelSectionHeader {
            visible: root.notes.length > 0
            text: "RECENT NOTES"
            foreground: root.fg
            fontFamily: root.fontFamily
          }

          PanelSeparator {
            visible: root.notes.length > 0
            width: listColumn.width
            foreground: root.fg
          }

          Text {
            visible: root.notes.length === 0
            width: parent.width
            padding: Style.space(10)
            text: "No notes yet"
            color: root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.body
          }

          Repeater {
            id: notesRepeater
            model: root.notes

            delegate: Column {
              id: item
              required property var modelData
              required property int index
              width: listColumn.width

              Rectangle {
                id: card
                width: parent.width
                height: cardCol.implicitHeight + Style.space(14)
                radius: Style.cornerRadius
                color: item.index === root.selectedIndex ? Util.alpha(root.fg, 0.12) : "transparent"

                Column {
                  id: cardCol
                  anchors.left: parent.left
                  anchors.right: parent.right
                  anchors.verticalCenter: parent.verticalCenter
                  anchors.leftMargin: Style.space(10)
                  anchors.rightMargin: Style.space(10)
                  spacing: Style.space(3)

                  Text {
                    width: parent.width
                    text: item.modelData.title
                    color: root.fg
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.subtitle
                    font.bold: true
                    elide: Text.ElideRight
                  }

                  Text {
                    width: parent.width
                    text: item.modelData.body
                    color: root.dim
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.body
                    wrapMode: Text.Wrap
                    maximumLineCount: 3
                    elide: Text.ElideRight
                  }
                }

                MouseArea {
                  id: cardMouse
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onEntered: root.selectedIndex = item.index
                  onClicked: { root.copyNote(item.modelData.path); root.close() }
                }
              }

              PanelSeparator {
                visible: item.index < root.notes.length - 1
                width: listColumn.width
                foreground: root.fg
              }
            }
          }
        }
      }

      Column {
        id: footer
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        spacing: Style.space(6)
        visible: root.notes.length > 0
        height: visible ? implicitHeight : 0

        PanelSeparator { width: footer.width; foreground: root.fg }

        Text {
          width: footer.width
          text: "Enter copy   ·   X delete   ·   j/k move"
          horizontalAlignment: Text.AlignHCenter
          color: root.dim
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
        }
      }

      ConfirmDialog {
        id: confirmDialog
        anchors.fill: parent
        fontFamily: root.fontFamily
        confirmText: "Delete"
        cancelText: "Cancel"
        message: "Move this note to trash?\n\n" + root.pendingDeleteTitle
        onConfirmed: root.performDelete()
        onCanceled: root.cancelDelete()
      }
    }
  }
}
