import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"

Rectangle {
    id: root
    implicitWidth: 510; implicitHeight: 445
    color: backend.baseColor; border.color: backend.accent2Color
    property var status: ({active:false,enabled:false,games:0,title:"Waiting for a Steam game",gpu:"Unavailable",gpuUsage:0,gpuMemory:0,gpuTemperature:0,hud:false})
    function refresh() { status = backend.json([backend.home + "/.config/hypr/scripts/gaming-control", "status"], 2500) || status }
    ColumnLayout {
        anchors.fill: parent; anchors.margins: 12; spacing: 9
        PanelHeader { Layout.fillWidth: true; title: "Gaming Dashboard"; subtitle: root.status.active ? root.status.title : "Automatic, reversible game-session tuning" }
        Rectangle {
            Layout.fillWidth: true; implicitHeight: 82; color: backend.surfaceColor; border.color: root.status.active ? backend.accentColor : backend.lineColor
            RowLayout { anchors.fill: parent; anchors.margins: 10
                ColumnLayout { Layout.fillWidth: true; spacing: 2
                    Text { text: root.status.gpu; color: backend.textColor; font.family: "monospace"; font.bold: true; font.pixelSize: 12; elide: Text.ElideRight }
                    Text { text: "GPU " + root.status.gpuUsage + "%   VRAM " + root.status.gpuMemory + " MiB   " + root.status.gpuTemperature + "°C"; color: backend.accentColor; font.family: "monospace"; font.pixelSize: 10 }
                    Text { text: root.status.active ? "GAME SESSION ACTIVE" : "GPU SAMPLED ONLY WHILE THIS CARD IS OPEN"; color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 8 }
                }
                Text { text: root.status.gpuUsage + "%"; color: backend.textColor; font.family: "monospace"; font.pixelSize: 24; font.bold: true }
            }
        }
        SectionLabel { text: "AUTOMATION" }
        Rectangle {
            Layout.fillWidth: true; implicitHeight: 56; color: backend.surfaceColor; border.color: backend.lineColor
            RowLayout { anchors.fill: parent; anchors.margins: 9
                ColumnLayout { Layout.fillWidth: true; spacing: 1
                    Text { text: "STEAM GAME DETECTION"; color: backend.textColor; font.family: "monospace"; font.bold: true; font.pixelSize: 10 }
                    Text { text: "Performance, caffeine and focus roll back exactly when the game closes."; color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 8 }
                }
                NocturneToggle { checked: root.status.enabled; onToggleRequested: function(enabled) { backend.run([backend.home + "/.config/hypr/scripts/game-session", enabled ? "enable" : "disable"], 3000); delayed.restart() } }
            }
        }
        RowLayout {
            Layout.fillWidth: true; spacing: 5
            NocturneButton { Layout.fillWidth: true; text: root.status.hud ? "MANGOHUD ON" : "MANGOHUD OFF"; selected: root.status.hud; onClicked: { backend.run([backend.home + "/.config/hypr/scripts/gaming-control", "hud", root.status.hud ? "false" : "true"]); root.refresh() } }
            NocturneButton { Layout.fillWidth: true; text: "OPEN STEAM"; onClicked: backend.start([backend.home + "/.config/hypr/scripts/steam-launch"]) }
            NocturneButton { Layout.fillWidth: true; text: "GAME MODE NOW"; onClicked: backend.run([backend.home + "/.config/hypr/scripts/game-session", "refresh"]) }
        }
        SectionLabel { text: "WHAT CHANGES" }
        Repeater { model: [
            {icon:"⚡",title:"PERFORMANCE",detail:"Uses the supported power profile; no unsafe overclock."},
            {icon:"☕",title:"CAFFEINE",detail:"Prevents idle lock while a detected game is active."},
            {icon:"◌",title:"FOCUS",detail:"Silences popups, then restores the previous notification mode."}
        ]; Rectangle { required property var modelData; Layout.fillWidth: true; implicitHeight: 43; color: "transparent"; border.color: backend.lineColor
            RowLayout { anchors.fill: parent; anchors.margins: 7
                Text { text: modelData.icon; color: backend.accentColor; font.pixelSize: 15 }
                Text { text: modelData.title; color: backend.textColor; font.family: "monospace"; font.bold: true; font.pixelSize: 9 }
                Text { Layout.fillWidth: true; text: modelData.detail; color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 8; elide: Text.ElideRight }
            }
        } }
        Item { Layout.fillHeight: true }
    }
    Timer { interval: 2000; running: true; repeat: true; triggeredOnStart: true; onTriggered: root.refresh() }
    Timer { id: delayed; interval: 900; onTriggered: root.refresh() }
}
