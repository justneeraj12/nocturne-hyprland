import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"

Rectangle {
    id: root
    color: backend.baseColor
    property bool active: false
    property bool busy: false
    property string pendingRemove: ""
    property var state: ({configured:false, sourceCount:0, enabledSources:0, eventCount:0, refreshed:"", sources:[], upcoming:[], privacy:{residentProcesses:0}})
    readonly property string tool: backend.home + "/.local/bin/nocturne-agenda"

    function refresh() {
        if (!active || busy) return
        var next = backend.json([tool, "status"], 3500)
        if (next && next.format === "nocturne-agenda-v1") state = next
    }
    function addSource() {
        if (!sourceName.text.trim() || !sourceLocation.text.trim()) return
        busy = true
        backend.run([tool, "add", sourceName.text.trim(), sourceLocation.text.trim(), "#5f8f76"], 5000)
        sourceName.clear(); sourceLocation.clear(); busy = false; refresh()
    }
    function removeSource(id) {
        if (pendingRemove !== id) { pendingRemove = id; removeReset.restart(); return }
        backend.run([tool, "remove", id], 4000); pendingRemove = ""; refresh()
    }
    function friendlyTime(value, allDay) {
        if (allDay) return "ALL DAY"
        var parsed = new Date(value)
        return Qt.formatDateTime(parsed, "ddd dd MMM · h:mm AP")
    }

    ScrollView {
        anchors.fill: parent
        contentWidth: availableWidth
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        ColumnLayout {
            x: 26; width: parent.width - 52; spacing: 14
            Item { Layout.preferredHeight: 10 }
            SettingsPageHeader {
                Layout.fillWidth: true
                eyebrow: "CALDAV-LITE + ICS"
                title: "Connected Agenda"
                description: "A private read-only agenda for Google, Outlook, iCloud, Nextcloud and local ICS calendars. Subscription URLs never enter UI status, logs or support bundles."
                badge: root.state.sourceCount + " SOURCES · " + root.state.eventCount + " EVENTS"
            }

            SettingsCard {
                Layout.fillWidth: true
                title: "ADD CALENDAR SOURCE"
                description: "Paste a private/public ICS or webcal URL exported by your provider, or an absolute path to a local .ics file. NOC never asks for your account password."
                icon: "view-calendar"; glyph: "+"
                GridLayout {
                    Layout.fillWidth: true; columns: 3; columnSpacing: 8
                    TextField {
                        id: sourceName; Layout.preferredWidth: 170; placeholderText: "Family calendar"
                        color: backend.textColor; placeholderTextColor: backend.mutedColor; font.family: "Inter"; font.pixelSize: 9
                        background: Rectangle { color: backend.baseColor; border.color: sourceName.activeFocus ? backend.accentColor : backend.lineColor }
                    }
                    TextField {
                        id: sourceLocation; Layout.fillWidth: true; placeholderText: "https://…/calendar.ics or /home/me/calendar.ics"
                        echoMode: TextInput.PasswordEchoOnEdit
                        color: backend.textColor; placeholderTextColor: backend.mutedColor; font.family: "monospace"; font.pixelSize: 9
                        background: Rectangle { color: backend.baseColor; border.color: sourceLocation.activeFocus ? backend.accentColor : backend.lineColor }
                    }
                    NocturneButton { text: "ADD SOURCE"; selected: true; enabled: !root.busy && sourceName.text.trim() !== "" && sourceLocation.text.trim() !== ""; onClicked: root.addSource() }
                }
            }

            SettingsCard {
                Layout.fillWidth: true
                title: "CALENDARS"
                description: "Refresh is timer-driven and zero-resident between runs. Cached event files and source configuration are private to your user."
                icon: "view-calendar-list"; glyph: "▤"
                Text { visible: !(root.state.sources || []).length; text: "NO CALENDAR SOURCES YET"; color: backend.mutedColor; font.family: "monospace"; font.pixelSize: 9 }
                Repeater {
                    model: root.state.sources || []
                    Rectangle {
                        required property var modelData
                        Layout.fillWidth: true; implicitHeight: 54
                        color: backend.baseColor; border.color: modelData.ok ? backend.lineColor : "#6b5634"
                        RowLayout {
                            anchors.fill: parent; anchors.margins: 8; spacing: 9
                            Rectangle { Layout.preferredWidth: 6; Layout.fillHeight: true; color: modelData.color }
                            ColumnLayout { Layout.fillWidth: true; spacing: 2
                                Text { text: modelData.name; color: backend.textColor; font.family: "Inter"; font.pixelSize: 10; font.bold: true }
                                Text { text: String(modelData.kind).toUpperCase() + " · " + modelData.events + " EVENTS" + (modelData.ok ? " · CURRENT" : " · REFRESH NEEDED"); color: modelData.ok ? backend.mutedColor : "#d9a85f"; font.family: "monospace"; font.pixelSize: 8 }
                            }
                            NocturneToggle { checked: modelData.enabled; accessibleName: "Enable " + modelData.name; onToggleRequested: function(value) { backend.run([root.tool, value ? "enable" : "disable", modelData.id], 3500); root.refresh() } }
                            NocturneButton { text: root.pendingRemove === modelData.id ? "CONFIRM" : "REMOVE"; danger: root.pendingRemove === modelData.id; onClicked: root.removeSource(modelData.id) }
                        }
                    }
                }
                RowLayout {
                    Layout.fillWidth: true
                    Text { Layout.fillWidth: true; text: root.state.refreshed ? "LAST REFRESH · " + root.state.refreshed : "NOT REFRESHED YET"; color: backend.mutedColor; font.family: "monospace"; font.pixelSize: 8; elide: Text.ElideRight }
                    NocturneButton { text: root.busy ? "REFRESHING…" : "REFRESH NOW"; selected: true; enabled: !root.busy && root.state.enabledSources > 0; onClicked: { root.busy = true; backend.run([root.tool, "refresh"], 25000); root.busy = false; root.refresh() } }
                }
            }

            SettingsCard {
                Layout.fillWidth: true
                title: "UPCOMING"
                description: "The next fourteen days from enabled sources. Calendar subscriptions are currently read-only by design."
                icon: "appointment-new"; glyph: "◷"
                Text { visible: !(root.state.upcoming || []).length; text: root.state.configured ? "NO UPCOMING EVENTS" : "ADD A SOURCE TO BUILD YOUR AGENDA"; color: backend.mutedColor; font.family: "monospace"; font.pixelSize: 9 }
                Repeater {
                    model: root.state.upcoming || []
                    Rectangle {
                        required property var modelData; required property int index
                        Layout.fillWidth: true; implicitHeight: 43; color: index % 2 ? backend.baseColor : "transparent"
                        RowLayout { anchors.fill: parent; anchors.leftMargin: 8; anchors.rightMargin: 8; spacing: 9
                            Rectangle { implicitWidth: 5; implicitHeight: 24; color: modelData.color }
                            ColumnLayout { Layout.fillWidth: true; spacing: 1
                                Text { Layout.fillWidth: true; text: modelData.title; color: backend.textColor; font.family: "Inter"; font.pixelSize: 9; font.bold: true; elide: Text.ElideRight }
                                Text { Layout.fillWidth: true; text: modelData.source + (modelData.location ? " · " + modelData.location : ""); color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 8; elide: Text.ElideRight }
                            }
                            Text { text: root.friendlyTime(modelData.start, modelData.allDay); color: backend.accentColor; font.family: "monospace"; font.pixelSize: 8; font.bold: true }
                        }
                    }
                }
            }
            Item { Layout.preferredHeight: 16 }
        }
    }
    Timer { id: removeReset; interval: 5000; onTriggered: root.pendingRemove = "" }
    Timer { interval: 60000; repeat: true; running: root.active; onTriggered: root.refresh() }
    onActiveChanged: if (active) Qt.callLater(refresh)
    Component.onCompleted: if (active) Qt.callLater(refresh)
}
