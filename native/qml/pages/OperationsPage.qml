import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"

Rectangle {
    id: root
    implicitWidth: 760
    implicitHeight: 590
    color: backend.baseColor
    border.color: state.level === "RED" ? "#c75c66" : (state.level === "AMBER" ? "#c69b54" : backend.accent2Color)
    property var state: ({
        level:"GREEN", score:100,
        node:{host:"node",kernel:"—",uptime:"—"},
        resources:{memory:0,swap:0,load1:"0",temperature:0,barMiB:0,barCpu:0},
        power:{profile:"unknown",source:"—",battery:0,charging:false},
        network:{interface:"offline",connection:"Disconnected",ip:"—",received:"0B",sent:"0B"},
        services:{failed:0,portal:false,pipewire:false,wireplumber:false,notifications:false,session:false,legacy:0},
        alerts:[]
    })
    readonly property string stateColor: state.level === "RED" ? "#ff6673" : (state.level === "AMBER" ? "#d9a85f" : backend.accentColor)

    function refresh() {
        var next = backend.json([backend.home + "/.config/hypr/scripts/noc-state", "status"], 2200)
        if (next && next.format === "nocturne-operations-v1") state = next
    }
    function serviceItems() {
        return [
            {name:"PORTAL", ok:Boolean(state.services.portal), detail:"screen share + chooser"},
            {name:"PIPEWIRE", ok:Boolean(state.services.pipewire), detail:"audio graph"},
            {name:"WIREPLUMBER", ok:Boolean(state.services.wireplumber), detail:"route policy"},
            {name:"NOTIFY", ok:Boolean(state.services.notifications), detail:"D-Bus provider"},
            {name:"SESSION", ok:Boolean(state.services.session), detail:"supervised target"},
            {name:"SHELL", ok:Number(state.services.legacy) === 0, detail:Number(state.services.legacy) === 0 ? "single owner" : state.services.legacy + " competitor(s)"}
        ]
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Text { text: "NOC // OPERATIONS DECK"; color: backend.textColor; font.family: "Inter"; font.bold: true; font.pixelSize: 12; font.letterSpacing: 1.1 }
                Text { text: root.state.node.host + "  ·  " + root.state.node.kernel + "  ·  UP " + root.state.node.uptime; color: backend.mutedColor; font.family: "monospace"; font.pixelSize: 9 }
            }
            Text { text: "● " + root.state.level; color: root.stateColor; font.family: "monospace"; font.bold: true; font.pixelSize: 11 }
            Text { text: String(root.state.score).padStart(3, "0"); color: backend.textColor; font.family: "monospace"; font.bold: true; font.pixelSize: 27 }
        }
        Rectangle { Layout.fillWidth: true; height: 1; color: backend.lineColor }

        RowLayout {
            Layout.fillWidth: true
            spacing: 7
            Repeater {
                model: [
                    {tag:"MEM", value:root.state.resources.memory + "%", detail:"SWAP " + root.state.resources.swap + "%"},
                    {tag:"LOAD", value:String(root.state.resources.load1), detail:"1 MINUTE"},
                    {tag:"THERMAL", value:(root.state.resources.temperature > 0 ? root.state.resources.temperature + "°" : "—"), detail:"PACKAGE"},
                    {tag:"SHELL", value:root.state.resources.barMiB + "M", detail:Number(root.state.resources.barCpu).toFixed(1) + "% CPU"}
                ]
                Rectangle {
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: 76
                    color: backend.surfaceColor
                    border.color: backend.lineColor
                    ColumnLayout {
                        anchors.fill: parent; anchors.margins: 8; spacing: 1
                        Text { text: modelData.tag; color: backend.accent2Color; font.family: "monospace"; font.bold: true; font.pixelSize: 8 }
                        Text { text: modelData.value; color: backend.textColor; font.family: "monospace"; font.bold: true; font.pixelSize: 22 }
                        Text { text: modelData.detail; color: backend.mutedColor; font.family: "monospace"; font.pixelSize: 8 }
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            Rectangle {
                Layout.fillWidth: true; Layout.preferredWidth: 1
                implicitHeight: 138; color: backend.surfaceColor; border.color: backend.lineColor
                ColumnLayout {
                    anchors.fill: parent; anchors.margins: 9; spacing: 5
                    SectionLabel { text: "NETWORK LINK" }
                    Text { Layout.fillWidth: true; text: root.state.network.connection.toUpperCase(); color: backend.textColor; font.family: "monospace"; font.bold: true; font.pixelSize: 11; elide: Text.ElideRight }
                    Text { text: root.state.network.interface + "  //  " + root.state.network.ip; color: backend.accentColor; font.family: "monospace"; font.pixelSize: 9 }
                    Item { Layout.fillHeight: true }
                    Text { text: "RX  " + root.state.network.received + "    TX  " + root.state.network.sent; color: backend.mutedColor; font.family: "monospace"; font.pixelSize: 9 }
                }
            }
            Rectangle {
                Layout.fillWidth: true; Layout.preferredWidth: 1
                implicitHeight: 138; color: backend.surfaceColor; border.color: backend.lineColor
                ColumnLayout {
                    anchors.fill: parent; anchors.margins: 9; spacing: 5
                    SectionLabel { text: "POWER ENVELOPE" }
                    Text { text: root.state.power.profile.toUpperCase(); color: backend.textColor; font.family: "monospace"; font.bold: true; font.pixelSize: 11 }
                    Text { text: root.state.power.source + (root.state.power.battery > 0 ? "  //  " + root.state.power.battery + "%" : ""); color: backend.accentColor; font.family: "monospace"; font.pixelSize: 9 }
                    Item { Layout.fillHeight: true }
                    Text { text: root.state.power.charging ? "EXTERNAL POWER · CHARGING" : "ADAPTIVE POLICY ACTIVE"; color: backend.mutedColor; font.family: "monospace"; font.pixelSize: 8 }
                }
            }
        }

        SectionLabel { text: "CONTROL PLANE" }
        GridLayout {
            Layout.fillWidth: true
            columns: 2
            columnSpacing: 7; rowSpacing: 7
            Repeater {
                model: root.serviceItems()
                Rectangle {
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: 48
                    color: "transparent"
                    border.color: backend.lineColor
                    RowLayout {
                        anchors.fill: parent; anchors.margins: 8; spacing: 8
                        Text { text: modelData.ok ? "●" : "×"; color: modelData.ok ? backend.accentColor : "#ff6673"; font.pixelSize: 12 }
                        ColumnLayout {
                            Layout.fillWidth: true; spacing: 0
                            Text { text: modelData.name; color: backend.textColor; font.family: "monospace"; font.bold: true; font.pixelSize: 9 }
                            Text { text: modelData.detail; color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 8 }
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 48
            color: root.state.alerts.length ? "#1b1212" : backend.surfaceColor
            border.color: root.state.alerts.length ? "#613038" : backend.lineColor
            RowLayout {
                anchors.fill: parent; anchors.margins: 8
                Text { text: root.state.alerts.length ? "!" : "✓"; color: root.state.alerts.length ? "#ff8c96" : backend.accentColor; font.family: "monospace"; font.bold: true; font.pixelSize: 14 }
                Text { Layout.fillWidth: true; text: root.state.alerts.length ? root.state.alerts.join("  //  ") : "ALL MONITORED SYSTEMS NOMINAL"; color: backend.textColor; font.family: "monospace"; font.bold: true; font.pixelSize: 9; elide: Text.ElideRight }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            NocturneButton { Layout.fillWidth: true; text: "MAINTENANCE"; onClicked: backend.start([backend.home + "/.local/bin/nocturne-native", "maintenance"]) }
            NocturneButton { Layout.fillWidth: true; text: "SETTINGS"; onClicked: backend.start([backend.home + "/.local/bin/nocturne-settings", "overview"]) }
            NocturneButton { Layout.fillWidth: true; text: "RUN DOCTOR"; onClicked: backend.start(["kitty", "--class", "nocturne-doctor", "--title", "NOC // DOCTOR", "-e", backend.home + "/.local/bin/nocturne-doctor"]) }
            NocturneButton { text: "REFRESH"; onClicked: root.refresh() }
        }
        Text { Layout.alignment: Qt.AlignRight; text: "LIVE WHILE OPEN  //  ZERO IDLE TELEMETRY"; color: backend.mutedColor; font.family: "monospace"; font.pixelSize: 7 }
    }

    Timer { interval: 2500; running: true; repeat: true; triggeredOnStart: true; onTriggered: root.refresh() }
}
