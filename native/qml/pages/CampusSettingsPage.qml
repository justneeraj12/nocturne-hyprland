import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"

Rectangle {
    id: root
    color: backend.baseColor
    property bool active: false
    property bool discovering: false
    property var state: ({
        privacy:"NO CREDENTIALS STORED",
        print:{ready:false,cups:"unknown",avahi:"unknown",ippUsb:"unknown",queues:[],defaultQueue:"",driverless:"IPP EVERYWHERE"},
        scan:{ready:false,application:"none",airscan:false,protocols:[]},
        network:{ready:false,enterpriseWifi:false,vpnProfiles:false,certificatePolicy:"USE UNIVERSITY PROFILE"},
        identity:{smartcard:false,fido:false}, guidance:[]
    })
    property var discovery: ({printers:[],scanners:[]})
    readonly property string helper: backend.home + "/.config/hypr/scripts/campus-control"

    function refresh() {
        if (!active) return
        var value = backend.json([helper, "status"], 7000)
        if (value) state = value
    }
    function discover() {
        discovering = true
        var value = backend.json([helper, "discover"], 14000)
        if (value) discovery = value
        discovering = false
    }
    function repair() { backend.start(["kitty", "--title", "NOC Campus Repair", "-e", helper, "repair"]) }

    ScrollView {
        anchors.fill: parent
        contentWidth: availableWidth
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        ColumnLayout {
            x: 26; width: parent.width - 52; spacing: 14
            Item { Layout.preferredHeight: 10 }
            SettingsPageHeader {
                Layout.fillWidth: true
                eyebrow: "UNIVERSITY + SHARED DEVICES"
                title: "Campus compatibility"
                description: "Driverless printers, network scanners, enterprise Wi-Fi and portable identity—using standard Linux services instead of vendor daemons."
                badge: root.state.privacy
            }

            GridLayout {
                Layout.fillWidth: true; columns: 4; columnSpacing: 9; rowSpacing: 9
                Repeater {
                    model: [
                        {label:"PRINT",value:root.state.print.ready ? "READY" : "SETUP",detail:(root.state.print.queues || []).length + " configured queue(s)",good:root.state.print.ready},
                        {label:"SCAN",value:root.state.scan.ready ? "READY" : "SETUP",detail:root.state.scan.application,good:root.state.scan.ready},
                        {label:"ENTERPRISE WI-FI",value:root.state.network.enterpriseWifi ? "READY" : "SETUP",detail:"802.1X via NetworkManager",good:root.state.network.enterpriseWifi},
                        {label:"PORTABLE ID",value:root.state.identity.fido ? "FIDO2" : "OPTIONAL",detail:root.state.identity.smartcard ? "smart card + security key" : "security key available",good:root.state.identity.fido}
                    ]
                    Rectangle {
                        required property var modelData
                        Layout.fillWidth: true; implicitHeight: 72
                        color: backend.surfaceColor; border.color: modelData.good ? backend.lineColor : "#8d4b54"
                        Column { anchors.fill: parent; anchors.margins: 10; spacing: 3
                            Text { text: modelData.label; color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 8; font.bold: true; font.letterSpacing: 0.7 }
                            Text { text: modelData.value; color: modelData.good ? backend.accentColor : "#ff8c96"; font.family: "monospace"; font.pixelSize: 14; font.bold: true }
                            Text { text: modelData.detail; color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 8; elide: Text.ElideRight; width: parent.width }
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true; spacing: 9
                SettingsCard {
                    Layout.fillWidth: true
                    title: "PRINTERS"
                    description: "IPP Everywhere, AirPrint and USB IPP first. CUPS remains the universal queue backend."
                    glyph: "PRN"
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 6
                        Text { Layout.fillWidth: true; text: "CUPS  " + String(root.state.print.cups).toUpperCase() + "    DISCOVERY  " + String(root.state.print.avahi).toUpperCase(); color: backend.mutedColor; font.family: "monospace"; font.pixelSize: 8; elide: Text.ElideRight }
                        Text { Layout.fillWidth: true; text: (root.discovery.printers || []).length ? root.discovery.printers.join("\n") : "No discovered device yet. Discovery runs only when requested."; color: backend.textColor; font.family: "monospace"; font.pixelSize: 8; wrapMode: Text.WordWrap; maximumLineCount: 4; elide: Text.ElideRight }
                    }
                }
                SettingsCard {
                    Layout.fillWidth: true
                    title: "SCANNERS"
                    description: "AirScan/eSCL, WSD and USB SANE. Skanpage is preferred; Document Scanner is the fallback."
                    glyph: "SCN"
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 6
                        Text { Layout.fillWidth: true; text: "APP  " + String(root.state.scan.application).toUpperCase() + "    AIRSCAN  " + (root.state.scan.airscan ? "READY" : "OPTIONAL"); color: backend.mutedColor; font.family: "monospace"; font.pixelSize: 8; elide: Text.ElideRight }
                        Text { Layout.fillWidth: true; text: (root.discovery.scanners || []).length ? root.discovery.scanners.join("\n") : "No discovered device yet. Device names are not stored."; color: backend.textColor; font.family: "monospace"; font.pixelSize: 8; wrapMode: Text.WordWrap; maximumLineCount: 4; elide: Text.ElideRight }
                    }
                }
            }

            SettingsCard {
                Layout.fillWidth: true
                title: "CAMPUS-SAFE DEFAULTS"
                description: "Compatibility without weakening university security policy."
                glyph: "802.1X"
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 0
                    Repeater {
                        model: root.state.guidance || []
                        Rectangle {
                            required property var modelData; required property int index
                            Layout.fillWidth: true; implicitHeight: 43; color: index % 2 ? backend.baseColor : "transparent"
                            RowLayout { anchors.fill: parent; anchors.leftMargin: 9; anchors.rightMargin: 9; spacing: 12
                                Text { Layout.preferredWidth: 115; text: modelData.label.toUpperCase(); color: backend.accent2Color; font.family: "monospace"; font.pixelSize: 8; font.bold: true }
                                Text { Layout.fillWidth: true; text: modelData.detail; color: backend.textColor; font.family: "Inter"; font.pixelSize: 8; elide: Text.ElideRight }
                            }
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true; spacing: 9
                NocturneButton { Layout.fillWidth: true; text: root.discovering ? "DISCOVERING…" : "DISCOVER DEVICES"; selected: true; enabled: !root.discovering; onClicked: root.discover() }
                NocturneButton { Layout.fillWidth: true; text: "SCAN DOCUMENT"; enabled: root.state.scan.application !== "none"; onClicked: backend.start([helper, "open-scanner"]) }
                NocturneButton { Layout.fillWidth: true; text: "PRINT MANAGER"; onClicked: backend.start([helper, "open-printers"]) }
                NocturneButton { Layout.fillWidth: true; text: "REPAIR SERVICES"; onClicked: root.repair() }
            }
            Text { Layout.fillWidth: true; text: "For eduroam, always import the university-issued profile or geteduroam installer. NOC never asks for campus passwords and never disables server-certificate validation."; color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 8; wrapMode: Text.WordWrap }
            Item { Layout.preferredHeight: 16 }
        }
    }

    onActiveChanged: if (active) Qt.callLater(refresh)
    Component.onCompleted: if (active) Qt.callLater(refresh)
}
