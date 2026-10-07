import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"

Rectangle {
    id: root
    color: backend.baseColor
    property bool active: false
    property var state: ({complete:0,total:7,steps:{},hardware:{battery:false,camera:false,fingerprint:false,touchpad:false,bluetooth:false,monitors:0,gpu:""}})
    signal sectionRequested(string key)
    readonly property string tool: backend.home + "/.config/hypr/scripts/onboarding-control"

    function refresh() {
        if (!active) return
        var next = backend.json([tool, "status"], 5000)
        if (next && next.format === "nocturne-onboarding-v1") state = next
    }

    ScrollView {
        anchors.fill: parent; contentWidth: availableWidth; ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        ColumnLayout {
            x: 26; width: parent.width - 52; spacing: 14
            Item { Layout.preferredHeight: 10 }
            SettingsPageHeader {
                Layout.fillWidth: true; eyebrow: "FIRST RUN + HARDWARE"; title: "Welcome to NOC"
                description: "A bounded setup path for people arriving from GNOME, KDE or a plain Hyprland configuration. Every step is optional and reversible."
                badge: root.state.complete + "/" + root.state.total + " READY"
            }
            SettingsCard {
                Layout.fillWidth: true; title: "HARDWARE REPORT"; description: "Capability detection only. No serial numbers, account names or file contents are collected."; icon: "computer-laptop"; glyph: "▣"
                GridLayout {
                    Layout.fillWidth: true; columns: 4; columnSpacing: 8; rowSpacing: 8
                    Repeater {
                        model: [
                            {label:"FORM FACTOR",value:root.state.hardware.battery ? "LAPTOP" : "DESKTOP"},
                            {label:"DISPLAYS",value:String(root.state.hardware.monitors)},
                            {label:"INPUT",value:root.state.hardware.touchpad ? "TOUCHPAD" : "POINTER"},
                            {label:"DEVICES",value:(root.state.hardware.bluetooth ? "BT " : "") + (root.state.hardware.camera ? "CAMERA " : "") + (root.state.hardware.fingerprint ? "FINGERPRINT" : "")}
                        ]
                        Rectangle { required property var modelData; Layout.fillWidth: true; implicitHeight: 50; color: backend.baseColor; border.color: backend.lineColor
                            Column { anchors.fill: parent; anchors.margins: 8; spacing: 3
                                Text { text: modelData.label; color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 8; font.bold: true }
                                Text { width: parent.width; text: modelData.value || "STANDARD"; color: backend.textColor; font.family: "monospace"; font.pixelSize: 9; font.bold: true; elide: Text.ElideRight }
                            }
                        }
                    }
                }
                Text { Layout.fillWidth: true; text: root.state.hardware.gpu; color: backend.mutedColor; font.family: "monospace"; font.pixelSize: 8; elide: Text.ElideRight }
            }
            SettingsCard {
                Layout.fillWidth: true; title: "SETUP CHECKLIST"; description: "Complete only what matters to this device. The shell remains usable at every stage."; icon: "view-task"; glyph: "✓"
                Repeater {
                    model: [
                        {key:"shell",label:"Native shell health",detail:"Bar and core session ownership",section:"overview"},
                        {key:"recovery",label:"Recovery checkpoint",detail:"Known-good rollback before experiments",section:"setup"},
                        {key:"profile",label:"Hardware profile",detail:"Minimal, desktop or laptop services",section:"setup"},
                        {key:"display",label:"Display layout",detail:"Scale, positions and dock profile",section:"displaylab"},
                        {key:"shortcuts",label:"Shortcut orientation",detail:"Keyboard and mouse reference",section:"workflow"},
                        {key:"agenda",label:"Connected agenda",detail:"Optional read-only calendar sources",section:"agenda"},
                        {key:"security",label:"Security baseline",detail:"Containment or malware engine available",section:"security"}
                    ]
                    Rectangle {
                        required property var modelData; Layout.fillWidth: true; implicitHeight: 51; color: backend.baseColor; border.color: root.state.steps[modelData.key] ? backend.lineColor : "#6b5634"
                        RowLayout { anchors.fill: parent; anchors.margins: 8; spacing: 9
                            Text { text: root.state.steps[modelData.key] ? "●" : "○"; color: root.state.steps[modelData.key] ? backend.accentColor : "#d9a85f"; font.pixelSize: 12 }
                            ColumnLayout { Layout.fillWidth: true; spacing: 1
                                Text { text: modelData.label; color: backend.textColor; font.family: "Inter"; font.pixelSize: 9; font.bold: true }
                                Text { text: modelData.detail; color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 8 }
                            }
                            NocturneButton { text: root.state.steps[modelData.key] ? "REVIEW" : "SET UP"; onClicked: root.sectionRequested(modelData.section) }
                            NocturneButton { visible: modelData.key === "shortcuts" && !root.state.steps.shortcuts; text: "MARK READ"; selected: true; onClicked: { backend.run([root.tool, "acknowledge-shortcuts"], 3000); root.refresh() } }
                        }
                    }
                }
            }
            Text { Layout.fillWidth: true; text: "NOC never replaces an existing desktop configuration without a snapshot. Hardware-dependent controls stay hidden or disabled when the kernel does not expose them."; color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 8; wrapMode: Text.WordWrap }
            Item { Layout.preferredHeight: 16 }
        }
    }
    onActiveChanged: if (active) Qt.callLater(refresh)
    Component.onCompleted: if (active) Qt.callLater(refresh)
}
