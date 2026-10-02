import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"

Rectangle {
    id: root
    required property string initialPage
    implicitWidth: 410
    implicitHeight: panel.implicitHeight + 20
    color: backend.baseColor; border.color: backend.accent2Color; border.width: 1
    property string tab: initialPage
    property var wifi: []
    property var bluetooth: []
    property var vpn: []
    property string selectedSsid: ""

    function refresh() {
        if (tab === "wifi") {
            var rows = backend.run(["nmcli", "-t", "--escape", "no", "-f", "IN-USE,SSID,SIGNAL,SECURITY", "device", "wifi", "list", "--rescan", "no"])
            var seen = {}
            wifi = rows.split("\n").filter(function(line) { return line.length > 0 }).map(function(line) {
                var f = line.split(":"); return {active:f[0] === "*",ssid:f[1] || "",signal:parseInt(f[2] || "0"),security:f.slice(3).join(":") || "OPEN"}
            }).filter(function(item) { if (!item.ssid || seen[item.ssid]) return false; seen[item.ssid] = true; return true }).sort(function(a,b) { return a.active ? -1 : (b.active ? 1 : b.signal-a.signal) })
        } else if (tab === "bluetooth") {
            var devices = backend.run(["bluetoothctl", "devices"]).split("\n")
            var connected = backend.run(["bluetoothctl", "devices", "Connected"])
            bluetooth = devices.filter(function(line) { return line.indexOf("Device ") === 0 }).map(function(line) {
                var fields = line.split(" "); var mac = fields[1]; return {mac:mac,name:fields.slice(2).join(" "),active:connected.indexOf(mac) >= 0}
            })
        } else {
            var active = backend.run(["nmcli", "-t", "--escape", "no", "-f", "NAME,TYPE", "connection", "show", "--active"])
            vpn = backend.run(["nmcli", "-t", "--escape", "no", "-f", "NAME,TYPE", "connection", "show"]).split("\n").map(function(line) {
                var f=line.split(":"); return {name:f[0] || "",type:f[1] || "",active:active.indexOf((f[0] || "") + ":") >= 0}
            }).filter(function(item) { return item.type === "vpn" || item.type === "wireguard" })
        }
    }

    ColumnLayout {
        id: panel; x: 10; y: 10; width: parent.width - 20; spacing: 7
        SectionLabel { text: "CONNECTIVITY // NATIVE CONTROL" }
        RowLayout {
            Layout.fillWidth: true; spacing: 5
            Repeater {
                model: [{key:"wifi",label:"WI-FI"},{key:"bluetooth",label:"BLUETOOTH"},{key:"vpn",label:"VPN"}]
                NocturneButton {
                    required property var modelData
                    Layout.fillWidth: true; text: modelData.label; selected: root.tab === modelData.key
                    onClicked: { root.tab = modelData.key; root.refresh() }
                }
            }
        }
        RowLayout {
            Layout.fillWidth: true
            Text {
                Layout.fillWidth: true
                text: root.tab === "wifi" ? "NetworkManager radio" : (root.tab === "bluetooth" ? "BlueZ radio" : "NetworkManager tunnels")
                color: backend.textColor; font.family: "Inter"; font.bold: true
            }
            NocturneButton {
                visible: root.tab !== "vpn"
                text: {
                    if (root.tab === "wifi") return backend.run(["nmcli", "-t", "-f", "WIFI", "general"]) === "enabled" ? "ON" : "OFF"
                    return backend.run(["bluetoothctl", "show"]).indexOf("Powered: yes") >= 0 ? "ON" : "OFF"
                }
                selected: text === "ON"
                onClicked: {
                    if (root.tab === "wifi") backend.run(["nmcli", "radio", "wifi", text === "ON" ? "off" : "on"])
                    else backend.run(["bluetoothctl", "power", text === "ON" ? "off" : "on"])
                    root.refresh()
                }
            }
        }
        SectionLabel { text: root.tab === "wifi" ? "AVAILABLE NETWORKS" : (root.tab === "bluetooth" ? "PAIRED + DISCOVERED" : "VPN PROFILES") }
        Repeater {
            model: root.tab === "wifi" ? root.wifi : (root.tab === "bluetooth" ? root.bluetooth : root.vpn)
            delegate: Rectangle {
                required property var modelData
                Layout.fillWidth: true; implicitHeight: 48
                color: backend.surfaceColor; border.color: modelData.active ? backend.accentColor : backend.lineColor
                RowLayout {
                    anchors.fill: parent; anchors.margins: 7
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 1
                        Text { text: root.tab === "wifi" ? modelData.ssid : modelData.name; color: backend.textColor; font.family: "monospace"; font.bold: true }
                        Text {
                            text: modelData.active ? "CONNECTED" : (root.tab === "wifi" ? modelData.signal + "% · " + modelData.security : (root.tab === "bluetooth" ? modelData.mac : modelData.type.toUpperCase()))
                            color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 9
                        }
                    }
                    NocturneButton {
                        text: modelData.active ? "DISCONNECT" : "CONNECT"
                        selected: modelData.active
                        onClicked: {
                            if (root.tab === "wifi") {
                                if (modelData.active) backend.start(["nmcli", "device", "disconnect", backend.run(["nmcli", "-t", "-f", "DEVICE,TYPE,STATE", "device"]).split("\n").filter(function(x){return x.indexOf(":wifi:connected")>0})[0].split(":")[0]])
                                else backend.start(["nmcli", "connection", "up", "id", modelData.ssid])
                            } else if (root.tab === "bluetooth") backend.start(["bluetoothctl", modelData.active ? "disconnect" : "connect", modelData.mac])
                            else backend.start(["nmcli", "connection", modelData.active ? "down" : "up", "id", modelData.name])
                            delayed.restart()
                        }
                    }
                }
            }
        }
        NocturneButton {
            visible: root.tab === "bluetooth"
            Layout.fillWidth: true; text: "SCAN FOR DEVICES"
            onClicked: { backend.start(["bluetoothctl", "--timeout", "5", "scan", "on"]); delayed.restart() }
        }
    }
    Timer { interval: 3000; running: true; repeat: true; triggeredOnStart: true; onTriggered: root.refresh() }
    Timer { id: delayed; interval: 1800; onTriggered: root.refresh() }
}
