import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"

Rectangle {
    id: root
    implicitWidth: 410
    implicitHeight: Math.max(112, panel.implicitHeight + 20)
    color: backend.baseColor
    border.color: backend.accent2Color
    border.width: 1
    property var items: backend.trayItems()

    function refresh() { items = backend.trayItems() }

    ColumnLayout {
        id: panel
        x: 10; y: 10; width: parent.width - 20
        spacing: 6
        RowLayout {
            Layout.fillWidth: true
            SectionLabel { Layout.fillWidth: true; text: "BACKGROUND // STATUS ITEMS" }
            Text { text: root.items.length + " ACTIVE"; color: backend.mutedColor; font.family: "monospace"; font.pixelSize: 9 }
        }
        Text {
            Layout.fillWidth: true
            visible: root.items.length === 0
            text: "No background status items are registered."
            color: backend.mutedColor
            font.family: "Inter"
            font.pixelSize: 10
        }
        Repeater {
            model: root.items
            delegate: Rectangle {
                required property var modelData
                Layout.fillWidth: true
                implicitHeight: 43
                color: itemMouse.containsMouse ? backend.overlayColor : backend.surfaceColor
                border.color: itemMouse.containsMouse ? backend.accentColor : backend.lineColor
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 9
                    Text { text: modelData.title.substring(0, 1).toUpperCase(); color: backend.accentColor; font.family: "monospace"; font.bold: true }
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 0
                        Text { Layout.fillWidth: true; text: modelData.title; color: backend.textColor; font.family: "monospace"; font.pixelSize: 11; elide: Text.ElideRight }
                        Text { text: (modelData.status || "passive").toUpperCase(); color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 8 }
                    }
                    Text { text: "LEFT OPEN  ·  RIGHT MENU"; color: backend.mutedColor; font.family: "monospace"; font.pixelSize: 8 }
                }
                MouseArea {
                    id: itemMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                    onClicked: function(mouse) {
                        backend.activateTrayItem(modelData.reference,
                            mouse.button === Qt.RightButton ? "context" : (mouse.button === Qt.MiddleButton ? "secondary" : "activate"))
                    }
                }
            }
        }
    }
    Timer { interval: 1500; running: true; repeat: true; onTriggered: root.refresh() }
}
