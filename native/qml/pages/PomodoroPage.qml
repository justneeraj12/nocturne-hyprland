import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"

Rectangle {
    id: root
    implicitWidth: 410
    implicitHeight: panel.implicitHeight + 20
    color: backend.baseColor; border.color: backend.accent2Color; border.width: 1
    property var state: ({mode:"work",running:false,remaining:1500,total:1500,cycles:0,auto:false})
    property var desk: ({focus:null,focusMinutesToday:0,sessionsToday:0})
    function refresh() {
        var data = backend.json([backend.home + "/.config/hypr/scripts/pomodoro", "inspect"])
        if (data) state = data
        desk = backend.json([backend.home + "/.config/hypr/scripts/desk", "status"]) || desk
    }
    function action(name) { backend.run([backend.home + "/.config/hypr/scripts/pomodoro", name]); refresh() }
    ColumnLayout {
        id: panel; x: 10; y: 10; width: parent.width - 20; spacing: 8
        PanelHeader { Layout.fillWidth: true; title: "Focus timer"; subtitle: "Pomodoro session" }
        Rectangle {
            Layout.fillWidth: true; implicitHeight: 42; color: backend.surfaceColor; border.color: root.desk.focus ? backend.accent2Color : backend.lineColor
            RowLayout { anchors.fill: parent; anchors.margins: 8
                ColumnLayout { Layout.fillWidth: true; spacing: 1
                    Text { text: root.desk.focus ? "FOCUSING NOW" : "NOC DESK"; color: root.desk.focus ? backend.accentColor : backend.mutedColor; font.family: "monospace"; font.pixelSize: 7; font.bold: true }
                    Text { Layout.fillWidth: true; text: root.desk.focus ? root.desk.focus.text : "Choose a task from NOC Desk"; color: backend.textColor; font.family: "Inter"; font.pixelSize: 9; elide: Text.ElideRight }
                }
                Text { text: (root.desk.focusMinutesToday || 0) + "m · " + (root.desk.sessionsToday || 0) + " blocks"; color: backend.mutedColor; font.family: "monospace"; font.pixelSize: 8 }
                NocturneButton { visible: Boolean(root.desk.focus); text: "DONE"; onClicked: { backend.run([backend.home + "/.config/hypr/scripts/desk", "toggle", String(root.desk.focus.id)]); root.refresh() } }
            }
        }
        SectionLabel { Layout.alignment: Qt.AlignHCenter; text: root.state.mode === "work" ? "FOCUS" : "RECOVERY" }
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: String(Math.floor(root.state.remaining / 60)).padStart(2,"0") + ":" + String(root.state.remaining % 60).padStart(2,"0")
            color: backend.textColor; font.family: "monospace"; font.pixelSize: 42; font.bold: true
        }
        ProgressBar { Layout.fillWidth: true; from: 0; to: root.state.total || 1; value: (root.state.total || 1) - root.state.remaining }
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "CYCLE " + (root.state.cycles + 1) + " · " + (root.state.running ? "RUNNING" : "PAUSED")
            color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 10
        }
        RowLayout {
            Layout.fillWidth: true; spacing: 5
            NocturneButton { Layout.fillWidth: true; text: root.state.running ? "PAUSE" : "START"; selected: root.state.running; onClicked: root.action("toggle") }
            NocturneButton { Layout.fillWidth: true; text: "RESET"; onClicked: root.action("reset") }
            NocturneButton { Layout.fillWidth: true; text: "SKIP"; onClicked: root.action("skip") }
        }
        RowLayout {
            Layout.fillWidth: true
            Text { Layout.fillWidth: true; text: "AUTO-START NEXT PHASE"; color: backend.textColor; font.family: "Inter"; font.pixelSize: 9 }
            NocturneToggle { checked: root.state.auto; accessibleName: "Auto-start next Pomodoro phase"; onToggleRequested: function(enabled) { backend.run([backend.home + "/.config/hypr/scripts/pomodoro", "auto", enabled ? "on" : "off"]); root.refresh() } }
            NocturneButton { text: "NOC DESK"; onClicked: backend.start([backend.home + "/.local/bin/nocturne-native", "desk"]) }
        }
        SectionLabel { text: "PRESETS" }
        RowLayout {
            Layout.fillWidth: true; spacing: 5
            Repeater {
                model: [{label:"25 / 5",work:25,rest:5},{label:"50 / 10",work:50,rest:10},{label:"15 / 5",work:15,rest:5}]
                NocturneButton {
                    required property var modelData
                    Layout.fillWidth: true; text: modelData.label
                    onClicked: { backend.run([backend.home + "/.config/hypr/scripts/pomodoro", "preset", String(modelData.work), String(modelData.rest)]); root.refresh() }
                }
            }
        }
    }
    Timer { interval: 1000; running: true; repeat: true; triggeredOnStart: true; onTriggered: root.refresh() }
}
