import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"

Rectangle {
    id: root
    color: backend.baseColor
    property bool active: false
    property var meeting: ({active:false, dnd:false, caffeine:false, source:"", sink:"", power:""})
    property var permissions: ({portals:{healthy:false}, flatpaks:[], startup:[], dynamicPermissions:0})
    property var guard: ({healthy:false, issues:[], summary:{}})
    property var pulse: ({desk:{}, habits:{}, guard:{}, meeting:{}})
    property var configDiff: ({count:0, files:[]})
    readonly property string meetingTool: backend.home + "/.config/hypr/scripts/meeting-mode"
    readonly property string permissionTool: backend.home + "/.config/hypr/scripts/permission-control"
    readonly property string guardTool: backend.home + "/.config/hypr/scripts/system-guard"
    readonly property string pulseTool: backend.home + "/.config/hypr/scripts/pulse"

    function refresh() {
        var nextMeeting = backend.json([meetingTool, "status"], 3500)
        var nextPermissions = backend.json([permissionTool, "status"], 10000)
        var nextGuard = backend.json([guardTool, "status"], 5000)
        var nextPulse = backend.json([pulseTool, "status"], 6000)
        if (nextMeeting && nextMeeting.active !== undefined) meeting = nextMeeting
        if (nextPermissions && nextPermissions.portals) permissions = nextPermissions
        if (nextGuard && nextGuard.issues) guard = nextGuard
        if (nextPulse && nextPulse.desk) pulse = nextPulse
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
                eyebrow: "CONTROL + RELIABILITY"
                title: "System Command"
                description: "Meeting orchestration, permissions, startup ownership and explainable one-click repair."
                badge: guard.healthy ? "ALL SYSTEMS NOMINAL" : (guard.issues || []).length + " ISSUES"
            }

            SettingsCard {
                Layout.fillWidth: true
                title: "MEETING MODE"
                description: "Captures the current state, enables DND and caffeine, prefers the laptop mic, then restores everything when the meeting ends."
                icon: "camera-web"
                glyph: "◉"
                highlighted: meeting.active
                RowLayout {
                    Layout.fillWidth: true
                    NocturneButton { text: meeting.active ? "END + RESTORE" : "START MODE"; selected: meeting.active; onClicked: { backend.run([root.meetingTool, "toggle"], 10000); refreshDelay.restart() } }
                    NocturneButton { text: "OPEN GOOGLE MEET"; onClicked: { backend.start([root.meetingTool, "launch", "meet"]); refreshDelay.restart() } }
                    NocturneButton { text: "OPEN DISCORD"; onClicked: { backend.start([root.meetingTool, "launch", "discord"]); refreshDelay.restart() } }
                    Text { Layout.fillWidth: true; text: (meeting.dnd ? "DND · " : "") + (meeting.caffeine ? "CAFFEINE · " : "") + String(meeting.power).toUpperCase(); color: backend.mutedColor; font.family: "monospace"; font.pixelSize: 8; horizontalAlignment: Text.AlignRight }
                }
            }

            GridLayout {
                Layout.fillWidth: true
                columns: width >= 700 ? 2 : 1
                columnSpacing: 10
                rowSpacing: 10
                SettingsCard {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    title: "PERMISSION CENTER"
                    description: "Portal health, dynamic grants and per-Flatpak overrides."
                    icon: "security-high"
                    glyph: "◆"
                    Text { text: permissions.portals.healthy ? "PORTALS HEALTHY" : "PORTAL REPAIR NEEDED"; color: permissions.portals.healthy ? backend.accentColor : "#e17780"; font.family: "monospace"; font.pixelSize: 9; font.bold: true }
                    Text { text: (permissions.flatpaks || []).length + " SANDBOXED APPS · " + permissions.dynamicPermissions + " DYNAMIC GRANTS"; color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 8 }
                    RowLayout {
                        Layout.fillWidth: true
                        NocturneButton { Layout.fillWidth: true; text: "LIVE SENSOR ACCESS"; onClicked: backend.start([backend.home + "/.local/bin/nocturne-native", "privacy"]) }
                        NocturneButton { text: "RESTART PORTALS"; onClicked: { backend.run([root.permissionTool, "portal-restart"], 10000); root.refresh() } }
                    }
                }
                SettingsCard {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    title: "NOC GUARD"
                    description: "Detects broken shell, portal, audio, wallpaper and configuration state."
                    icon: "security-medium"
                    glyph: "✓"
                    highlighted: guard.healthy
                    Text { text: guard.healthy ? "NO ACTION REQUIRED" : (guard.issues || []).length + " REPAIRABLE CONDITIONS"; color: guard.healthy ? backend.accentColor : "#e17780"; font.family: "monospace"; font.pixelSize: 9; font.bold: true }
                    Repeater {
                        model: (guard.issues || []).slice(0, 3)
                        Text { required property var modelData; Layout.fillWidth: true; text: "• " + modelData.title; color: backend.textColor; font.family: "Inter"; font.pixelSize: 8; elide: Text.ElideRight }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        NocturneButton { Layout.fillWidth: true; text: "RECHECK"; onClicked: root.refresh() }
                        NocturneButton { Layout.fillWidth: true; text: "REPAIR SAFE ISSUES"; enabled: !guard.healthy; onClicked: { backend.run([root.guardTool, "fix", "all"], 30000); refreshDelay.restart() } }
                    }
                }
            }

            SettingsCard {
                Layout.fillWidth: true
                title: "APPLICATION OWNERSHIP"
                description: "Control user startup entries and reset sandbox grants without exposing application data."
                icon: "preferences-system-windows-actions"
                glyph: "▦"
                GridLayout {
                    Layout.fillWidth: true
                    columns: width >= 700 ? 2 : 1
                    columnSpacing: 10
                    ColumnLayout {
                        Layout.fillWidth: true
                        SectionLabel { text: "STARTUP APPLICATIONS" }
                        Repeater {
                            model: (permissions.startup || []).slice(0, 8)
                            Rectangle {
                                required property var modelData
                                Layout.fillWidth: true; implicitHeight: 42; color: backend.baseColor; border.color: backend.lineColor
                                RowLayout {
                                    anchors.fill: parent; anchors.margins: 7
                                    Text { Layout.fillWidth: true; text: modelData.name; color: backend.textColor; font.family: "Inter"; font.pixelSize: 8; elide: Text.ElideRight }
                                    NocturneToggle { checked: modelData.enabled; onToggleRequested: function(v) { backend.run([root.permissionTool, "startup", modelData.id, String(v)], 2500); root.refresh() } }
                                }
                            }
                        }
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        SectionLabel { text: "SANDBOX OVERRIDES" }
                        Repeater {
                            model: (permissions.flatpaks || []).slice(0, 8)
                            Rectangle {
                                required property var modelData
                                Layout.fillWidth: true; implicitHeight: 42; color: backend.baseColor; border.color: modelData.custom ? backend.accent2Color : backend.lineColor
                                RowLayout {
                                    anchors.fill: parent; anchors.margins: 7
                                    ColumnLayout {
                                        Layout.fillWidth: true; spacing: 1
                                        Text { Layout.fillWidth: true; text: modelData.name; color: backend.textColor; font.family: "Inter"; font.pixelSize: 8; elide: Text.ElideRight }
                                        Text { text: modelData.custom ? "CUSTOM OVERRIDE" : "DEFAULT SANDBOX"; color: backend.mutedColor; font.family: "monospace"; font.pixelSize: 7 }
                                    }
                                    NocturneButton { text: "RESET"; enabled: modelData.custom; onClicked: { backend.run([root.permissionTool, "reset", modelData.id], 5000); root.refresh() } }
                                }
                            }
                        }
                    }
                }
            }

            SettingsCard {
                Layout.fillWidth: true
                title: "NOC PULSE"
                description: "A private on-demand snapshot across work, habits, focus, meeting and system health."
                icon: "view-calendar-timeline"
                glyph: "⌁"
                GridLayout {
                    Layout.fillWidth: true
                    columns: 5
                    Repeater {
                        model: [{l:"OPEN TASKS",v:pulse.desk.open||0}, {l:"DONE TODAY",v:pulse.desk.completedToday||0}, {l:"HABITS",v:pulse.habits.doneToday||0}, {l:"SYSTEM ISSUES",v:pulse.guard.issues||0}, {l:"MEETING",v:pulse.meeting.active?"ON":"OFF"}]
                        Rectangle {
                            required property var modelData
                            Layout.fillWidth: true; implicitHeight: 48; color: backend.baseColor; border.color: backend.lineColor
                            Column {
                                anchors.centerIn: parent; spacing: 2
                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.v; color: backend.accentColor; font.family: "monospace"; font.pixelSize: 11; font.bold: true }
                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.l; color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 7; font.bold: true }
                            }
                        }
                    }
                }
            }

            SettingsCard {
                Layout.fillWidth: true
                title: "CONFIGURATION DIFF"
                description: "Compare current shell configuration to the last-known-good checkpoint without exposing file contents."
                icon: "vcs-diff"
                glyph: "±"
                RowLayout {
                    Layout.fillWidth: true
                    NocturneButton { text: "COMPARE"; selected: true; onClicked: configDiff = backend.json([root.guardTool, "diff"], 15000) || configDiff }
                    Text { Layout.fillWidth: true; text: (configDiff.count || 0) + " CHANGED PATHS"; color: backend.mutedColor; font.family: "monospace"; font.pixelSize: 8 }
                }
                Repeater {
                    model: (root.configDiff.files || []).slice(0, 6)
                    Text { required property string modelData; Layout.fillWidth: true; text: modelData; color: backend.textColor; font.family: "monospace"; font.pixelSize: 8; elide: Text.ElideMiddle }
                }
            }
            Item { Layout.preferredHeight: 16 }
        }
    }

    Timer { id: refreshDelay; interval: 900; onTriggered: root.refresh() }
    onActiveChanged: if (active) Qt.callLater(refresh)
    Component.onCompleted: if (active) Qt.callLater(refresh)
}
