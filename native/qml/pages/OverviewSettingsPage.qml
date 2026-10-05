import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"

Rectangle {
    id: root
    color: backend.baseColor
    property bool active: false
    property var state: ({system:{os:"",kernel:"",cpu:"",memory:"",disk:"",gpu:""},devices:{keyboards:0,mice:0,touchpads:0},accounts:[]})
    readonly property string helper: backend.home + "/.config/hypr/scripts/system-preferences"
    signal sectionRequested(string key)

    function refresh() { state = backend.json([helper, "status"], 8000) || state }
    function openSurface(name, page) {
        var args = [backend.home + "/.local/bin/nocturne-native", name]
        if (page) args.push(page)
        backend.start(args)
    }

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
                eyebrow: "CONTROL CENTER"
                title: "Your system, at a glance"
                description: "Daily controls stay one click away. Deeper tools remain available without mixing desktop environments or duplicate services."
                badge: "WAYLAND NATIVE"
            }
            SettingsCard {
                Layout.fillWidth: true
                title: "NOCTURNE IS READY"
                description: root.state.system.os + " · " + root.state.system.kernel
                icon: "emblem-default"
                glyph: "✓"
                highlighted: true
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    Repeater {
                        model: [
                            {label:"CPU", value:root.state.system.cpu},
                            {label:"MEMORY", value:root.state.system.memory},
                            {label:"STORAGE", value:root.state.system.disk}
                        ]
                        Rectangle {
                            required property var modelData
                            Layout.fillWidth: true
                            implicitHeight: 45
                            color: backend.baseColor
                            border.color: backend.lineColor
                            Column {
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 3
                                Text { text: modelData.label; color: backend.accentColor; font.family: "Inter"; font.pixelSize: 8; font.bold: true; font.letterSpacing: 1 }
                                Text { width: parent.width; text: modelData.value || "Checking…"; color: backend.textColor; font.family: "monospace"; font.pixelSize: 8; elide: Text.ElideRight }
                            }
                        }
                    }
                }
            }
            Text { text: "QUICK CONTROLS"; color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 9; font.bold: true; font.letterSpacing: 1.2 }
            GridLayout {
                Layout.fillWidth: true
                columns: width >= 650 ? 3 : 2
                columnSpacing: 9
                rowSpacing: 9
                Repeater {
                    model: [
                        {icon:"preferences-desktop-theme",glyph:"◈",title:"Appearance",detail:"Wallpaper, theme and accent",section:"appearance"},
                        {icon:"network-wireless",glyph:"⌁",title:"Connectivity",detail:"Wi-Fi, Bluetooth and VPN",surface:"connectivity",page:"wifi"},
                        {icon:"audio-volume-high",glyph:"♪",title:"Sound",detail:"Output, mixer and routing",surface:"audio"},
                        {icon:"video-display",glyph:"▣",title:"Displays",detail:"Layout, scale and refresh",surface:"display"},
                        {icon:"battery",glyph:"⚡",title:"Power",detail:"Profiles and game sessions",surface:"power"},
                        {icon:"preferences-system",glyph:"◫",title:"System",detail:"Accounts and integrations",section:"system"}
                    ]
                    SettingsAction {
                        required property var modelData
                        Layout.fillWidth: true
                        iconName: modelData.icon
                        glyph: modelData.glyph || ""
                        title: modelData.title
                        description: modelData.detail
                        actionText: "OPEN"
                        onClicked: {
                            if (modelData.section) root.sectionRequested(modelData.section)
                            else root.openSurface(modelData.surface, modelData.page || "")
                        }
                    }
                }
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 9
                SettingsCard {
                    Layout.fillWidth: true
                    title: "INPUT DEVICES"
                    description: root.state.devices.keyboards + " keyboards · " + root.state.devices.mice + " pointers · " + root.state.devices.touchpads + " touchpads"
                    icon: "input-keyboard"
                    glyph: "⌨"
                    NocturneButton { Layout.fillWidth: true; text: "CONFIGURE INPUT"; onClicked: root.sectionRequested("input") }
                }
                SettingsCard {
                    Layout.fillWidth: true
                    title: "CONNECTED ACCOUNTS"
                    description: root.state.accounts.length + " accounts available to compatible applications"
                    icon: "user-identity"
                    glyph: "@"
                    NocturneButton { Layout.fillWidth: true; text: "VIEW INTEGRATIONS"; onClicked: root.sectionRequested("system") }
                }
            }
            Item { Layout.preferredHeight: 16 }
        }
    }
    onActiveChanged: if (active) Qt.callLater(refresh)
    Component.onCompleted: if (active) Qt.callLater(refresh)
}
