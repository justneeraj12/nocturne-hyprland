import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"

Rectangle {
    id: root
    implicitWidth: 410
    implicitHeight: Math.min(500, Math.max(175, 126 + (activeItems.length + historyItems.length) * 63))
    color: backend.baseColor
    border.color: backend.accent2Color
    border.width: 1
    property var activeItems: []
    property var historyItems: []
    property bool dnd: false

    function refresh() {
        activeItems = backend.notifications("list")
        historyItems = backend.notifications("history")
        dnd = backend.run(["makoctl", "mode"], 1000).split("\n").indexOf("do-not-disturb") >= 0
    }
    function dismiss(id) {
        backend.run(["makoctl", "dismiss", "-n", String(id)], 1200)
        refresh()
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 7
        RowLayout {
            Layout.fillWidth: true
            PanelHeader { Layout.fillWidth: true; title: "Notifications"; subtitle: "Alerts and history" }
            Text { text: "DND"; color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 9; font.bold: true }
            NocturneToggle {
                checked: root.dnd
                onToggleRequested: function(enabled) {
                    backend.run(["makoctl", "mode", "-t", "do-not-disturb"], 1200)
                    root.refresh()
                }
            }
        }
        RowLayout {
            Layout.fillWidth: true
            NocturneButton {
                Layout.fillWidth: true
                text: "RESTORE LAST"
                onClicked: { backend.run(["makoctl", "restore"], 1200); root.refresh() }
            }
            NocturneButton {
                Layout.fillWidth: true
                text: "CLEAR ACTIVE"
                danger: true
                onClicked: { backend.run(["makoctl", "dismiss", "--all"], 1200); root.refresh() }
            }
        }
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentWidth: availableWidth
            ColumnLayout {
                width: parent.width
                spacing: 5
                SectionLabel { text: "ACTIVE · " + root.activeItems.length }
                Text {
                    visible: root.activeItems.length === 0
                    text: "No active notifications."
                    color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 10
                }
                Repeater { model: root.activeItems; delegate: NotificationDelegate {} }
                SectionLabel { text: "HISTORY · " + root.historyItems.length }
                Text {
                    visible: root.historyItems.length === 0
                    text: "History is empty."
                    color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 10
                }
                Repeater { model: root.historyItems; delegate: NotificationDelegate {} }
            }
        }
    }

    component NotificationDelegate: Rectangle {
        required property var modelData
        Layout.fillWidth: true
        implicitHeight: 58
        color: backend.surfaceColor
        border.color: modelData.urgency === "critical" ? "#c75c66" : backend.lineColor
        RowLayout {
            anchors.fill: parent
            anchors.margins: 9
            ColumnLayout {
                Layout.fillWidth: true; spacing: 2
                Text { Layout.fillWidth: true; text: modelData.summary; color: backend.textColor; font.family: "monospace"; font.bold: true; font.pixelSize: 11; elide: Text.ElideRight }
                Text { text: (modelData.app || "SYSTEM").toUpperCase() + "  ·  " + (modelData.urgency || "normal").toUpperCase(); color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 8 }
            }
            NocturneButton {
                text: modelData.history ? "RESTORE" : "OPEN"
                onClicked: {
                    if (modelData.history) backend.run(["makoctl", "restore"], 1200)
                    else backend.run(["makoctl", "invoke", "-n", String(modelData.id)], 1200)
                    root.refresh()
                }
            }
            NocturneButton {
                visible: !modelData.history
                text: "×"; danger: true
                onClicked: root.dismiss(modelData.id)
            }
        }
    }

    Timer { interval: 1500; running: true; repeat: true; onTriggered: root.refresh() }
    Component.onCompleted: refresh()
}
