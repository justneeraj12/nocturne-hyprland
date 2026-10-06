import QtQuick
import QtQuick.Layouts
import "../components"

Rectangle {
    id: root
    implicitWidth: 330
    implicitHeight: 72
    color: backend.baseColor
    border.color: muted ? "#c75c66" : backend.accent2Color
    border.width: 1
    opacity: 0
    scale: 0.97

    property string kind: "volume"
    property int value: 0
    property bool muted: false

    function refresh() {
        var fields = String(backend.page).split("|")
        kind = fields[0] || "volume"
        value = Math.max(0, Math.min(150, parseInt(fields[1]) || 0))
        muted = fields[2] === "true"
        hideTimer.restart()
        enter.restart()
    }
    function title() {
        if (kind === "brightness") return "DISPLAY BRIGHTNESS"
        if (kind === "microphone") return muted ? "MICROPHONE MUTED" : "MICROPHONE LIVE"
        return muted ? "MASTER VOLUME MUTED" : "MASTER VOLUME"
    }
    function icon() {
        if (kind === "brightness") return "󰖨"
        if (kind === "microphone") return muted ? "󰍭" : "󰍬"
        return muted ? "󰖁" : (value < 35 ? "󰕿" : (value < 70 ? "󰖀" : "󰕾"))
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 11
        spacing: 11
        Text {
            text: root.icon()
            color: root.muted ? "#ff8c96" : backend.accentColor
            font.family: "MesloLGS Nerd Font Mono"; font.pixelSize: 20
        }
        ColumnLayout {
            Layout.fillWidth: true; spacing: 4
            RowLayout {
                Layout.fillWidth: true
                Text { Layout.fillWidth: true; text: root.title(); color: backend.textColor; font.family: "Inter"; font.pixelSize: 9; font.bold: true }
                Text { text: root.value + "%"; color: backend.textColor; font.family: "monospace"; font.pixelSize: 11; font.bold: true }
            }
            Rectangle {
                Layout.fillWidth: true; implicitHeight: 5; color: backend.lineColor
                Rectangle {
                    width: Math.min(1, root.value / 100) * parent.width
                    height: parent.height
                    color: root.muted ? "#c75c66" : backend.accentColor
                    Behavior on width { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }
                }
            }
        }
    }

    ParallelAnimation {
        id: enter
        NumberAnimation { target: root; property: "opacity"; from: 0.25; to: 1; duration: 110 }
        NumberAnimation { target: root; property: "scale"; from: 0.97; to: 1; duration: 110; easing.type: Easing.OutCubic }
    }
    Timer { id: hideTimer; interval: 1150; onTriggered: backend.close() }
    Connections { target: backend; function onPageChanged() { root.refresh() } }
    Component.onCompleted: refresh()
}
