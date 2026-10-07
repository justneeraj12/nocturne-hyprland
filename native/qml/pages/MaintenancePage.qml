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
    property var state: ({packages:0, flatpak:0, firmware:0, failed:0, platform:{packageLabel:"SYSTEM PACKAGES"}, guard:{phase:"unavailable",risk:"critical",reason:"CHECKING",prepared:false,checkpoint:false,hyprland:{current:"unknown",pending:""}}})
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

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: guardColumn.implicitHeight + 18
            color: backend.surfaceColor
            border.color: root.state.guard.risk === "critical" ? "#c75c66" : (root.state.guard.risk === "review" ? "#c69b54" : backend.accentColor)
            ColumnLayout {
                id: guardColumn
                anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                anchors.margins: 9; spacing: 5
                RowLayout {
                    Layout.fillWidth: true
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 1
                        Text { text: "NOC UPDATE GUARD"; color: backend.textColor; font.family: "Inter"; font.bold: true; font.pixelSize: 10 }
                        Text { text: root.state.guard.reason || "CHECKING"; color: root.state.guard.risk === "critical" ? "#ff8c96" : (root.state.guard.risk === "review" ? "#d9a85f" : backend.accentColor); font.family: "monospace"; font.bold: true; font.pixelSize: 8 }
                    }
                    Text {
                        text: String(root.state.guard.hyprland.current || "unknown") + (root.state.guard.hyprland.pending ? "  →  " + root.state.guard.hyprland.pending : "")
                        color: backend.mutedColor; font.family: "monospace"; font.pixelSize: 8
                    }
                }
                Text {
                    Layout.fillWidth: true
                    text: "Checkpoint the desktop, record critical package state, then verify config, shell and portal health after upgrading."
                    color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 8; wrapMode: Text.WordWrap
                }
                RowLayout {
                    Layout.fillWidth: true; spacing: 5
                    NocturneButton { Layout.fillWidth: true; text: "PREPARE"; onClicked: root.openTask("prepare") }
                    NocturneButton { Layout.fillWidth: true; text: "GUARDED UPGRADE"; selected: true; onClicked: root.openTask("packages") }
                    NocturneButton { Layout.fillWidth: true; text: "VERIFY"; onClicked: root.openTask("verify") }
                }
            }
        }

        Repeater {
            model: [
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
