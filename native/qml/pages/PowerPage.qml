import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"

Rectangle {
    id: root
    implicitWidth: 410
    implicitHeight: panel.implicitHeight + 20
    color: backend.baseColor; border.color: backend.accent2Color; border.width: 1
    property string profile: "balanced"
    property string detail: ""
    property int battery: -1
    property string batteryState: "EXTERNAL POWER"
    property string pendingSessionAction: ""
    property var gaming: ({active:false, enabled:false, games:0, title:"Waiting for a Steam game"})
    property var lab: ({battery:{health:-1,cycles:-1},charge:{supported:false,threshold:-1},sleep:{current:"",deepAvailable:false},adaptiveSaver:false,lowBattery:20})
    function refresh() {
        var status = backend.run([backend.home + "/.config/hypr/scripts/power-profile", "status"]).split("\t")
        profile = status[0] || "balanced"; detail = status.slice(1).join(" ")
        var capacity = backend.readFirst("/sys/class/power_supply", "capacity").trim()
        battery = capacity ? parseInt(capacity) : -1
        batteryState = backend.readFirst("/sys/class/power_supply", "status").trim().toUpperCase() || "EXTERNAL POWER"
        gaming = backend.json([backend.home + "/.config/hypr/scripts/game-session", "status"], 1600) || gaming
        var nextLab = backend.json([backend.home + "/.config/hypr/scripts/power-lab", "status"], 1800)
        if (nextLab && nextLab.battery && nextLab.sleep) lab = nextLab
    }
    function setProfile(name) {
        if (name === "boost") backend.start([backend.home + "/.config/hypr/scripts/power-profile", "boost", "30"])
        else backend.start([backend.home + "/.config/hypr/scripts/power-profile", "set", name])
        delayed.restart()
    }
    function armSessionAction(action) { pendingSessionAction = action; confirmTimeout.restart() }
    function performSessionAction() {
        if (pendingSessionAction === "restart") backend.start(["systemctl", "reboot"])
        else if (pendingSessionAction === "poweroff") backend.start(["systemctl", "poweroff"])
        pendingSessionAction = ""
    }
    ColumnLayout {
        id: panel; x: 10; y: 10; width: parent.width - 20; spacing: 8
        PanelHeader { Layout.fillWidth: true; title: "Power"; subtitle: "Battery, performance and session" }
        RowLayout {
            Layout.fillWidth: true; spacing: 8
            Text { text: root.batteryState.indexOf("CHARG") >= 0 ? "󰂄" : (root.battery >= 0 && root.battery <= 15 ? "󰁺" : "󰁹"); color: root.battery >= 0 && root.battery <= 15 && root.batteryState.indexOf("CHARG") < 0 ? "#ff8c96" : backend.accentColor; font.family: "MesloLGS Nerd Font Mono"; font.pixelSize: 20 }
            Text { text: root.battery >= 0 ? root.battery + "%" : "AC POWER"; color: root.battery >= 0 && root.battery <= 15 && root.batteryState.indexOf("CHARG") < 0 ? "#ff8c96" : backend.textColor; font.family: "Inter"; font.pixelSize: 18; font.bold: true }
            Text { Layout.fillWidth: true; text: root.batteryState; color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 10; horizontalAlignment: Text.AlignRight }
        }
        SectionLabel { text: "POWER MODE" }
        RowLayout {
            Layout.fillWidth: true; spacing: 5
            Repeater {
                model: [{key:"boost",label:"SUPER"},{key:"performance",label:"PERFORMANCE"},{key:"balanced",label:"BALANCED"},{key:"power-saver",label:"SAVER"}]
                NocturneButton {
                    required property var modelData
                    Layout.fillWidth: true; text: modelData.label; selected: root.profile === modelData.key
                    onClicked: root.setProfile(modelData.key)
                }
            }
        }
        Text { text: root.detail.toUpperCase(); color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 9 }
        SectionLabel { text: "BATTERY LAB" }
        Rectangle { Layout.fillWidth: true; implicitHeight: 64; color: backend.surfaceColor; border.color: backend.lineColor
            RowLayout { anchors.fill: parent; anchors.margins: 8; spacing: 8
                ColumnLayout { Layout.fillWidth: true; spacing: 2
                    Text { text: (root.lab.battery.health >= 0 ? root.lab.battery.health + "% HEALTH" : "HEALTH UNAVAILABLE") + " · " + (root.lab.sleep.current || "UNKNOWN").toUpperCase() + " SLEEP"; color: backend.textColor; font.family: "monospace"; font.pixelSize: 8; font.bold: true }
                    Text { text: root.lab.sleep.deepAvailable ? "DEEP SLEEP AVAILABLE" : "FIRMWARE EXPOSES S2IDLE ONLY"; color: root.lab.sleep.deepAvailable ? backend.accentColor : "#ffb36a"; font.family: "Inter"; font.pixelSize: 8 }
                }
                Text { visible: root.lab.charge.supported; text: "CHARGE LIMIT"; color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 7 }
                NocturneButton { visible: root.lab.charge.supported; text: (root.lab.charge.threshold || 100) + "%"; onClicked: { var next = root.lab.charge.threshold >= 100 ? 80 : (root.lab.charge.threshold >= 80 ? 60 : 100); backend.start([backend.home + "/.config/hypr/scripts/power-lab", "threshold", String(next)]); delayed.restart() } }
                Text { text: "AUTO SAVER"; color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 7 }
                NocturneToggle { checked: root.lab.adaptiveSaver; onToggleRequested: function(v) { backend.run([backend.home + "/.config/hypr/scripts/power-lab", "configure", "adaptiveSaver", String(v)], 2500); delayed.restart() } }
            }
        }
        SectionLabel { text: "GAMING MODE" }
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 50
            color: backend.surfaceColor
            border.color: root.gaming.active ? backend.accentColor : backend.lineColor
            RowLayout {
                anchors.fill: parent; anchors.margins: 8; spacing: 8
                Text { text: root.gaming.active ? "󰊴" : "󰊗"; color: root.gaming.active ? backend.accentColor : backend.mutedColor; font.family: "MesloLGS Nerd Font Mono"; font.pixelSize: 18 }
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 1
                    Text { text: root.gaming.active ? "AUTOMATIC MODE ACTIVE" : "AUTOMATIC GAME DETECTION"; color: backend.textColor; font.family: "Inter"; font.bold: true; font.pixelSize: 10 }
                    Text { Layout.fillWidth: true; text: root.gaming.title; color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 9; elide: Text.ElideRight }
                }
                NocturneToggle {
                    checked: root.gaming.enabled
                    onToggleRequested: function(enabled) {
                        backend.run([backend.home + "/.config/hypr/scripts/game-session", enabled ? "enable" : "disable"], 3000)
                        delayed.restart()
                    }
                }
            }
        }
        SectionLabel { text: "SESSION" }
        RowLayout {
            Layout.fillWidth: true; spacing: 5
            NocturneButton { Layout.fillWidth: true; text: "LOCK"; onClicked: { backend.start([backend.home + "/.config/hypr/scripts/lock-screen"]); backend.close() } }
            NocturneButton { Layout.fillWidth: true; text: "SLEEP"; onClicked: { backend.start(["systemctl", "suspend"]); backend.close() } }
            NocturneButton { Layout.fillWidth: true; text: "LOG OUT"; onClicked: { backend.start(["uwsm", "stop"]); backend.close() } }
        }
        RowLayout {
            Layout.fillWidth: true; spacing: 5
            NocturneButton { Layout.fillWidth: true; text: "RESTART"; danger: true; onClicked: root.armSessionAction("restart") }
            NocturneButton { Layout.fillWidth: true; text: "SHUT DOWN"; danger: true; onClicked: root.armSessionAction("poweroff") }
        }
        RowLayout {
            visible: root.pendingSessionAction !== ""; Layout.fillWidth: true; spacing: 5
            NocturneButton {
                Layout.fillWidth: true
                text: root.pendingSessionAction === "restart" ? "CONFIRM RESTART" : "CONFIRM SHUT DOWN"
                danger: true; onClicked: root.performSessionAction()
            }
            NocturneButton { text: "CANCEL"; onClicked: root.pendingSessionAction = "" }
        }
    }
    Timer { interval: 3000; running: true; repeat: true; triggeredOnStart: true; onTriggered: root.refresh() }
    Timer { id: delayed; interval: 1200; onTriggered: root.refresh() }
    Timer { id: confirmTimeout; interval: 6000; onTriggered: root.pendingSessionAction = "" }
}
