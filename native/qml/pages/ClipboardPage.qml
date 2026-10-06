import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"

Rectangle {
    id: root
    implicitWidth: 520
    implicitHeight: 390
    color: backend.baseColor
    border.color: backend.accent2Color
    border.width: 1
    property var items: backend.clipboardItems("")
    property bool clearArmed: false
    function refresh() { items = backend.clipboardItems(search.text); list.currentIndex = items.length ? 0 : -1 }
    function navigate(delta) {
        if (!items.length) return
        list.currentIndex = Math.max(0, Math.min(items.length - 1, list.currentIndex + delta))
        list.positionViewAtIndex(list.currentIndex, ListView.Contain)
    }
    function first() { if (items.length) { list.currentIndex = 0; list.positionViewAtBeginning() } }
    function last() { if (items.length) { list.currentIndex = items.length - 1; list.positionViewAtEnd() } }
    function clearQuery() { search.clear(); search.forceActiveFocus() }
    function clearHistory() {
        if (!clearArmed) { clearArmed = true; clearReset.restart(); return }
        backend.run(["cliphist", "wipe"]); clearArmed = false; refresh()
    }

    ColumnLayout {
        anchors.fill: parent; anchors.margins: 11; spacing: 7
        RowLayout {
            Layout.fillWidth: true
            PanelHeader { Layout.fillWidth: true; title: "Clipboard"; subtitle: "Recent copied items" }
            Text { text: root.items.length + (root.items.length === 1 ? " ITEM" : " ITEMS"); color: backend.mutedColor; font.family: "monospace"; font.pixelSize: 8 }
            NocturneButton { text: root.clearArmed ? "CONFIRM CLEAR" : "CLEAR"; danger: true; onClicked: root.clearHistory() }
        }
        TextField {
            id: search
            Layout.fillWidth: true; implicitHeight: 38
            placeholderText: "Filter copied items…"
            color: backend.textColor; placeholderTextColor: backend.mutedColor
            font.family: "monospace"; font.pixelSize: 12
            background: Rectangle { color: backend.surfaceColor; border.color: search.activeFocus ? backend.accentColor : backend.lineColor }
            onTextChanged: root.refresh()
            Keys.onPressed: function(event) {
                if (event.key === Qt.Key_Down) { root.navigate(1); event.accepted = true }
                else if (event.key === Qt.Key_Up) { root.navigate(-1); event.accepted = true }
                else if (event.key === Qt.Key_PageDown) { root.navigate(8); event.accepted = true }
                else if (event.key === Qt.Key_PageUp) { root.navigate(-8); event.accepted = true }
                else if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_Home) { root.first(); event.accepted = true }
                else if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_End) { root.last(); event.accepted = true }
                else if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_L) { search.selectAll(); event.accepted = true }
                else if (event.key === Qt.Key_Return && list.currentIndex >= 0) { backend.copyClipboardItem(root.items[list.currentIndex].entry); event.accepted = true }
                else if (event.key === Qt.Key_Escape) { if (search.text !== "") root.clearQuery(); else backend.close(); event.accepted = true }
            }
            Component.onCompleted: forceActiveFocus()
        }
        ListView {
            id: list
            Layout.fillWidth: true; Layout.fillHeight: true
            model: root.items; spacing: 3; clip: true
            Text {
                anchors.centerIn: parent; visible: root.items.length === 0
                text: search.text === "" ? "CLIPBOARD HISTORY IS EMPTY" : "NO COPIED ITEM MATCHES THIS FILTER"
                color: backend.mutedColor; font.family: "monospace"; font.pixelSize: 10
            }
            delegate: Rectangle {
                required property var modelData
                required property int index
                width: ListView.view.width; height: 36
                color: index === list.currentIndex ? backend.overlayColor : backend.surfaceColor
                border.color: index === list.currentIndex ? backend.accentColor : backend.lineColor
                Text { anchors.fill: parent; anchors.margins: 9; text: modelData.preview; color: backend.textColor; font.family: "monospace"; font.pixelSize: 10; elide: Text.ElideRight; verticalAlignment: Text.AlignVCenter }
                MouseArea { anchors.fill: parent; hoverEnabled: true; onEntered: list.currentIndex = index; onClicked: backend.copyClipboardItem(modelData.entry) }
            }
        }
        Text { Layout.fillWidth: true; text: "↑↓/PG SELECT   ↵ COPY   CTRL+L SEARCH   ESC CLEAR/CLOSE"; color: backend.mutedColor; horizontalAlignment: Text.AlignHCenter; font.family: "monospace"; font.pixelSize: 9 }
    }
    Timer { id: clearReset; interval: 5000; onTriggered: root.clearArmed = false }
}
