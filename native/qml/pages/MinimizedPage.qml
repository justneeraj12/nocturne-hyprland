import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"

Rectangle {
    id: root
    implicitWidth: 500
    implicitHeight: Math.max(120, Math.min(430, panel.implicitHeight + 20))
    color: backend.baseColor; border.color: backend.accent2Color; border.width: 1
    property var items: backend.json([backend.home + "/.config/hypr/scripts/minimize", "list"], 1800) || []
    property int currentIndex: items.length ? 0 : -1
    function navigate(delta) {
        if (!items.length) return
        currentIndex = Math.max(0, Math.min(items.length - 1, currentIndex + delta))
        windows.positionViewAtIndex(currentIndex, ListView.Contain)
    }
    function activateCurrent() {
        if (currentIndex < 0 || currentIndex >= items.length) return
        backend.run([backend.home + "/.config/hypr/scripts/minimize", "restore", items[currentIndex].address])
        backend.close()
    }
    ColumnLayout {
        id: panel; x: 10; y: 10; width: parent.width - 20; spacing: 5
        RowLayout {
            Layout.fillWidth: true
            PanelHeader { Layout.fillWidth: true; title: "Minimized"; subtitle: "Hidden windows" }
            Text { text: root.items.length + (root.items.length === 1 ? " WINDOW" : " WINDOWS"); color: backend.mutedColor; font.family: "monospace"; font.pixelSize: 8 }
            NocturneButton { visible: root.items.length > 0; text: "RESTORE ALL"; onClicked: { backend.run([backend.home + "/.config/hypr/scripts/minimize", "restore-all"]); backend.close() } }
        }
        Text { visible: root.items.length === 0; text: "Nothing is minimized."; color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 10 }
        ListView {
            id: windows
            visible: root.items.length > 0
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(contentHeight, 320)
            clip: true
            spacing: 4
            model: root.items
            delegate: Rectangle {
                required property var modelData
                required property int index
                width: ListView.view.width; height: 42
                color: index === root.currentIndex ? backend.overlayColor : backend.surfaceColor
                border.color: index === root.currentIndex ? backend.accentColor : backend.lineColor
                RowLayout {
                    anchors.fill: parent; anchors.leftMargin: 9; anchors.rightMargin: 9; spacing: 8
                    Text { Layout.fillWidth: true; text: modelData.title || modelData.class || "Window"; color: backend.textColor; font.family: "Inter"; font.pixelSize: 10; font.bold: index === root.currentIndex; elide: Text.ElideRight }
                    Text { text: "WS " + modelData.workspace; color: backend.accentColor; font.family: "monospace"; font.pixelSize: 8 }
                    Text { text: "RESTORE"; color: backend.mutedColor; font.family: "monospace"; font.pixelSize: 8 }
                }
                MouseArea { anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onEntered: root.currentIndex = index; onClicked: root.activateCurrent() }
            }
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
        }
        Text { visible: root.items.length > 0; Layout.fillWidth: true; text: "↑↓ SELECT   ↵ RESTORE   ESC CLOSE"; color: backend.mutedColor; horizontalAlignment: Text.AlignHCenter; font.family: "monospace"; font.pixelSize: 8 }
    }
}
