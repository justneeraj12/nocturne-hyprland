import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"

Rectangle {
    id: root
    color: backend.baseColor
    property bool active: false
    property var hardware: ({current:"unconfigured",recommended:"desktop",battery:false,bluetooth:false,displays:0})
    property var backup: ({latest:"",exists:false})
    property var recovery: ({exists:false,size:0,modified:"",failures:0})
    property bool confirmPortableRestore: false
    property bool confirmRecoveryRestore: false
    readonly property string profileHelper: backend.home + "/.config/hypr/scripts/setup-profile"
    readonly property string portable: backend.home + "/.local/bin/nocturne-portable"
    readonly property string recoveryTool: backend.home + "/.local/bin/nocturne-recovery"

    function refresh() {
        hardware = backend.json([profileHelper, "status"], 2500) || hardware
        backup = backend.json([portable, "status"], 2500) || backup
        recovery = backend.json([recoveryTool, "status"], 2500) || recovery
    }
    function applyProfile(name) {
        backend.start([profileHelper, "apply", name])
        refreshDelay.restart()
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
                eyebrow: "SAFETY + PORTABILITY"
                title: "Setup & recovery"
                description: "Tune optional services for this hardware, export a portable configuration and recover from a broken desktop without touching personal files."
                badge: root.recovery.exists ? "CHECKPOINT READY" : "CHECKPOINT NEEDED"
            }

            SettingsCard {
                Layout.fillWidth: true
                title: "DETECTED HARDWARE"
                description: "The recommended profile changes optional helpers only; your shortcuts and workflow stay the same."
                icon: "computer-laptop"
                glyph: "▣"
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    Repeater {
                        model: [
                            {label:"DISPLAYS", value:String(root.hardware.displays)},
                            {label:"FORM FACTOR", value:root.hardware.battery ? "LAPTOP" : "DESKTOP"},
                            {label:"BLUETOOTH", value:root.hardware.bluetooth ? "AVAILABLE" : "NOT FOUND"},
                            {label:"RECOMMENDED", value:String(root.hardware.recommended).toUpperCase()}
                        ]
                        Rectangle {
                            required property var modelData
                            Layout.fillWidth: true
                            implicitHeight: 48
                            color: backend.baseColor
                            border.color: backend.lineColor
                            Column { anchors.fill: parent; anchors.margins: 8; spacing: 3
                                Text { text: modelData.label; color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 8; font.bold: true }
                                Text { width: parent.width; text: modelData.value; color: backend.textColor; font.family: "monospace"; font.pixelSize: 9; font.bold: true; elide: Text.ElideRight }
                            }
                        }
                    }
                    NocturneButton { text: "RECHECK"; onClicked: root.refresh() }
                }
            }

            SettingsCard {
                Layout.fillWidth: true
                title: "USAGE PROFILE"
                description: "Choose how much optional automation Nocturne should keep active."
                icon: "speedometer"
                glyph: "≡"
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    Repeater {
                        model: [
                            {key:"minimal",label:"MINIMAL",detail:"Core shell only",glyph:"—"},
                            {key:"desktop",label:"DESKTOP",detail:"Visuals and EQ",glyph:"▣"},
                            {key:"laptop",label:"LAPTOP",detail:"All hardware helpers",glyph:"⌁"}
                        ]
                        Button {
                            required property var modelData
                            Layout.fillWidth: true
                            implicitHeight: 68
                            hoverEnabled: true
                            onClicked: root.applyProfile(modelData.key)
                            contentItem: RowLayout {
                                spacing: 8
                                Rectangle {
                                    Layout.preferredWidth: 26; Layout.preferredHeight: 26
                                    color: backend.baseColor; border.color: backend.lineColor
                                    Text { anchors.centerIn: parent; text: modelData.glyph; color: backend.accentColor; font.family: "MesloLGS Nerd Font Mono"; font.pixelSize: 12; font.bold: true }
                                }
                                ColumnLayout { Layout.fillWidth: true; spacing: 2
                                    Text { text: modelData.label; color: backend.textColor; font.family: "Inter"; font.pixelSize: 10; font.bold: true }
                                    Text { text: modelData.detail; color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 8 }
                                }
                                Text { visible: root.hardware.current === modelData.key; text: "ACTIVE"; color: backend.accentColor; font.family: "monospace"; font.pixelSize: 8; font.bold: true }
                            }
                            background: Rectangle {
                                color: root.hardware.current === modelData.key ? backend.overlayColor : backend.baseColor
                                border.color: root.hardware.current === modelData.key || parent.hovered ? backend.accent2Color : backend.lineColor
                            }
                        }
                    }
                }
            }

            GridLayout {
                Layout.fillWidth: true
                columns: width >= 650 ? 2 : 1
                columnSpacing: 10
                rowSpacing: 10

                SettingsCard {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    title: "PORTABLE CONFIGURATION"
                    description: "Preferences and monitor layout—never passwords, Wi-Fi credentials, browser data or wallpapers."
                    icon: "document-save"
                    glyph: "⇩"
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 50
                        color: backend.baseColor
                        border.color: backend.lineColor
                        Column { anchors.fill: parent; anchors.margins: 8; spacing: 3
                            Text { text: root.backup.exists ? "LATEST BACKUP READY" : "NO BACKUP YET"; color: root.backup.exists ? backend.accentColor : backend.mutedColor; font.family: "monospace"; font.pixelSize: 9; font.bold: true }
                            Text { width: parent.width; text: root.backup.exists ? root.backup.latest : "~/Documents/Nocturne-Backups"; color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 8; elide: Text.ElideMiddle }
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        NocturneButton { Layout.fillWidth: true; text: "EXPORT"; selected: true; onClicked: { backend.run([root.portable, "export"], 15000); root.refresh() } }
                        NocturneButton {
                            Layout.fillWidth: true
                            text: root.confirmPortableRestore ? "CONFIRM RESTORE" : "RESTORE"
                            danger: root.confirmPortableRestore
                            enabled: root.backup.exists
                            onClicked: {
                                if (!root.confirmPortableRestore) { root.confirmPortableRestore = true; portableConfirmTimeout.restart() }
                                else { backend.run([root.portable, "restore-latest"], 15000); root.confirmPortableRestore = false; root.refresh() }
                            }
                        }
                        NocturneButton { text: "FOLDER"; onClicked: backend.start([backend.home + "/.local/bin/nocturne-files", backend.home + "/Documents/Nocturne-Backups"]) }
                    }
                }

                SettingsCard {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    title: "LAST-KNOWN-GOOD"
                    description: "A local rollback point for shell configuration. Personal files are outside the checkpoint."
                    icon: "edit-undo"
                    glyph: "↶"
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 50
                        color: backend.baseColor
                        border.color: backend.lineColor
                        Column { anchors.fill: parent; anchors.margins: 8; spacing: 3
                            Text { text: root.recovery.exists ? "CHECKPOINT READY · " + Math.round(root.recovery.size / 1024 / 1024) + " MiB" : "NO CHECKPOINT"; color: root.recovery.exists ? backend.accentColor : backend.mutedColor; font.family: "monospace"; font.pixelSize: 9; font.bold: true }
                            Text { width: parent.width; text: root.recovery.modified || "Create one after a known-good session"; color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 8; elide: Text.ElideRight }
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        NocturneButton { Layout.fillWidth: true; text: "NEW CHECKPOINT"; selected: true; onClicked: { backend.run([root.recoveryTool, "checkpoint"], 20000); root.refresh() } }
                        NocturneButton {
                            Layout.fillWidth: true
                            text: root.confirmRecoveryRestore ? "CONFIRM ROLLBACK" : "ROLL BACK"
                            danger: true
                            enabled: root.recovery.exists
                            onClicked: {
                                if (!root.confirmRecoveryRestore) { root.confirmRecoveryRestore = true; recoveryConfirmTimeout.restart() }
                                else { backend.run([root.recoveryTool, "restore"], 20000); root.confirmRecoveryRestore = false; root.refresh() }
                            }
                        }
                    }
                }
            }
            Item { Layout.preferredHeight: 16 }
        }
    }
    Timer { id: refreshDelay; interval: 900; onTriggered: root.refresh() }
    Timer { id: portableConfirmTimeout; interval: 6000; onTriggered: root.confirmPortableRestore = false }
    Timer { id: recoveryConfirmTimeout; interval: 6000; onTriggered: root.confirmRecoveryRestore = false }
    onActiveChanged: if (active) Qt.callLater(refresh)
    Component.onCompleted: if (active) Qt.callLater(refresh)
}
