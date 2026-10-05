import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"

Rectangle {
    id: root
    color: backend.baseColor
    property bool active: false
    property var state: ({accounts:[],system:{os:"",kernel:"",cpu:"",memory:"",disk:"",gpu:""},integrations:{}})
    readonly property string helper: backend.home + "/.config/hypr/scripts/system-preferences"
    function refresh() { state = backend.json([helper, "status"], 8000) || state }

    ScrollView {
        anchors.fill: parent; contentWidth: availableWidth
        ColumnLayout {
            x: 22; width: parent.width - 44; spacing: 9
            Text { text: "SYSTEM + INTEGRATIONS"; color: backend.textColor; font.family: "monospace"; font.pixelSize: 25; font.bold: true }
            Text { Layout.fillWidth: true; text: "One control surface, with every compatibility backend named and justified instead of pretending it is part of the shell."; color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 11; wrapMode: Text.WordWrap }
            SectionLabel { text: "THIS MACHINE" }
            Rectangle {
                Layout.fillWidth: true; implicitHeight: 112; color: backend.surfaceColor; border.color: backend.lineColor
                GridLayout { anchors.fill: parent; anchors.margins: 10; columns: 2; columnSpacing: 14; rowSpacing: 4
                    Text { text: "OS"; color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 8 }
                    Text { Layout.fillWidth: true; text: root.state.system.os + " · " + root.state.system.kernel; color: backend.textColor; font.family: "monospace"; font.pixelSize: 9; elide: Text.ElideRight }
                    Text { text: "CPU"; color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 8 }
                    Text { Layout.fillWidth: true; text: root.state.system.cpu; color: backend.textColor; font.family: "monospace"; font.pixelSize: 9; elide: Text.ElideRight }
                    Text { text: "GPU"; color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 8 }
                    Text { Layout.fillWidth: true; text: root.state.system.gpu; color: backend.textColor; font.family: "monospace"; font.pixelSize: 9; elide: Text.ElideRight }
                    Text { text: "MEMORY / DISK"; color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 8 }
                    Text { text: root.state.system.memory + " RAM · " + root.state.system.disk; color: backend.textColor; font.family: "monospace"; font.pixelSize: 9 }
                }
            }
            SectionLabel { text: "GOOGLE ACCOUNTS · PRESERVED THROUGH THE GOA FILES BACKEND" }
            Repeater {
                model: root.state.accounts
                Rectangle {
                    required property var modelData; Layout.fillWidth: true; implicitHeight: 43; color: backend.surfaceColor; border.color: backend.lineColor
                    RowLayout { anchors.fill: parent; anchors.margins: 7
                        Text { text: "G"; color: backend.accentColor; font.family: "monospace"; font.bold: true; font.pixelSize: 14 }
                        Text { Layout.fillWidth: true; text: modelData.identity; color: backend.textColor; font.family: "monospace"; font.pixelSize: 9; elide: Text.ElideRight }
                        Text { text: (modelData.files ? "FILES " : "") + (modelData.mail ? "MAIL" : ""); color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 8 }
                        NocturneButton { text: "ACCOUNT"; onClicked: backend.start(["xdg-open", "https://myaccount.google.com/"]) }
                    }
                }
            }
            RowLayout {
                Layout.fillWidth: true; spacing: 5
                NocturneButton { Layout.fillWidth: true; text: "GOOGLE DRIVE"; onClicked: backend.start([backend.home + "/.local/bin/nocturne-web-app", "drive"]) }
                NocturneButton { Layout.fillWidth: true; text: "GOOGLE KEEP"; onClicked: backend.start([backend.home + "/.local/bin/nocturne-web-app", "keep"]) }
                NocturneButton { Layout.fillWidth: true; text: "PHONE / KDE CONNECT"; onClicked: backend.start([backend.home + "/.local/bin/nocturne-native", "kdeconnect"]) }
            }
            SectionLabel { text: "DESKTOP BACKENDS" }
            Repeater {
                model: [
                    {name:"HYPRLAND PORTAL",owner:"HYPRLAND NATIVE",detail:"Screen sharing, screenshots and global shortcuts."},
                    {name:"KDE FILE-CHOOSER PORTAL",owner:"COMPATIBILITY",detail:"Required because the Hyprland portal has no file picker."},
                    {name:"GNOME KEYRING / SECRET SERVICE",owner:"COMPATIBILITY",detail:"Stores Signal and application credentials; no GNOME shell UI."},
                    {name:"GVFS + GOA",owner:"COMPATIBILITY",detail:"Mounts your three existing Google accounts in applications."},
                    {name:"KDE CONNECT DAEMON",owner:"USER FEATURE",detail:"Phone notifications, clipboard and file transfer."}
                ]
                Rectangle {
                    required property var modelData; Layout.fillWidth: true; implicitHeight: 48; color: "transparent"; border.color: backend.lineColor
                    RowLayout { anchors.fill: parent; anchors.margins: 7
                        ColumnLayout { Layout.fillWidth: true; spacing: 1
                            Text { text: modelData.name; color: backend.textColor; font.family: "monospace"; font.bold: true; font.pixelSize: 9 }
                            Text { Layout.fillWidth: true; text: modelData.detail; color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 8; elide: Text.ElideRight }
                        }
                        Text { text: modelData.owner; color: modelData.owner === "HYPRLAND NATIVE" ? backend.accentColor : backend.mutedColor; font.family: "Inter"; font.bold: true; font.pixelSize: 8 }
                    }
                }
            }
            SectionLabel { text: "ADVANCED HARDWARE" }
            RowLayout { Layout.fillWidth: true; spacing: 5
                NocturneButton { Layout.fillWidth: true; text: "NVIDIA CONTROL"; onClicked: backend.start(["nvidia-settings"]) }
                NocturneButton { Layout.fillWidth: true; text: "PIPEWIRE GRAPH"; onClicked: backend.start(["qpwgraph"]) }
                NocturneButton { Layout.fillWidth: true; text: "FIRMWARE + UPDATES"; onClicked: backend.start([backend.home + "/.local/bin/nocturne-native", "maintenance"]) }
                NocturneButton { Layout.fillWidth: true; text: "PRINTERS"; onClicked: backend.start(["xdg-open", "http://localhost:631/"]) }
            }
            Item { Layout.preferredHeight: 12 }
        }
    }
    onActiveChanged: if (active) Qt.callLater(refresh)
    Component.onCompleted: if (active) Qt.callLater(refresh)
}
