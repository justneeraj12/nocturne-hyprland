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

    property var players: []
    property string player: ""
    property string status: ""
    property string title: "Nothing playing"
    property string artist: ""
    property string album: ""
    property string artUrl: ""
    property real positionSeconds: 0
    property real lengthSeconds: 0
    property real playerVolume: 1
    property double pinnedUntil: 0

    function playerLabel(name) {
        if (!name) return "No media player"
        var value = String(name).split(".")[0]
        return value.charAt(0).toUpperCase() + value.slice(1)
    }

    function formatTime(seconds) {
        var value = Math.max(0, Math.round(seconds || 0))
        var hours = Math.floor(value / 3600)
        var minutes = Math.floor((value % 3600) / 60)
        var remainder = value % 60
        return (hours > 0 ? hours + ":" + String(minutes).padStart(2, "0") : minutes)
            + ":" + String(remainder).padStart(2, "0")
    }

    function refresh() {
        var raw = backend.run(["playerctl", "-a", "metadata", "--format",
            "{{playerName}}\\t{{status}}\\t{{title}}\\t{{artist}}\\t{{album}}\\t{{mpris:length}}\\t{{position}}\\t{{mpris:artUrl}}"], 1400)
        var entries = raw.split("\\n").filter(function(line) { return line !== "" }).map(function(line) {
            var fields = line.split("\\t")
            return {
                player: fields[0] || "",
                status: fields[1] || "",
                title: fields[2] || "Untitled",
                artist: fields[3] || "",
                album: fields[4] || "",
                length: (parseFloat(fields[5] || "0") || 0) / 1000000,
                position: (parseFloat(fields[6] || "0") || 0) / 1000000,
                art: fields[7] || ""
            }
        })
        players = entries.map(function(entry) { return entry.player })

        var current = entries.filter(function(entry) { return entry.player === root.player })[0]
        var playing = entries.filter(function(entry) { return entry.status === "Playing" })[0]
        var selected = current && Date.now() < pinnedUntil ? current : (playing || current || entries[0])
        if (!selected) {
            player = ""; status = ""; title = "Nothing playing"; artist = ""; album = ""; artUrl = ""
            positionSeconds = 0; lengthSeconds = 0
            return
        }

        player = selected.player
        status = selected.status
        title = selected.title
        artist = selected.artist
        album = selected.album
        artUrl = selected.art
        lengthSeconds = selected.length
        if (!seek.pressed) positionSeconds = selected.position
        if (!playerVolumeSlider.pressed) {
            var volumeText = backend.run(["playerctl", "--player", player, "volume"], 800)
            var parsedVolume = parseFloat(volumeText)
            if (!isNaN(parsedVolume)) playerVolume = parsedVolume
        }
    }

    function runPlayer(action, extra) {
        if (!player) return
        var command = ["playerctl", "--player", player, action]
        if (extra) command = command.concat(extra)
        backend.run(command, 1400)
        delayedRefresh.restart()
    }

    function cyclePlayer() {
        if (players.length < 2) return
        var index = players.indexOf(player)
        player = players[(index + 1) % players.length]
        pinnedUntil = Date.now() + 10000
        refresh()
    }
    function navigate(delta) {
        if (players.length < 2) return
        var index = players.indexOf(player)
        player = players[(index + delta + players.length) % players.length]
        pinnedUntil = Date.now() + 15000
        refresh()
    }
    function activateCurrent() { runPlayer("play-pause") }

    ColumnLayout {
        id: panel
        x: 10
        y: 10
        width: parent.width - 20
        spacing: 7

        RowLayout {
            Layout.fillWidth: true
            PanelHeader {
                Layout.fillWidth: true
                title: "Now playing"
                subtitle: root.playerLabel(root.player) + (root.status ? " · " + root.status : "")
            }
            NocturneButton {
                visible: root.players.length > 1
                text: "SWITCH"
                onClicked: root.cyclePlayer()
            }
        }

        RowLayout {
            Layout.fillWidth: true
            visible: root.players.length > 1
            spacing: 4
            Repeater { model: root.players
                NocturneButton { required property string modelData; Layout.fillWidth: true; text: root.playerLabel(modelData).toUpperCase(); selected: root.player === modelData; onClicked: { root.player = modelData; root.pinnedUntil = Date.now() + 15000; root.refresh() } }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            Rectangle {
                implicitWidth: 68
                implicitHeight: 68
                color: backend.surfaceColor
                border.color: backend.lineColor
                Image {
                    id: artwork
                    anchors.fill: parent
                    anchors.margins: 2
                    source: root.artUrl
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }
                Text {
                    anchors.centerIn: parent
                    visible: root.artUrl === "" || artwork.status === Image.Error
                    text: "󰝚"
                    color: backend.accentColor
                    font.family: "MesloLGS Nerd Font Mono"
                    font.pixelSize: 27
                }
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 3
                Text {
                    Layout.fillWidth: true
                    text: root.title
                    color: backend.textColor
                    font.family: "monospace"
                    font.pixelSize: 14
                    font.bold: true
                    elide: Text.ElideRight
                }
                Text {
                    Layout.fillWidth: true
                    text: root.artist || root.playerLabel(root.player)
                    color: backend.mutedColor
                    font.family: "Inter"
                    font.pixelSize: 10
                    elide: Text.ElideRight
                }
                Text {
                    Layout.fillWidth: true
                    visible: root.album !== ""
                    text: root.album
                    color: backend.mutedColor
                    font.family: "Inter"
                    font.pixelSize: 9
                    elide: Text.ElideRight
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Text { text: "PLAYER VOL"; color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 8; font.bold: true }
            NocturneSlider { id: playerVolumeSlider; Layout.fillWidth: true; from: 0; to: 1; stepSize: .01; value: root.playerVolume; onPressedChanged: if (!pressed && root.player) { root.playerVolume = value; root.runPlayer("volume", [value.toFixed(2)]) } }
            Text { text: Math.round(playerVolumeSlider.value * 100) + "%"; color: backend.textColor; font.family: "monospace"; font.pixelSize: 9 }
        }

        NocturneSlider {
            id: seek
            visible: root.lengthSeconds > 0
            Layout.fillWidth: true
            from: 0
            to: Math.max(1, root.lengthSeconds)
            value: root.positionSeconds
            onPressedChanged: {
                if (!pressed && root.player) {
                    root.positionSeconds = value
                    root.runPlayer("position", [String(value)])
                }
            }
        }

        RowLayout {
            visible: root.lengthSeconds > 0
            Layout.fillWidth: true
            Text { text: root.formatTime(root.positionSeconds); color: backend.mutedColor; font.family: "monospace"; font.pixelSize: 9 }
            Item { Layout.fillWidth: true }
            Text { text: root.formatTime(root.lengthSeconds); color: backend.mutedColor; font.family: "monospace"; font.pixelSize: 9 }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 5
            NocturneButton { Layout.fillWidth: true; text: "󰒮"; font.family: "MesloLGS Nerd Font Mono"; font.pixelSize: 15; onClicked: root.runPlayer("previous") }
            NocturneButton {
                Layout.fillWidth: true
                text: root.status === "Playing" ? "󰏤  PAUSE" : "󰐊  PLAY"
                font.family: "MesloLGS Nerd Font Mono"
                font.pixelSize: 12
                selected: root.status === "Playing"
                onClicked: root.runPlayer("play-pause")
            }
            NocturneButton { Layout.fillWidth: true; text: "󰒭"; font.family: "MesloLGS Nerd Font Mono"; font.pixelSize: 15; onClicked: root.runPlayer("next") }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 5
            NocturneButton { Layout.fillWidth: true; text: "VISUALIZER"; onClicked: backend.start([backend.home + "/.local/bin/nocturne-visualizer"]) }
            NocturneButton { Layout.fillWidth: true; text: "SOUND"; onClicked: backend.start([backend.home + "/.local/bin/nocturne-native", "audio"]) }
        }
    }

    Timer { interval: 1000; running: true; repeat: true; triggeredOnStart: true; onTriggered: root.refresh() }
    Timer { id: delayedRefresh; interval: 250; onTriggered: root.refresh() }
}
