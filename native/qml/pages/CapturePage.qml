import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"

Rectangle {
    id: root
    implicitWidth: panel.implicitWidth + 16
    implicitHeight: panel.implicitHeight + 16
    color: backend.baseColor; border.color: backend.accent2Color; border.width: 1
    property string mode: "photo"
    property string source: "area"
    property var recording: ({})
    readonly property bool recordingActive: recording.pid !== undefined
    readonly property int elapsed: recordingActive ? Math.max(0, Math.floor(Date.now() / 1000) - Number(recording.started || 0)) : 0

    function refresh() {
        var state = backend.json([backend.home + "/.local/bin/nocturne-capture-engine", "status"])
        recording = state || ({})
    }
    RowLayout {
        id: panel; x: 8; y: 8; spacing: 6
        ColumnLayout {
            spacing: 0
            SectionLabel { text: "NOCTURNE" }
            Text { text: "CAPTURE"; color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 9 }
        }
        Repeater {
            visible: !root.recordingActive
            model: [{key:"photo",label:"PHOTO"},{key:"video",label:"VIDEO"}]
            NocturneButton { required property var modelData; text: modelData.label; selected: root.mode === modelData.key; onClicked: root.mode = modelData.key }
        }
        Repeater {
            visible: !root.recordingActive
            model: [{key:"area",label:"AREA"},{key:"window",label:"WINDOW"},{key:"display",label:"DISPLAY"}]
            NocturneButton { required property var modelData; text: modelData.label; selected: root.source === modelData.key; onClicked: root.source = modelData.key }
        }
        NocturneButton {
            text: root.recordingActive ? "STOP + SAVE" : (root.mode === "photo" ? "CAPTURE" : "RECORD")
            selected: true
            danger: root.recordingActive
            onClicked: {
                backend.start([backend.home + "/.local/bin/nocturne-capture-engine", root.recordingActive ? "stop" : (root.mode === "photo" ? "shot" : "record"), root.source])
                backend.close()
            }
        }
        Text {
            visible: root.recordingActive
            text: "REC  " + String(Math.floor(root.elapsed / 60)).padStart(2, "0") + ":" + String(root.elapsed % 60).padStart(2, "0")
            color: "#ff8c96"; font.family: "monospace"; font.bold: true
        }
    }
    Timer { interval: 1000; running: true; repeat: true; triggeredOnStart: true; onTriggered: root.refresh() }
}
