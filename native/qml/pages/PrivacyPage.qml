import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"

Rectangle {
    id: root
    implicitWidth: 460; implicitHeight: Math.max(310, 190 + items.length * 58)
    color: backend.baseColor; border.color: backend.accent2Color
    property var items: []
    property int confirmPid: -1
    function refresh() { items = backend.privacyItems() }
    ColumnLayout {
        anchors.fill: parent; anchors.margins: 12; spacing: 8
        PanelHeader { Layout.fillWidth: true; title: "Privacy Dashboard"; subtitle: root.items.length ? root.items.length + " active capture clients" : "Microphone, camera and screen sharing are idle" }
        Rectangle {
            Layout.fillWidth: true; implicitHeight: 52
            color: root.items.length ? "#241012" : backend.surfaceColor
            border.color: root.items.length ? "#c75c66" : backend.lineColor
            RowLayout { anchors.fill: parent; anchors.margins: 9
                Text { text: root.items.length ? "●" : "○"; color: root.items.length ? "#ff6673" : backend.accentColor; font.pixelSize: 16 }
                Text { Layout.fillWidth: true; text: root.items.length ? "A SENSOR IS CURRENTLY IN USE" : "NO ACTIVE SENSOR ACCESS"; color: backend.textColor; font.family: "monospace"; font.bold: true; font.pixelSize: 10 }
            }
        }
        Repeater { model: root.items; Rectangle {
            required property var modelData; Layout.fillWidth: true; implicitHeight: 52; color: backend.surfaceColor; border.color: backend.lineColor
            RowLayout { anchors.fill: parent; anchors.margins: 8
                Text { text: modelData.kind === "screen" ? "󰍹" : (modelData.kind === "camera" ? "󰄀" : "󰍬"); color: "#ff6673"; font.family: "MesloLGS Nerd Font Mono"; font.pixelSize: 18 }
                ColumnLayout { Layout.fillWidth: true; spacing: 1
                    Text { text: (modelData.app || "Unknown application").toUpperCase(); color: backend.textColor; font.family: "monospace"; font.bold: true; font.pixelSize: 10 }
                    Text { text: modelData.kind.toUpperCase() + (modelData.pid > 1 ? " · PID " + modelData.pid : " · PORTAL MANAGED"); color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 8 }
                }
                Text { visible: !modelData.stoppable; text: modelData.kind === "screen" ? "END IN SHARING APP" : "PROVIDER MANAGED"; color: backend.mutedColor; font.family: "monospace"; font.pixelSize: 8; font.bold: true }
                NocturneButton { visible: Boolean(modelData.stoppable); text: root.confirmPid === modelData.pid ? "CONFIRM STOP" : "STOP"; danger: true; onClicked: { if (root.confirmPid !== modelData.pid) root.confirmPid = modelData.pid; else { backend.stopPrivacyClient(modelData.pid); root.confirmPid = -1; refreshDelay.restart() } } }
            }
        } }
        SectionLabel { text: "PRIVACY SHORTCUTS" }
        RowLayout { Layout.fillWidth: true
            NocturneButton { Layout.fillWidth: true; text: "MUTE MIC"; onClicked: backend.run(["wpctl", "set-mute", "@DEFAULT_AUDIO_SOURCE@", "toggle"]) }
            NocturneButton { Layout.fillWidth: true; text: "PIPEWIRE GRAPH"; onClicked: backend.start(["qpwgraph"]) }
        }
        Text { Layout.fillWidth: true; text: "Microphone clients can be stopped here. End portal screen sharing from Meet, Discord or the browser so the session and permission close cleanly."; color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 8; wrapMode: Text.WordWrap }
        Item { Layout.fillHeight: true }
    }
    Timer { interval: 1600; running: true; repeat: true; triggeredOnStart: true; onTriggered: root.refresh() }
    Timer { id: refreshDelay; interval: 500; onTriggered: root.refresh() }
}
