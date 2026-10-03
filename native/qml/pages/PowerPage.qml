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
    function refresh() {
        var status = backend.run([backend.home + "/.config/hypr/scripts/power-profile", "status"]).split("\t")
        profile = status[0] || "balanced"; detail = status.slice(1).join(" ")
        var capacity = backend.readFirst("/sys/class/power_supply", "capacity").trim()
        battery = capacity ? parseInt(capacity) : -1
        batteryState = backend.readFirst("/sys/class/power_supply", "status").trim().toUpperCase() || "EXTERNAL POWER"
    }
    function setProfile(name) {
        if (name === "boost") backend.start([backend.home + "/.config/hypr/scripts/power-profile", "boost", "30"])
        else backend.start([backend.home + "/.config/hypr/scripts/power-profile", "set", name])
        delayed.restart()
    }
    ColumnLayout {
        id: panel; x: 10; y: 10; width: parent.width - 20; spacing: 8
        PanelHeader { Layout.fillWidth: true; title: "Power"; subtitle: "Battery, performance and session" }
        Text { text: root.battery >= 0 ? root.battery + "%" : "AC POWER"; color: backend.textColor; font.family: "Inter"; font.pixelSize: 18; font.bold: true }
        Text { text: root.batteryState; color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 10 }
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
        SectionLabel { text: "SESSION" }
        RowLayout {
            Layout.fillWidth: true; spacing: 5
            NocturneButton { Layout.fillWidth: true; text: "LOCK"; onClicked: { backend.start([backend.home + "/.config/hypr/scripts/lock-screen"]); backend.close() } }
            NocturneButton { Layout.fillWidth: true; text: "SLEEP"; onClicked: { backend.start(["systemctl", "suspend"]); backend.close() } }
            NocturneButton { Layout.fillWidth: true; text: "LOG OUT"; onClicked: { backend.start(["uwsm", "stop"]); backend.close() } }
        }
        RowLayout {
            Layout.fillWidth: true; spacing: 5
            NocturneButton { Layout.fillWidth: true; text: "RESTART"; danger: true; onClicked: confirmRestart.visible = true }
            NocturneButton { Layout.fillWidth: true; text: "SHUT DOWN"; danger: true; onClicked: confirmShutdown.visible = true }
        }
        NocturneButton {
            id: confirmRestart; visible: false; Layout.fillWidth: true; text: "CONFIRM RESTART"; danger: true
            onClicked: backend.start(["systemctl", "reboot"])
        }
        NocturneButton {
            id: confirmShutdown; visible: false; Layout.fillWidth: true; text: "CONFIRM SHUT DOWN"; danger: true
            onClicked: backend.start(["systemctl", "poweroff"])
        }
    }
    Timer { interval: 3000; running: true; repeat: true; triggeredOnStart: true; onTriggered: root.refresh() }
    Timer { id: delayed; interval: 1200; onTriggered: root.refresh() }
}
