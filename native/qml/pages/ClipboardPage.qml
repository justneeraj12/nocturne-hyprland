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
    function refresh() { items = backend.clipboardItems(search.text); list.currentIndex = items.length ? 0 : -1 }

    ColumnLayout {
        anchors.fill: parent; anchors.margins: 11; spacing: 7
        RowLayout {
            Layout.fillWidth: true
            SectionLabel { Layout.fillWidth: true; text: "CLIPBOARD // LOCAL HISTORY" }
            NocturneButton { text: "CLEAR"; danger: true; onClicked: { backend.run(["cliphist", "wipe"]); root.refresh() } }
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
                if (event.key === Qt.Key_Down) { list.currentIndex = Math.min(list.count - 1, list.currentIndex + 1); event.accepted = true }
                else if (event.key === Qt.Key_Up) { list.currentIndex = Math.max(0, list.currentIndex - 1); event.accepted = true }
                else if (event.key === Qt.Key_Return && list.currentIndex >= 0) { backend.copyClipboardItem(root.items[list.currentIndex].entry); event.accepted = true }
                else if (event.key === Qt.Key_Escape) { backend.close(); event.accepted = true }
            }
            Component.onCompleted: forceActiveFocus()
        }
        ListView {
            id: list
            Layout.fillWidth: true; Layout.fillHeight: true
            model: root.items; spacing: 3; clip: true
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
        Text { Layout.fillWidth: true; text: "↑↓ SELECT   ↵ COPY   ESC CLOSE"; color: backend.mutedColor; horizontalAlignment: Text.AlignHCenter; font.family: "monospace"; font.pixelSize: 9 }
    }
}
