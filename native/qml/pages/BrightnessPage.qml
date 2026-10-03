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
    property var night: ({available:false, running:false, mode:"off", temperature:0})
    readonly property string nightHelper: backend.home + "/.config/hypr/scripts/night-light"

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
    function refreshNight() { night = backend.json([nightHelper, "status"], 1200) || night }
    function setNight(action, value) {
        var args = [nightHelper, action]
        if (value) args.push(String(value))
        backend.start(args)
        nightDelay.restart()
    }

    ColumnLayout {
        id: panel
        x: 10
        y: 10
        width: parent.width - 20
        spacing: 8
        PanelHeader { Layout.fillWidth: true; title: "Display"; subtitle: "Screen brightness" }
        RowLayout {
            Layout.fillWidth: true
            Text { text: "☼"; color: backend.textColor; font.pixelSize: 20 }
            ColumnLayout {
                Layout.fillWidth: true; spacing: 0
                Text { text: "BUILT-IN DISPLAY"; color: backend.textColor; font.family: "Inter"; font.bold: true }
                Text { text: "Synced with brightness keys"; color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 9 }
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
        SectionLabel { text: "NIGHT SHIFT" }
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 50
            color: backend.surfaceColor
            border.color: backend.lineColor
            RowLayout {
                anchors.fill: parent; anchors.margins: 8
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 1
                    Text { text: "COLOR TEMPERATURE"; color: backend.textColor; font.family: "Inter"; font.bold: true; font.pixelSize: 10 }
                    Text {
                        text: !root.night.available ? "hyprsunset is not installed"
                            : (root.night.mode === "auto" ? "Automatic evening schedule"
                                : (root.night.mode === "manual" ? root.night.temperature + " K manual" : "Filter off"))
                        color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 9
                    }
                }
                NocturneToggle {
                    checked: root.night.running
                    available: root.night.available
                    onToggleRequested: function(enabled) { root.setNight(enabled ? "auto" : "off", 0) }
                }
            }
        }
        RowLayout {
            Layout.fillWidth: true; spacing: 5
            Repeater {
                model: [{label:"WARM",value:3200},{label:"SOFT",value:4000},{label:"NEUTRAL",value:5000}]
                NocturneButton {
                    required property var modelData
                    Layout.fillWidth: true; text: modelData.label
                    enabled: root.night.available
                    selected: root.night.mode === "manual" && root.night.temperature === modelData.value
                    onClicked: root.setNight("set", modelData.value)
                }
            }
            NocturneButton { Layout.fillWidth: true; text: "AUTO"; enabled: root.night.available; selected: root.night.mode === "auto"; onClicked: root.setNight("auto", 0) }
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
    Timer { interval: 3000; running: true; repeat: true; triggeredOnStart: true; onTriggered: root.refreshNight() }
    Timer { id: nightDelay; interval: 700; onTriggered: root.refreshNight() }
}
