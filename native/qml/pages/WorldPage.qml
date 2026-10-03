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
            var configured = config.weather_locations || []
            var currentText = backend.readText(backend.home + "/.cache/nocturne/current-location.json")
            var current = currentText ? JSON.parse(currentText) : null
            var currentEnabled = !config.current_location || config.current_location.enabled !== false
            locations = currentEnabled && current && current.timezone ? [current].concat(configured) : configured
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
        return backend.run(["env", "TZ=" + timezone, "date", "+%a %-I:%M%p"]).replace("AM", "+").replace("PM", "−")
    }
    function icon(code) {
        var value = parseInt(code || "-1")
        if (value === 0) return "󰖙"
        if (value >= 1 && value <= 3) return "󰖕"
        if (value === 45 || value === 48) return "󰖑"
        if ((value >= 51 && value <= 67) || (value >= 80 && value <= 82)) return "󰖗"
        if ((value >= 71 && value <= 77) || value === 85 || value === 86) return "󰖘"
        if (value >= 95) return "󰖓"
        return "󰖐"
    }
    function temperature(value) {
        var number = parseFloat(value)
        return isNaN(number) ? "--°" : Math.round(number) + "°"
    }

    ColumnLayout {
        id: panel
        x: 10
        y: 10
        width: parent.width - 20
        spacing: 6
        PanelHeader { Layout.fillWidth: true; title: "World clock"; subtitle: "Family time and weather" }
        RowLayout {
            Layout.fillWidth: true
            SectionLabel { Layout.fillWidth: true; text: "CITIES" }
            NocturneButton {
                text: "REFRESH"
                onClicked: {
                    backend.start([backend.home + "/.config/hypr/scripts/world-status", "--refresh-location"])
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
                    anchors.fill: parent; anchors.margins: 7; spacing: 7
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 1
                        Text { text: modelData.label; color: backend.textColor; font.family: "monospace"; font.bold: true }
                        Text {
                            text: modelData.current
                                ? "CURRENT LOCATION" + (modelData.country ? " · " + modelData.country : "")
                                : (modelData.name || modelData.label)
                            color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 9
                        }
                    }
                    Text {
                        readonly property var data: root.weather[modelData.key || modelData.label] || {temperature:"--",code:""}
                        Layout.preferredWidth: 82
                        text: root.localTime(modelData.timezone)
                        color: backend.textColor; font.family: "monospace"; font.pixelSize: 10; font.bold: true
                        horizontalAlignment: Text.AlignRight
                    }
                    Text {
                        readonly property var data: root.weather[modelData.key || modelData.label] || {temperature:"--",code:""}
                        Layout.preferredWidth: 26
                        text: root.icon(data.code)
                        color: backend.accentColor; font.family: "MesloLGS Nerd Font Mono"; font.pixelSize: 18
                        horizontalAlignment: Text.AlignHCenter
                    }
                    Text {
                        readonly property var data: root.weather[modelData.key || modelData.label] || {temperature:"--",code:""}
                        Layout.preferredWidth: 42
                        text: root.temperature(data.temperature)
                        color: backend.textColor; font.family: "monospace"; font.pixelSize: 11; font.bold: true
                        horizontalAlignment: Text.AlignRight
                    }
                }
            }
        }
    }
    Timer { interval: 30000; running: true; repeat: true; triggeredOnStart: true; onTriggered: root.refresh() }
    Timer { id: delayedRefresh; interval: 2500; onTriggered: root.refresh() }
}
