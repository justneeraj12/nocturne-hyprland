import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"

Rectangle {
    id: root
    implicitWidth: 410
    implicitHeight: panel.implicitHeight + 20
    color: backend.baseColor; border.color: backend.accent2Color; border.width: 1
    property string status: ""
    property string title: "Nothing playing"
    property string artist: ""
    function refresh() {
        var raw = backend.run(["playerctl", "metadata", "--format", "{{status}}\\t{{title}}\\t{{artist}}"], 1000)
        var fields = raw.split("\\t")
        status = fields[0] || ""; title = fields[1] || "Nothing playing"; artist = fields[2] || ""
    }
    ColumnLayout {
        id: panel; x: 10; y: 10; width: parent.width - 20; spacing: 7
        PanelHeader { Layout.fillWidth: true; title: "Now playing"; subtitle: "Media controls" }
        Text { Layout.fillWidth: true; text: root.title; color: backend.textColor; font.family: "monospace"; font.pixelSize: 14; font.bold: true; elide: Text.ElideRight; horizontalAlignment: Text.AlignHCenter }
        Text { Layout.fillWidth: true; text: root.artist; color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 10; elide: Text.ElideRight; horizontalAlignment: Text.AlignHCenter }
        RowLayout {
            Layout.fillWidth: true
            NocturneButton { Layout.fillWidth: true; text: "󰒮"; onClicked: backend.run(["playerctl", "previous"]) }
            NocturneButton { Layout.fillWidth: true; text: root.status === "Playing" ? "󰏤" : "󰐊"; selected: true; onClicked: backend.run(["playerctl", "play-pause"]) }
            NocturneButton { Layout.fillWidth: true; text: "󰒭"; onClicked: backend.run(["playerctl", "next"]) }
        }
        RowLayout {
            Layout.fillWidth: true
            NocturneButton { Layout.fillWidth: true; text: "VISUALIZER"; onClicked: backend.start([backend.home + "/.local/bin/nocturne-visualizer"]) }
            NocturneButton { Layout.fillWidth: true; text: "SOUND"; onClicked: backend.start([backend.home + "/.local/bin/nocturne-native", "audio"]) }
        }
    }
    Timer { interval: 1000; running: true; repeat: true; onTriggered: root.refresh() }
    Component.onCompleted: refresh()
}
