import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

// Bar button for the notes plugin. Hosts the recent-notes dropdown (Panel.qml)
// and forwards the open/close/opened contract the bar uses to find the panel.
BarWidget {
  id: root
  moduleName: "golgor.notes"

  readonly property bool opened: panelLoader.item ? panelLoader.item.opened === true : false
  function open() { if (panelLoader.item) panelLoader.item.open() }
  function close() { if (panelLoader.item) panelLoader.item.close() }
  function togglePanel() { if (panelLoader.item) panelLoader.item.toggle() }

  readonly property real openPanelIndicatorWidth: button.labelWidth
  readonly property real openPanelIndicatorHeight: Math.max(Style.space(10), Math.round(Style.bar.iconSlot * 0.55))

  readonly property bool popoutSwitchClosing: panelLoader.item ? panelLoader.item.popoutSwitchClosing === true : false
  function closeForPopoutSwitch() { if (panelLoader.item) panelLoader.item.closeForPopoutSwitch() }

  function openCapture() { if (captureLoader.item) captureLoader.item.open() }
  function toggleCapture() { if (captureLoader.item) captureLoader.item.toggle() }

  function injectPanel() {
    var target = panelLoader.item
    if (!target) return
    if ("bar" in target) target.bar = root.bar
    if ("settings" in target) target.settings = root.settings
    if ("anchorItem" in target) target.anchorItem = button
    if ("hostWidget" in target) target.hostWidget = root
  }

  function injectCapture() {
    var target = captureLoader.item
    if (!target) return
    if ("bar" in target) target.bar = root.bar
    if ("hostWidget" in target) target.hostWidget = root
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight
  onBarChanged: { injectPanel(); injectCapture() }
  onSettingsChanged: injectPanel()

  Loader {
    id: panelLoader
    active: true
    source: Qt.resolvedUrl("Panel.qml")
    visible: false
    onLoaded: { root.injectPanel(); Qt.callLater(root.injectPanel) }
  }

  Loader {
    id: captureLoader
    active: true
    source: Qt.resolvedUrl("CaptureOverlay.qml")
    visible: false
    onLoaded: { root.injectCapture(); Qt.callLater(root.injectCapture) }
  }

  IpcHandler {
    target: "golgor.notes"
    function open(): void { root.open() }
    function close(): void { root.close() }
    function show(): void { root.open() }
    function hide(): void { root.close() }
    function toggle(): void { root.togglePanel() }
    function capture(): void { root.toggleCapture() }
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "󰅌"
    tooltipText: "Notes"
    horizontalMargin: 8.75
    verticalPadding: 8.75
    onPressed: function(b) { root.togglePanel() }
  }
}
