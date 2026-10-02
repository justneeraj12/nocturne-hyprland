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
    property var locations: []
    property var weather: ({})

    function refresh() {
        try {
            var config = JSON.parse(backend.readText(backend.home + "/.config/nocturne/locations.json"))
            locations = config.weather_locations || []
        } catch (error) { locations = [] }
        var cache = backend.readText(backend.home + "/.cache/nocturne/weather.tsv")
        var next = {}
        cache.split("\n").forEach(function(line) {
            var fields = line.split("\t")
            if (fields.length >= 3) next[fields[0]] = {temperature:fields[1], code:fields[2]}
        })
        weather = next
    }
    function localTime(timezone) {
        return backend.run(["env", "TZ=" + timezone, "date", "+%a  %-I:%M%p"]).replace("AM", "+").replace("PM", "−")
    }
    function icon(code) {
        var value = parseInt(code || "-1")
        if (value === 0) return "SUN"
        if (value >= 95) return "STORM"
        if (value >= 71 && value <= 86) return "SNOW"
        if (value >= 51) return "RAIN"
        if (value >= 1) return "CLOUD"
        return "--"
    }

    ColumnLayout {
        id: panel
        x: 10
        y: 10
        width: parent.width - 20
        spacing: 6
        SectionLabel { text: "WORLD // FAMILY CLOCKS" }
        RowLayout {
            Layout.fillWidth: true
            SectionLabel { Layout.fillWidth: true; text: "LIVE CITY STATUS" }
            NocturneButton {
                text: "REFRESH"
                onClicked: {
                    backend.start([backend.home + "/.config/hypr/scripts/world-status"])
                    delayedRefresh.restart()
                }
            }
        }
        Repeater {
            model: root.locations
            delegate: Rectangle {
                required property var modelData
                Layout.fillWidth: true
                implicitHeight: 49
                color: backend.surfaceColor
                border.color: "#3f3320"
                RowLayout {
                    anchors.fill: parent; anchors.margins: 7
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 1
                        Text { text: modelData.label; color: backend.textColor; font.family: "monospace"; font.bold: true }
                        Text {
                            text: (modelData.name || modelData.label) + " · " + root.localTime(modelData.timezone)
                            color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 9
                        }
                    }
                    Text {
                        readonly property var data: root.weather[modelData.label] || {temperature:"--",code:""}
                        text: root.icon(data.code) + "  " + data.temperature + "°C"
                        color: backend.accentColor; font.family: "monospace"; font.bold: true
                    }
                }
            }
        }
    }
    Timer { interval: 30000; running: true; repeat: true; triggeredOnStart: true; onTriggered: root.refresh() }
    Timer { id: delayedRefresh; interval: 2500; onTriggered: root.refresh() }
}
