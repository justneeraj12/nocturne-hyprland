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
        anchors.fill: parent
        contentWidth: availableWidth
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        ColumnLayout {
            x: 26
            width: parent.width - 52
            spacing: 14
            Item { Layout.preferredHeight: 10 }
            SettingsPageHeader {
                Layout.fillWidth: true
                eyebrow: "MACHINE + SERVICES"
                title: "System & accounts"
                description: "Hardware, connected accounts and compatibility services—named honestly so you always know what is running and why."
                badge: root.state.system.os || "LOADING"
            }

            SettingsCard {
                Layout.fillWidth: true
                title: "THIS MACHINE"
                description: root.state.system.kernel
                icon: "computer"
                glyph: "▣"
                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    columnSpacing: 9
                    rowSpacing: 9
                    Repeater {
                        model: [
                            {label:"PROCESSOR",value:root.state.system.cpu,glyph:"CPU"},
                            {label:"GRAPHICS",value:root.state.system.gpu,glyph:"GPU"},
                            {label:"MEMORY",value:root.state.system.memory + " installed",glyph:"RAM"},
                            {label:"SYSTEM STORAGE",value:root.state.system.disk,glyph:"SSD"}
                        ]
                        Rectangle {
                            required property var modelData
                            Layout.fillWidth: true
                            implicitHeight: 58
                            color: backend.baseColor
                            border.color: backend.lineColor
                            RowLayout {
                                anchors.fill: parent; anchors.margins: 9; spacing: 9
                                Rectangle {
                                    Layout.preferredWidth: 30; Layout.preferredHeight: 24
                                    color: backend.baseColor; border.color: backend.lineColor
                                    Text { anchors.centerIn: parent; text: modelData.glyph; color: backend.accentColor; font.family: "monospace"; font.pixelSize: 7; font.bold: true }
                                }
                                ColumnLayout { Layout.fillWidth: true; spacing: 2
                                    Text { text: modelData.label; color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 8; font.bold: true }
                                    Text { Layout.fillWidth: true; text: modelData.value || "Checking…"; color: backend.textColor; font.family: "monospace"; font.pixelSize: 8; elide: Text.ElideRight }
                                }
                            }
                        }
                    }
                }
                RowLayout {
                    Layout.fillWidth: true
                    NocturneButton { Layout.fillWidth: true; text: "RESOURCE DASHBOARD"; selected: true; onClicked: backend.start([backend.home + "/.local/bin/nocturne-dashboard"]) }
                    NocturneButton { Layout.fillWidth: true; text: "SYSTEM MAINTENANCE"; onClicked: backend.start([backend.home + "/.local/bin/nocturne-native", "maintenance"]) }
                    NocturneButton { Layout.fillWidth: true; text: "RUN HEALTH CHECK"; onClicked: backend.start(["kitty", "--class", "nocturne-doctor", "-e", backend.home + "/.local/bin/nocturne-doctor"]) }
                }
            }

            SettingsCard {
                Layout.fillWidth: true
                title: "CONNECTED GOOGLE ACCOUNTS"
                description: "Existing GNOME Online Accounts credentials remain available through the headless GOA/GVFS backend; no GNOME shell UI is running."
                icon: "user-identity"
                glyph: "@"
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 7
                    Repeater {
                        model: root.state.accounts
                        Rectangle {
                            required property var modelData
                            Layout.fillWidth: true
                            implicitHeight: 54
                            color: backend.baseColor
                            border.color: backend.lineColor
                            RowLayout {
                                anchors.fill: parent; anchors.margins: 8; spacing: 9
                                Rectangle {
                                    implicitWidth: 30; implicitHeight: 30; color: backend.overlayColor; border.color: backend.lineColor
                                    Text { anchors.centerIn: parent; text: "G"; color: backend.accentColor; font.family: "monospace"; font.pixelSize: 13; font.bold: true }
                                }
                                ColumnLayout { Layout.fillWidth: true; spacing: 2
                                    Text { Layout.fillWidth: true; text: modelData.identity; color: backend.textColor; font.family: "Inter"; font.pixelSize: 9; font.bold: true; elide: Text.ElideRight }
                                    Text { text: (modelData.files ? "FILES  " : "") + (modelData.mail ? "MAIL" : ""); color: backend.mutedColor; font.family: "monospace"; font.pixelSize: 8 }
                                }
                                NocturneButton { text: "SECURITY"; onClicked: backend.start(["xdg-open", "https://myaccount.google.com/security"]) }
                            }
                        }
                    }
                    Rectangle {
                        visible: root.state.accounts.length === 0
                        Layout.fillWidth: true; implicitHeight: 54
                        color: backend.baseColor; border.color: backend.lineColor
                        Text { anchors.centerIn: parent; text: "NO PRESERVED ONLINE ACCOUNTS FOUND"; color: backend.mutedColor; font.family: "monospace"; font.pixelSize: 9 }
                    }
                }
                RowLayout {
                    Layout.fillWidth: true
                    NocturneButton { Layout.fillWidth: true; text: "GOOGLE DRIVE"; selected: true; onClicked: backend.start([backend.home + "/.local/bin/nocturne-web-app", "drive"]) }
                    NocturneButton { Layout.fillWidth: true; text: "GOOGLE KEEP"; onClicked: backend.start([backend.home + "/.local/bin/nocturne-web-app", "keep"]) }
                    NocturneButton { Layout.fillWidth: true; text: "PHONE / KDE CONNECT"; onClicked: backend.start([backend.home + "/.local/bin/nocturne-native", "kdeconnect"]) }
                }
            }

            SettingsCard {
                Layout.fillWidth: true
                title: "DESKTOP SERVICES"
                description: "Only the backends required for native Hyprland features and application compatibility."
                icon: "preferences-system-services"
                glyph: "◎"
                GridLayout {
                    Layout.fillWidth: true
                    columns: width >= 650 ? 2 : 1
                    columnSpacing: 9
                    rowSpacing: 9
                    Repeater {
                        model: [
                            {name:"Hyprland portal",owner:"NATIVE",active:root.state.integrations.hyprlandPortal,detail:"Screen sharing and global shortcuts."},
                            {name:"KDE file picker",owner:"COMPAT",active:root.state.integrations.kdeFilePicker,detail:"File dialogs for sandboxed applications."},
                            {name:"Secret Service",owner:"COMPAT",active:root.state.integrations.keyring,detail:"Application credentials and Signal keys."},
                            {name:"GVFS + GOA",owner:"COMPAT",active:root.state.integrations.goa,detail:"Google account mounts and files."},
                            {name:"KDE Connect",owner:"FEATURE",active:root.state.integrations.kdeConnect,detail:"Phone, clipboard and file transfer."}
                        ]
                        Rectangle {
                            required property var modelData
                            Layout.fillWidth: true
                            implicitHeight: 60
                            color: backend.baseColor
                            border.color: backend.lineColor
                            RowLayout {
                                anchors.fill: parent; anchors.margins: 9; spacing: 8
                                Rectangle { implicitWidth: 7; implicitHeight: 7; radius: 4; color: modelData.active ? backend.accentColor : "#b95f68" }
                                ColumnLayout { Layout.fillWidth: true; spacing: 2
                                    Text { text: modelData.name; color: backend.textColor; font.family: "Inter"; font.pixelSize: 9; font.bold: true }
                                    Text { Layout.fillWidth: true; text: modelData.detail; color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 8; elide: Text.ElideRight }
                                }
                                Text { text: modelData.owner; color: modelData.owner === "NATIVE" ? backend.accentColor : backend.mutedColor; font.family: "monospace"; font.pixelSize: 8; font.bold: true }
                            }
                        }
                    }
                }
            }

            SettingsCard {
                Layout.fillWidth: true
                title: "ADVANCED HARDWARE"
                description: "Specialized tools stay available without cluttering the daily controls."
                icon: "configure"
                glyph: "⚙"
                GridLayout {
                    Layout.fillWidth: true
                    columns: 4
                    columnSpacing: 7
                    rowSpacing: 7
                    NocturneButton { Layout.fillWidth: true; text: "NVIDIA CONTROL"; onClicked: backend.start(["nvidia-settings"]) }
                    NocturneButton { Layout.fillWidth: true; text: "PIPEWIRE GRAPH"; onClicked: backend.start(["qpwgraph"]) }
                    NocturneButton { Layout.fillWidth: true; text: "FIRMWARE"; onClicked: backend.start([backend.home + "/.local/bin/nocturne-native", "maintenance"]) }
                    NocturneButton { Layout.fillWidth: true; text: "PRINTERS"; onClicked: backend.start(["xdg-open", "http://localhost:631/"]) }
                }
            }
            Item { Layout.preferredHeight: 16 }
        }
    }
    onActiveChanged: if (active) Qt.callLater(refresh)
    Component.onCompleted: if (active) Qt.callLater(refresh)
}
