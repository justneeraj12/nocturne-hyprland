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
    function refresh() {
        var data = backend.json([backend.home + "/.config/hypr/scripts/pomodoro", "inspect"])
        if (data) state = data
    }
    function action(name) { backend.run([backend.home + "/.config/hypr/scripts/pomodoro", name]); refresh() }
    ColumnLayout {
        id: panel; x: 10; y: 10; width: parent.width - 20; spacing: 8
        SectionLabel { text: "FOCUS // POMODORO" }
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
