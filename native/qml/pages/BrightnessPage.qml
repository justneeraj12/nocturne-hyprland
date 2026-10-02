import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"

Rectangle {
    id: root
    implicitWidth: 410
    implicitHeight: panel.implicitHeight + 20
    color: backend.baseColor
    border.color: backend.accent2Color
    border.width: 1
    property int brightness: 50
    property int pendingBrightness: -1

    function refresh() {
        var text = backend.run(["brightnessctl", "-m"])
        var match = text.match(/,(\d+)%,/)
        if (match && !slider.pressed && pendingBrightness < 0) brightness = parseInt(match[1])
    }
    function queueBrightness(value) {
        brightness = Math.round(value)
        pendingBrightness = brightness
        applyBrightness.restart()
    }

    ColumnLayout {
        id: panel
        x: 10
        y: 10
        width: parent.width - 20
        spacing: 8
        SectionLabel { text: "DISPLAY // NATIVE BRIGHTNESS" }
        RowLayout {
            Layout.fillWidth: true
            Text { text: "☼"; color: backend.textColor; font.pixelSize: 20 }
            ColumnLayout {
                Layout.fillWidth: true; spacing: 0
                Text { text: "LAPTOP DISPLAY"; color: backend.textColor; font.family: "Inter"; font.bold: true }
                Text { text: "Hardware backlight · live state"; color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 9 }
            }
            Text { text: root.brightness + "%"; color: backend.textColor; font.family: "monospace"; font.bold: true }
        }
        NocturneSlider {
            id: slider
            Layout.fillWidth: true
            from: 5; to: 100; value: root.brightness
            onMoved: root.queueBrightness(value)
        }
        SectionLabel { text: "QUICK LEVELS" }
        RowLayout {
            Layout.fillWidth: true; spacing: 5
            Repeater {
                model: [{label:"DIM",value:20},{label:"LOW",value:35},{label:"BAL",value:55},{label:"BRIGHT",value:75},{label:"MAX",value:100}]
                NocturneButton {
                    required property var modelData
                    Layout.fillWidth: true
                    text: modelData.label
                    selected: Math.abs(root.brightness - modelData.value) < 5
                    onClicked: root.queueBrightness(modelData.value)
                }
            }
        }
    }
    Timer {
        id: applyBrightness
        interval: 70
        onTriggered: {
            var value = root.pendingBrightness
            root.pendingBrightness = -1
            if (value >= 0) backend.run([backend.home + "/.config/hypr/scripts/brightness", "set", String(value)])
        }
    }
    Timer { interval: 200; running: true; repeat: true; triggeredOnStart: true; onTriggered: root.refresh() }
}
