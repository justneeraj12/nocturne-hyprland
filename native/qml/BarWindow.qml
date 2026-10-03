import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.layershell 1.0 as LayerShellQt
import "components"

ApplicationWindow {
    id: root
    required property var targetScreen
    required property var shell
    readonly property bool fullBar: targetScreen.name === "HDMI-A-1" || targetScreen === Qt.application.primaryScreen
    readonly property int activeWorkspace: {
        for (var i = 0; i < shell.monitors.length; ++i)
            if (shell.monitors[i].name === targetScreen.name) return shell.monitors[i].activeWorkspace.id
        return 1
    }
    visible: true
    screen: targetScreen
    height: 29
    color: backend.baseColor
    flags: Qt.FramelessWindowHint | Qt.Tool

    function run(args) { backend.start(args) }
    function clockText(value) {
        var hours = value.getHours()
        var displayHour = hours % 12
        if (displayHour === 0) displayHour = 12
        return displayHour + ":" + String(value.getMinutes()).padStart(2, "0") + (hours < 12 ? "+" : "−")
    }
    function mediaCommand(action) {
        var args = ["playerctl"]
        if (shell.media.player) args = args.concat(["--player", shell.media.player])
        args.push(action)
        root.run(args)
    }
    function nativeCard(surface, page) {
        var args = [backend.home + "/.local/bin/nocturne-native", surface]
        if (page) args.push(page)
        run(args)
    }

    LayerShellQt.Window.scope: "nocturne-bar"
    LayerShellQt.Window.layer: LayerShellQt.Window.LayerTop
    LayerShellQt.Window.exclusionZone: root.height
    LayerShellQt.Window.keyboardInteractivity: LayerShellQt.Window.KeyboardInteractivityNone
    LayerShellQt.Window.screen: root.targetScreen
    LayerShellQt.Window.anchors: LayerShellQt.Window.AnchorTop | LayerShellQt.Window.AnchorLeft | LayerShellQt.Window.AnchorRight

    Rectangle {
        anchors.fill: parent
        color: backend.baseColor
        border.color: backend.lineColor
        border.width: 1

        Row {
            id: left
            anchors.left: parent.left
            anchors.leftMargin: 5
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2
            BarButton {
                text: ""
                tooltip: "Applications · right-click for settings"
                onLeftClicked: root.run([backend.home + "/.config/hypr/scripts/launcher"])
                onRightClicked: root.run([backend.home + "/.config/hypr/scripts/control-center"])
                onMiddleClicked: root.run([backend.home + "/.config/hypr/scripts/help"])
            }
            Repeater {
                model: 9
                BarButton {
                    required property int index
                    text: String(index + 1)
                    tooltip: "Workspace " + String(index + 1)
                    selected: root.activeWorkspace === index + 1
                    onLeftClicked: root.run(["hyprctl", "dispatch", "hl.dsp.focus({ workspace = \"" + String(index + 1) + "\" })"])
                    onScrolled: function(direction) {
                        var workspace = direction > 0 ? "e-1" : "e+1"
                        root.run(["hyprctl", "dispatch", "hl.dsp.focus({ workspace = \"" + workspace + "\" })"])
                    }
                }
            }
            BarButton {
                visible: shell.minimized.text && shell.minimized.text !== ""
                text: shell.minimized.text || ""
                tooltip: "Minimized windows"
                onLeftClicked: root.nativeCard("minimized", "")
                onRightClicked: root.run([backend.home + "/.config/hypr/scripts/minimize", "restore-all"])
            }
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            spacing: 3
            BarButton {
                text: Qt.formatDate(shell.now, "ddd dd MMM") + "  ·  " + root.clockText(shell.now)
                tooltip: "Left: calendar · Right: world clocks"
                onLeftClicked: root.nativeCard("calendar", "")
                onRightClicked: root.nativeCard("world", "")
            }
            BarButton {
                visible: root.fullBar
                text: "󰖟"
                tooltip: "World clocks and weather"
                onLeftClicked: root.nativeCard("world", "")
            }
        }

        Row {
            id: right
            anchors.right: parent.right
            anchors.rightMargin: 5
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2
            BarButton {
                visible: root.fullBar
                text: shell.pomodoro.text || "󰔟"
                tooltip: "Focus timer"
                onLeftClicked: root.nativeCard("pomodoro", "")
                onRightClicked: root.run([backend.home + "/.config/hypr/scripts/pomodoro", "reset"])
            }
            BarButton {
                visible: root.fullBar && shell.media.title !== ""
                width: Math.min(190, implicitWidth)
                text: (shell.media.status === "Playing" ? "󰎈 " : "󰏤 ") + shell.media.title.substring(0, 22)
                tooltip: "Now playing · middle-click to pause"
                onLeftClicked: root.nativeCard("media", "")
                onMiddleClicked: root.mediaCommand("play-pause")
                onRightClicked: root.mediaCommand("next")
            }
            BarButton {
                visible: root.fullBar
                text: shell.caffeine.text || "󰛊"
                fontPixelSize: 12
                tooltip: shell.caffeine.tooltip || "Caffeine mode"
                selected: shell.caffeine.class === "active"
                onLeftClicked: {
                    backend.run([backend.home + "/.config/hypr/scripts/caffeine", "toggle"])
                    shell.refreshCaffeine()
                }
            }
            BarButton {
                visible: root.fullBar
                text: "•••"
                fontPixelSize: 11
                tooltip: "Background apps"
                onLeftClicked: root.nativeCard("background", "")
            }
            BarButton {
                visible: root.fullBar
                text: shell.kdeconnect.text || "󰄜"
                tooltip: shell.kdeconnect.tooltip || "KDE Connect"
                onLeftClicked: root.nativeCard("kdeconnect", "")
                onRightClicked: root.run([backend.home + "/.config/hypr/scripts/kdeconnect-menu", "clipboard"])
            }
            BarButton {
                visible: root.fullBar
                text: (shell.volumeMuted ? "" : "") + " " + shell.volume + "%"
                fontPixelSize: 11
                tooltip: "Master volume · scroll to adjust"
                onLeftClicked: root.nativeCard("audio", "")
                onMiddleClicked: root.run([backend.home + "/.local/bin/nocturne-visualizer"])
                onRightClicked: root.run(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"])
                onScrolled: function(direction) { root.run(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", direction > 0 ? "5%+" : "5%-"]) }
            }
            BarButton {
                visible: root.fullBar
                text: shell.micMuted ? "󰍭" : "󰍬"
                fontPixelSize: 12
                selected: shell.micInUse
                selectedColor: "#c75c66"
                tooltip: shell.micInUse ? "Microphone in use" : (shell.micMuted ? "Microphone muted" : "Microphone ready")
                onLeftClicked: root.run(["wpctl", "set-mute", "@DEFAULT_AUDIO_SOURCE@", "toggle"])
            }
            BarButton {
                text: "󰃠 " + shell.brightness + "%"
                tooltip: "Display brightness · scroll to adjust"
                onLeftClicked: root.nativeCard("brightness", "")
                onScrolled: function(direction) { root.run([backend.home + "/.config/hypr/scripts/brightness", direction > 0 ? "up" : "down"]) }
            }
            BarButton {
                visible: root.fullBar
                text: shell.systemState.text || "󰍛"
                fontPixelSize: 11
                tooltip: shell.systemState.tooltip || "System resources"
                onLeftClicked: root.run([backend.home + "/.local/bin/nocturne-dashboard"])
            }
            BarButton {
                text: shell.connectivity.text || "󰤨"
                tooltip: shell.connectivity.tooltip || "Wi-Fi · Bluetooth · VPN"
                onLeftClicked: root.nativeCard("connectivity", "wifi")
                onRightClicked: root.nativeCard("connectivity", "bluetooth")
                onMiddleClicked: root.nativeCard("connectivity", "vpn")
            }
            BarButton {
                text: shell.dnd ? "󰂛" : (shell.notificationCount > 0 ? "󱅫 " + shell.notificationCount : "󰂚")
                selected: shell.notificationCount > 0
                tooltip: shell.dnd ? "Notifications · do not disturb on" : "Notifications"
                onLeftClicked: root.nativeCard("notifications", "")
                onRightClicked: root.run(["makoctl", "mode", "-t", "do-not-disturb"])
            }
            BarButton {
                text: shell.battery.text || "󰁹"
                fontPixelSize: 11
                tooltip: shell.battery.tooltip || "Battery and power"
                onLeftClicked: root.nativeCard("power", "")
            }
        }
    }
}
