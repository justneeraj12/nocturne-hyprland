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
    property var sinks: []
    property var streams: []
    property string defaultSink: ""
    property int masterVolume: 0
    property bool masterMuted: false
    property bool streamDragging: false

    function refresh() {
        defaultSink = backend.run(["pactl", "get-default-sink"])
        var nextSinks = backend.json(["pactl", "-f", "json", "list", "sinks"])
        sinks = nextSinks || []
        var volumeText = backend.run(["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]) || ""
        var match = volumeText.match(/Volume:\s*([0-9.]+)/)
        if (match && !master.pressed) masterVolume = Math.round(parseFloat(match[1]) * 100)
        masterMuted = volumeText.indexOf("[MUTED]") >= 0
        if (!streamDragging) streams = backend.audioStreams()
    }

    ColumnLayout {
        id: panel
        x: 10
        y: 10
        width: parent.width - 20
        spacing: 8

        SectionLabel { text: "AUDIO // NATIVE MIXER" }
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            NocturneButton {
                text: root.masterMuted ? "MUTED" : "VOL"
                onClicked: { backend.run(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"]); root.refresh() }
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                Text { text: "MASTER"; color: backend.textColor; font.family: "Inter"; font.bold: true; font.pixelSize: 11 }
                Text {
                    Layout.fillWidth: true
                    text: {
                        for (var i = 0; i < root.sinks.length; ++i)
                            if (root.sinks[i].name === root.defaultSink) return root.sinks[i].description || root.defaultSink
                        return root.defaultSink
                    }
                    color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 9; elide: Text.ElideRight
                }
            }
            Text { text: root.masterVolume + "%"; color: backend.textColor; font.family: "monospace"; font.bold: true }
        }
        NocturneSlider {
            id: master
            Layout.fillWidth: true
            from: 0; to: 150; value: root.masterVolume
            onMoved: backend.run(["wpctl", "set-volume", "--limit", "1.5", "@DEFAULT_AUDIO_SINK@", Math.round(value) + "%"])
        }
        SectionLabel { text: "OUTPUT DEVICE" }
        RowLayout {
            Layout.fillWidth: true
            spacing: 5
            Repeater {
                model: root.sinks.filter(function(sink) {
                    return sink.name !== "easyeffects_sink" && String(sink.name).indexOf(".monitor") < 0
                }).sort(function(a, b) { return a.name === root.defaultSink ? -1 : (b.name === root.defaultSink ? 1 : 0) }).slice(0, 3)
                NocturneButton {
                    required property var modelData
                    Layout.fillWidth: true
                    text: {
                        var label = String(modelData.description || modelData.name)
                        var hdmi = label.match(/HDMI\s*\/\s*DisplayPort\s*(\d+)?/i)
                        if (hdmi) return "HDMI " + (hdmi[1] || "")
                        if (label.toLowerCase().indexOf("headphone") >= 0) return "HEADPHONES"
                        return label.substring(0, 14)
                    }
                    selected: modelData.name === root.defaultSink
                    onClicked: {
                        backend.run([backend.home + "/.config/hypr/scripts/audio-route", "set", modelData.name, modelData.description || modelData.name], 12000)
                        root.refresh()
                    }
                }
            }
        }
        SectionLabel { text: "APP VOLUME · " + root.streams.length + " ACTIVE" }
        Text {
            visible: root.streams.length === 0
            text: "No active audio streams · start playback to add an app"
            color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 10
            Layout.fillWidth: true
        }
        Repeater {
            model: root.streams
            delegate: Rectangle {
                required property var modelData
                Layout.fillWidth: true
                implicitHeight: streamColumn.implicitHeight + 12
                color: backend.surfaceColor
                border.color: backend.lineColor
                ColumnLayout {
                    id: streamColumn
                    anchors.fill: parent
                    anchors.margins: 6
                    spacing: 3
                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            Layout.fillWidth: true
                            text: modelData.name || "Application"
                            color: backend.textColor; font.family: "Inter"; font.bold: true
                        }
                        NocturneButton {
                            text: modelData.muted ? "MUTED" : "VOL"
                            onClicked: { backend.run(["wpctl", "set-mute", String(modelData.id), "toggle"]); root.refresh() }
                        }
                        Text { text: modelData.volume + "%"; color: backend.mutedColor; font.family: "monospace" }
                    }
                    NocturneSlider {
                        Layout.fillWidth: true
                        from: 0; to: 150; value: modelData.volume
                        onPressedChanged: root.streamDragging = pressed
                        onMoved: backend.run(["wpctl", "set-volume", "--limit", "1.5", String(modelData.id), Math.round(value) + "%"])
                    }
                }
            }
        }
    }
    Timer { interval: 800; running: true; repeat: true; triggeredOnStart: true; onTriggered: root.refresh() }
}
