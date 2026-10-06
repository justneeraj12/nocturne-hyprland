import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"

Rectangle {
    id: root
    property string initialPage: "wifi"
    implicitWidth: 410
    implicitHeight: panel.implicitHeight + 20
    color: backend.baseColor
    border.color: backend.accent2Color
    border.width: 1

    property string tab: initialPage
    property var wifi: []
    property var bluetooth: []
    property var vpn: []
    property bool wifiEnabled: false
    property bool bluetoothEnabled: false
    property bool bluetoothAvailable: true
    property bool vpnEnabled: false
    property string connectivity: "unknown"
    property bool metered: false
    property string activeWifiDevice: ""
    property string activeWifiProfile: ""
    property var tools: ({hotspotActive:false,hotspot:"",qrAvailable:false})
    property string qrPath: ""

    onInitialPageChanged: {
        tab = initialPage
        refresh()
    }

    readonly property bool currentEnabled: tab === "wifi" ? wifiEnabled : (tab === "bluetooth" ? bluetoothEnabled : vpnEnabled)
    readonly property bool currentAvailable: tab !== "bluetooth" || bluetoothAvailable
    readonly property string currentName: tab === "wifi" ? "Wi-Fi" : (tab === "bluetooth" ? "Bluetooth" : "VPN")
    readonly property string currentDetail: {
        if (tab === "wifi") {
            if (!wifiEnabled) return "Wireless networking is off"
            var state = connectivity === "full" ? "Internet online" : (connectivity === "portal" ? "Sign-in required" : (connectivity === "limited" ? "Limited internet" : "Connectivity unknown"))
            return state + (activeWifiProfile ? " · " + activeWifiProfile : "")
        }
        if (tab === "bluetooth") {
            if (!bluetoothAvailable) return "No Bluetooth adapter detected"
            return bluetoothEnabled ? "Nearby and paired devices are available" : "Bluetooth is off"
        }
        var connected = vpn.filter(function(item) { return item.active }).map(function(item) { return item.name })
        return connected.length > 0 ? connected.join(", ") + " connected" : "No secure tunnel connected"
    }

    function refresh() {
        var nextTools = backend.json([backend.home + "/.config/hypr/scripts/connectivity-tools", "status"], 2500)
        if (nextTools && nextTools.hotspotActive !== undefined) tools = nextTools
        wifiEnabled = backend.run(["nmcli", "-t", "-f", "WIFI", "general"]) === "enabled"
        connectivity = backend.run(["nmcli", "-t", "networking", "connectivity"]) || "unknown"
        var connectedWifi = backend.run(["nmcli", "-t", "--escape", "no", "-f", "DEVICE,TYPE,STATE,CONNECTION", "device"]).split("\n").filter(function(line) {
            return line.indexOf(":wifi:connected:") > 0
        })[0] || ""
        var wifiFields = connectedWifi.split(":")
        activeWifiDevice = wifiFields[0] || ""
        activeWifiProfile = wifiFields.slice(3).join(":") || ""
        var meterState = activeWifiDevice ? backend.run(["nmcli", "-g", "GENERAL.METERED", "device", "show", activeWifiDevice]).toLowerCase() : ""
        metered = meterState === "yes" || meterState.indexOf("guess yes") >= 0

        var bluetoothState = backend.run(["bluetoothctl", "show"])
        bluetoothAvailable = bluetoothState !== ""
        bluetoothEnabled = bluetoothState.indexOf("Powered: yes") >= 0

        var activeConnections = backend.run(["nmcli", "-t", "--escape", "no", "-f", "NAME,TYPE", "connection", "show", "--active"])
        var activeNames = activeConnections.split("\n").filter(function(line) {
            return line.endsWith(":vpn") || line.endsWith(":wireguard")
        }).map(function(line) { return line.substring(0, line.lastIndexOf(":")) })

        var profiles = backend.run(["nmcli", "-t", "--escape", "no", "-f", "NAME,TYPE", "connection", "show"])
        vpn = profiles.split("\n").map(function(line) {
            var separator = line.lastIndexOf(":")
            var name = separator >= 0 ? line.substring(0, separator) : line
            var type = separator >= 0 ? line.substring(separator + 1) : ""
            return {name:name, type:type, active:activeNames.indexOf(name) >= 0}
        }).filter(function(item) { return item.name !== "" && (item.type === "vpn" || item.type === "wireguard") })
        vpnEnabled = activeNames.length > 0

        if (tab === "wifi") {
            if (!wifiEnabled) { wifi = []; return }
            var rows = backend.run(["nmcli", "-t", "--escape", "no", "-f", "IN-USE,SSID,SIGNAL,SECURITY", "device", "wifi", "list", "--rescan", "no"])
            var seen = {}
            wifi = rows.split("\n").filter(function(line) { return line.length > 0 }).map(function(line) {
                var f = line.split(":")
                return {active:f[0] === "*", ssid:f[1] || "", signal:parseInt(f[2] || "0"), security:f.slice(3).join(":") || "Open"}
            }).filter(function(item) {
                if (!item.ssid || seen[item.ssid]) return false
                seen[item.ssid] = true
                return true
            }).sort(function(a, b) { return a.active ? -1 : (b.active ? 1 : b.signal - a.signal) })
        } else if (tab === "bluetooth") {
            if (!bluetoothEnabled) { bluetooth = []; return }
            var devices = backend.run(["bluetoothctl", "devices"]).split("\n")
            var connected = backend.run(["bluetoothctl", "devices", "Connected"])
            var cards = backend.json(["pactl", "-f", "json", "list", "cards"], 1500) || []
            bluetooth = devices.filter(function(line) { return line.indexOf("Device ") === 0 }).map(function(line) {
                var fields = line.split(" ")
                var mac = fields[1]
                var info = backend.run(["bluetoothctl", "info", mac], 1200)
                var battery = (info.match(/Battery Percentage:.*\((\d+)\)/) || [])[1] || ""
                var cardName = "bluez_card." + mac.replace(/:/g, "_")
                var found = cards.filter(function(x){ return x.name === cardName })[0]
                var codec = found ? String(found.active_profile || "").replace(/^a2dp-sink-?/, "").replace(/^a2dp-sink$/, "A2DP") : ""
                return {mac:mac, name:fields.slice(2).join(" "), active:connected.indexOf(mac) >= 0,battery:battery,codec:codec}
            }).sort(function(a, b) { return a.active ? -1 : (b.active ? 1 : a.name.localeCompare(b.name)) })
        }
    }

    function setMetered(enabled) {
        if (!activeWifiProfile) return
        metered = enabled
        backend.start(["nmcli", "connection", "modify", "id", activeWifiProfile, "connection.metered", enabled ? "yes" : "no"])
        delayed.restart()
    }

    function setCurrentEnabled(enabled) {
        if (tab === "wifi") {
            wifiEnabled = enabled
            backend.start(["nmcli", "radio", "wifi", enabled ? "on" : "off"])
        } else if (tab === "bluetooth") {
            bluetoothEnabled = enabled
            backend.start(["bluetoothctl", "power", enabled ? "on" : "off"])
        } else if (enabled) {
            var target = vpn.filter(function(item) { return !item.active })[0]
            if (target) backend.start(["nmcli", "connection", "up", "id", target.name])
        } else {
            vpn.filter(function(item) { return item.active }).forEach(function(item) {
                backend.start(["nmcli", "connection", "down", "id", item.name])
            })
        }
        delayed.restart()
    }

    function toggleConnection(item) {
        if (tab === "wifi") {
            if (item.active) {
                var row = backend.run(["nmcli", "-t", "-f", "DEVICE,TYPE,STATE", "device"]).split("\n").filter(function(value) {
                    return value.indexOf(":wifi:connected") > 0
                })[0]
                if (row) backend.start(["nmcli", "device", "disconnect", row.split(":")[0]])
            } else backend.start(["nmcli", "connection", "up", "id", item.ssid])
        } else if (tab === "bluetooth") {
            backend.start(["bluetoothctl", item.active ? "disconnect" : "connect", item.mac])
        } else {
            backend.start(["nmcli", "connection", item.active ? "down" : "up", "id", item.name])
        }
        delayed.restart()
    }

    ColumnLayout {
        id: panel
        x: 10
        y: 10
        width: parent.width - 20
        spacing: 8

        PanelHeader {
            Layout.fillWidth: true
            title: "Connections"
            subtitle: "Wi-Fi · Bluetooth · VPN"
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 5
            Repeater {
                model: [{key:"wifi", label:"WI-FI"}, {key:"bluetooth", label:"BLUETOOTH"}, {key:"vpn", label:"VPN"}]
                NocturneButton {
                    required property var modelData
                    Layout.fillWidth: true
                    text: modelData.label
                    selected: root.tab === modelData.key
                    onClicked: { root.tab = modelData.key; root.refresh() }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 50
            color: backend.surfaceColor
            border.color: backend.lineColor
            RowLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 8
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1
                    Text { text: root.currentName; color: backend.textColor; font.family: "Inter"; font.bold: true; font.pixelSize: 11 }
                    Text { Layout.fillWidth: true; text: root.currentDetail; color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 9; elide: Text.ElideRight }
                }
                NocturneToggle {
                    checked: root.currentEnabled
                    available: root.currentAvailable && (root.tab !== "vpn" || root.vpn.length > 0)
                    onToggleRequested: function(enabled) { root.setCurrentEnabled(enabled) }
                }
            }
        }

        RowLayout {
            visible: root.tab === "wifi" && root.wifiEnabled
            Layout.fillWidth: true; spacing: 5
            NocturneButton {
                Layout.fillWidth: true; text: root.tools.hotspotActive ? "STOP HOTSPOT" : "START HOTSPOT"
                onClicked: { backend.start([backend.home + "/.config/hypr/scripts/connectivity-tools", root.tools.hotspotActive ? "hotspot-off" : "hotspot-on", root.activeWifiDevice]); delayed.restart() }
            }
            NocturneButton {
                Layout.fillWidth: true; text: "SHARE WI-FI QR"; enabled: root.tools.qrAvailable
                onClicked: { root.qrPath = backend.run([backend.home + "/.config/hypr/scripts/connectivity-tools", "qr"], 4000).trim(); qrDialog.open() }
            }
        }

        Rectangle {
            visible: root.tab === "wifi" && root.wifiEnabled
            Layout.fillWidth: true
            implicitHeight: 44
            color: backend.surfaceColor
            border.color: root.connectivity === "portal" || root.connectivity === "limited" ? "#c7895c" : backend.lineColor
            RowLayout {
                anchors.fill: parent; anchors.margins: 7
                Text {
                    Layout.fillWidth: true
                    text: "NETWORK  " + root.connectivity.toUpperCase()
                    color: backend.textColor; font.family: "monospace"; font.bold: true; font.pixelSize: 9
                }
                Text { text: "METERED"; color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 8 }
                NocturneToggle {
                    checked: root.metered
                    available: root.activeWifiProfile !== ""
                    onToggleRequested: function(enabled) { root.setMetered(enabled) }
                }
                NocturneButton {
                    text: root.connectivity === "portal" ? "SIGN IN" : "CHECK"
                    onClicked: {
                        backend.run(["nmcli", "networking", "connectivity", "check"], 12000)
                        if (root.connectivity === "portal") backend.start(["xdg-open", "http://neverssl.com"])
                        delayed.restart()
                    }
                }
            }
        }

        SectionLabel { text: root.tab === "wifi" ? "NETWORKS" : (root.tab === "bluetooth" ? "DEVICES" : "VPN PROFILES") }

        Text {
            visible: !root.currentEnabled || (root.tab === "vpn" && root.vpn.length === 0)
            Layout.fillWidth: true
            text: root.tab === "vpn" && root.vpn.length === 0 ? "No VPN profiles configured." : root.currentName + " is off."
            color: backend.mutedColor
            font.family: "Inter"
            font.pixelSize: 10
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 5
            Repeater {
                model: root.tab === "wifi" ? root.wifi : (root.tab === "bluetooth" ? root.bluetooth : root.vpn)
                delegate: Rectangle {
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: 48
                    color: backend.surfaceColor
                    border.color: modelData.active ? backend.accentColor : backend.lineColor
                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 7
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1
                            Text { Layout.fillWidth: true; text: root.tab === "wifi" ? modelData.ssid : modelData.name; color: backend.textColor; font.family: "monospace"; font.bold: true; elide: Text.ElideRight }
                            Text {
                                text: modelData.active ? (root.tab === "bluetooth" ? "CONNECTED" + (modelData.codec ? " · " + modelData.codec.toUpperCase() : "") + (modelData.battery ? " · " + modelData.battery + "%" : "") : "CONNECTED") : (root.tab === "wifi" ? modelData.signal + "% · " + modelData.security : (root.tab === "bluetooth" ? modelData.mac : modelData.type.toUpperCase()))
                                color: backend.mutedColor
                                font.family: "Inter"
                                font.pixelSize: 9
                            }
                        }
                        NocturneButton { text: modelData.active ? "DISCONNECT" : "CONNECT"; selected: modelData.active; onClicked: root.toggleConnection(modelData) }
                    }
                }
            }
        }

        NocturneButton {
            visible: root.tab === "bluetooth" && root.bluetoothEnabled
            Layout.fillWidth: true
            text: "SCAN FOR DEVICES"
            onClicked: { backend.start(["bluetoothctl", "--timeout", "5", "scan", "on"]); delayed.restart() }
        }
    }

    Timer { interval: 3000; running: true; repeat: true; triggeredOnStart: true; onTriggered: root.refresh() }
    Timer { id: delayed; interval: 1200; onTriggered: root.refresh() }
    Popup {
        id: qrDialog; parent: root; x: Math.round((root.width - width) / 2); y: Math.round((root.height - height) / 2); modal: true; width: 260; height: 300
        background: Rectangle { color: backend.surfaceColor; border.color: backend.accent2Color }
        contentItem: ColumnLayout { spacing: 8
            Text { Layout.fillWidth: true; text: "SHARE CURRENT WI-FI"; color: backend.textColor; font.family: "monospace"; font.pixelSize: 10; font.bold: true; horizontalAlignment: Text.AlignHCenter }
            Image { Layout.alignment: Qt.AlignHCenter; Layout.preferredWidth: 220; Layout.preferredHeight: 220; source: root.qrPath ? "file://" + root.qrPath : ""; fillMode: Image.PreserveAspectFit; cache: false }
            Text { Layout.fillWidth: true; text: "PASSWORD IS ENCODED LOCALLY"; color: backend.mutedColor; font.family: "monospace"; font.pixelSize: 7; horizontalAlignment: Text.AlignHCenter }
        }
    }
}
