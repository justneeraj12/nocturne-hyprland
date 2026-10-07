import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"

Rectangle {
    id: root
    implicitWidth: 410
    implicitHeight: panel.implicitHeight + 20
    color: backend.baseColor
    border.color: backend.accent2Color
    border.width: 1
    property var state: ({packages:0, flatpak:0, firmware:0, failed:0, platform:{packageLabel:"SYSTEM PACKAGES"}})
    property bool loading: false

    readonly property string helper: backend.home + "/.config/hypr/scripts/system-maintenance"

    function refresh() {
        loading = true
        var next = backend.json([helper, "status"], 25000)
        if (next) state = next
        loading = false
    }
    function openTask(task) { backend.start([helper, task]) }

    ColumnLayout {
        id: panel
        x: 10; y: 10; width: parent.width - 20; spacing: 8
        PanelHeader { Layout.fillWidth: true; title: "Maintenance"; subtitle: "Updates, firmware and health" }

        Repeater {
            model: [
                {key:"packages", label:String(root.state.platform.packageLabel || "SYSTEM PACKAGES"), action:"packages"},
                {key:"flatpak", label:"FLATPAK APPS", action:"flatpak"},
                {key:"firmware", label:"DEVICE FIRMWARE", action:"firmware"},
                {key:"failed", label:"FAILED USER SERVICES", action:"doctor"}
            ]
            delegate: Rectangle {
                required property var modelData
                Layout.fillWidth: true
                implicitHeight: 48
                color: backend.surfaceColor
                border.color: modelData.key === "failed" && root.state[modelData.key] > 0
                    ? "#c75c66" : backend.lineColor
                RowLayout {
                    anchors.fill: parent; anchors.margins: 8
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 1
                        Text { text: modelData.label; color: backend.textColor; font.family: "Inter"; font.bold: true; font.pixelSize: 10 }
                        Text {
                            text: root.state[modelData.key] + (modelData.key === "failed" ? " reported" : " available")
                            color: backend.mutedColor; font.family: "monospace"; font.pixelSize: 9
                        }
                    }
                    NocturneButton { text: modelData.key === "failed" ? "CHECK" : "OPEN"; onClicked: root.openTask(modelData.action) }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true; spacing: 5
            NocturneButton { Layout.fillWidth: true; text: root.loading ? "CHECKING…" : "REFRESH STATUS"; enabled: !root.loading; onClicked: root.refresh() }
            NocturneButton { Layout.fillWidth: true; text: "REFRESH SOURCES"; onClicked: root.openTask("refresh") }
        }
        Text {
            Layout.fillWidth: true
            text: "Privileged changes open visibly in a terminal. Nothing is installed silently."
            color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 9; wrapMode: Text.WordWrap
        }
    }
    Component.onCompleted: refresh()
}
