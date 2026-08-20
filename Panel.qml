import QtQuick
import Quickshell.Io
import qs.Commons
import qs.Ui

// Recent-notes dropdown. Runs `bin/notes list` on open, shows one row per note
// (first 40 chars, newest first). Clicking a row copies the note's full text
// to the clipboard via `bin/notes copy` and closes the dropdown.
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

  function open() { refresh(); root.controller.show() }
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
      }
    }
  }

  Process { id: copyProc }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.barIdentity
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(420))
    contentHeight: panel.fittedContentHeight(listColumn.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }

      Flickable {
        id: scroll
        anchors.fill: parent
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
                color: cardMouse.containsMouse ? Util.alpha(root.fg, 0.10) : "transparent"

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
    }
  }
}
