import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "components"

ApplicationWindow {
    id: root
    visible: true
    width: 860
    height: 600
    minimumWidth: 720
    minimumHeight: 500
    title: "Nocturne Settings"
    color: backend.baseColor
    property int section: 0

    function openSurface(surface, page) {
        var args = [backend.home + "/.local/bin/nocturne-native", surface]
        if (page) args.push(page)
        backend.start(args)
    }

    header: Rectangle {
        implicitHeight: 46
        color: backend.surfaceColor
        border.color: backend.lineColor
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 15
            anchors.rightMargin: 15
            Text {
                Layout.fillWidth: true
                text: "NOCTURNE // SYSTEM CONTROL"
                color: backend.textColor
                font.family: "monospace"
                font.pixelSize: 13
                font.bold: true
                font.letterSpacing: 1
            }
            Text {
                text: "HYPRLAND · WAYLAND NATIVE"
                color: backend.mutedColor
                font.family: "Inter"
                font.pixelSize: 9
            }
        }
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: 182
            color: "#090d0e"
            border.color: backend.lineColor
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 5
                SectionLabel { text: "CONTROL GROUPS" }
                Repeater {
                    model: ["APPEARANCE", "CONNECTIVITY", "SOUND + DISPLAY", "WORKFLOW", "POWER + SESSION", "ABOUT"]
                    NocturneButton {
                        required property int index
                        required property string modelData
                        Layout.fillWidth: true
                        text: modelData
                        selected: root.section === index
                        onClicked: root.section = index
                    }
                }
                Item { Layout.fillHeight: true }
                SectionLabel { text: "NOCTURNE 2.0" }
                Text {
                    Layout.fillWidth: true
                    text: "Qt Quick · layer-shell\nNetworkManager · PipeWire\nBlueZ · power-profiles-daemon"
                    color: backend.mutedColor
                    font.family: "monospace"
                    font.pixelSize: 9
                    lineHeight: 1.35
                }
            }
        }

        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: root.section

            AppearancePage {}
            SettingsPage {
                title: "CONNECTIVITY"
                description: "NetworkManager and BlueZ remain the system backends; Nocturne supplies the shell interface."
                actions: [
                    {label:"WI-FI", detail:"Networks, signal and the active connection.", button:"MANAGE", surface:"connectivity", page:"wifi"},
                    {label:"BLUETOOTH", detail:"Radio, discovered devices and active connections.", button:"MANAGE", surface:"connectivity", page:"bluetooth"},
                    {label:"VPN", detail:"Start and stop NetworkManager VPN profiles.", button:"MANAGE", surface:"connectivity", page:"vpn"}
                ]
            }
            SettingsPage {
                title: "SOUND + DISPLAY"
                description: "Live PipeWire streams and the hardware backlight are sampled only while their card is open."
                actions: [
                    {label:"OUTPUT + APP MIXER", detail:"Master volume, output routing and every currently playing app.", button:"OPEN", surface:"audio"},
                    {label:"BRIGHTNESS", detail:"Live backlight state, hardware-key synchronization and presets.", button:"OPEN", surface:"brightness"}
                ]
            }
            SettingsPage {
                title: "WORKFLOW"
                description: "The shell stays keyboard-first, but every common action remains clickable."
                actions: [
                    {label:"FOCUS TIMER", detail:"Pomodoro presets, pause, skip and cycle progress.", button:"OPEN", surface:"pomodoro"},
                    {label:"SCREEN CAPTURE", detail:"Screenshot or record an area, window or display.", button:"OPEN", surface:"capture"},
                    {label:"KEY GUIDE", detail:"Open the complete shortcut reference in a terminal.", button:"SHOW", command:"keys"}
                ]
            }
            SettingsPage {
                title: "POWER + SESSION"
                description: "Profiles are backed by power-profiles-daemon and the session actions are provided by systemd/UWSM."
                actions: [
                    {label:"POWER MODE", detail:"Super, Performance, Balanced and Saver with verified state.", button:"OPEN", surface:"power"},
                    {label:"LOCK", detail:"Lock now using the themed Hyprlock session.", button:"LOCK", command:"lock"}
                ]
            }
            SettingsPage {
                title: "ABOUT"
                description: "Nocturne is an open Hyprland desktop layer built from standard, replaceable Linux services."
                actions: [
                    {label:"SYSTEM CHECK", detail:"Run the read-only Nocturne diagnostics in a terminal.", button:"RUN", command:"doctor"},
                    {label:"SOURCE", detail:"Configuration, native shell code, installer and validation live in one repository.", button:"GITHUB", command:"source"}
                ]
            }
        }
    }

    component AppearancePage: Rectangle {
        id: appearance
        color: backend.baseColor
        property var images: backend.wallpapers()
        property string current: {
            var state = backend.json([backend.home + "/.local/bin/nocturne-wallpaper-cycle", "status"])
            return state ? (state.current || "") : ""
        }
        function applyWallpaper(path) {
            backend.run([backend.home + "/.local/bin/nocturne-wallpaper-cycle", "disable"], 10000)
            backend.start([backend.home + "/.local/bin/nocturne-wallpaper-cycle", "apply-file", path])
            current = path
        }
        function applyDesign(name) {
            backend.run([backend.home + "/.config/hypr/scripts/theme-preset", name], 12000)
            backend.refreshTheme()
        }
        function applyAccent(name) {
            backend.run([backend.home + "/.config/hypr/scripts/accent", name], 12000)
            backend.refreshTheme()
        }
        ScrollView {
            anchors.fill: parent
            contentWidth: availableWidth
            ColumnLayout {
                x: 22
                width: parent.width - 44
                spacing: 10
                Text { text: "APPEARANCE"; color: backend.textColor; font.family: "monospace"; font.pixelSize: 25; font.bold: true }
                Text { Layout.fillWidth: true; text: "Native shell palette, layout density and compositor wallpapers."; color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 11; wrapMode: Text.WordWrap }
                SectionLabel { text: "WALLPAPER LIBRARY · ~/PICTURES/WALLPAPERS" }
                GridView {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 178
                    clip: true
                    cellWidth: 150
                    cellHeight: 84
                    model: appearance.images
                    delegate: Item {
                        required property var modelData
                        width: 146; height: 80
                        Image {
                            anchors.fill: parent
                            anchors.margins: 2
                            source: "file://" + modelData.path
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                        }
                        Rectangle {
                            anchors.fill: parent
                            color: "transparent"
                            border.width: appearance.current === modelData.path ? 2 : 1
                            border.color: appearance.current === modelData.path ? backend.accentColor : backend.lineColor
                        }
                        MouseArea { anchors.fill: parent; onClicked: appearance.applyWallpaper(modelData.path) }
                    }
                }
                RowLayout {
                    Layout.fillWidth: true
                    NocturneButton {
                        Layout.fillWidth: true; text: "FOLLOW DYNAMIC DAY CYCLE"
                        onClicked: backend.start([backend.home + "/.local/bin/nocturne-wallpaper-cycle", "enable"])
                    }
                    NocturneButton {
                        text: "OPEN FOLDER"
                        onClicked: backend.start(["pcmanfm-qt", backend.home + "/Pictures/Wallpapers"])
                    }
                }
                SectionLabel { text: "DESIGN PRESET" }
                Flow {
                    Layout.fillWidth: true
                    Layout.preferredHeight: childrenRect.height
                    spacing: 5
                    Repeater {
                        model: ["Obsidian Grid", "Carbon Compact", "Midnight Circuit", "Phosphor Terminal", "Crimson Relay", "Copper Blue", "Copper Deep Green", "Copper Deep Gold"]
                        NocturneButton { required property string modelData; text: modelData.toUpperCase(); onClicked: appearance.applyDesign(modelData) }
                    }
                }
                SectionLabel { text: "ACCENT" }
                Flow {
                    Layout.fillWidth: true
                    Layout.preferredHeight: childrenRect.height
                    spacing: 5
                    Repeater {
                        model: ["Green", "Teal", "Cyan", "Ice", "Slate", "Blue", "Indigo", "Purple", "Magenta", "Pink", "Red", "Rose", "Orange", "Amber", "Yellow", "Lime"]
                        NocturneButton { required property string modelData; text: modelData.toUpperCase(); onClicked: appearance.applyAccent(modelData) }
                    }
                }
                RowLayout {
                    Layout.fillWidth: true
                    NocturneButton { Layout.fillWidth: true; text: "WORLD CLOCKS"; onClicked: root.openSurface("world", "") }
                    NocturneButton { Layout.fillWidth: true; text: "CALENDAR"; onClicked: root.openSurface("calendar", "") }
                }
            }
        }
    }

    component SettingsPage: Rectangle {
        required property string title
        required property string description
        required property var actions
        color: backend.baseColor
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 22
            spacing: 10
            Text { text: parent.parent.title; color: backend.textColor; font.family: "monospace"; font.pixelSize: 25; font.bold: true }
            Text {
                Layout.fillWidth: true
                text: parent.parent.description
                wrapMode: Text.WordWrap
                color: backend.mutedColor
                font.family: "Inter"
                font.pixelSize: 11
            }
            Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: backend.lineColor }
            Repeater {
                model: parent.parent.actions
                delegate: Rectangle {
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: 68
                    color: backend.surfaceColor
                    border.color: backend.lineColor
                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            Text { text: modelData.label; color: backend.textColor; font.family: "monospace"; font.bold: true; font.pixelSize: 12 }
                            Text { Layout.fillWidth: true; text: modelData.detail; color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 10; wrapMode: Text.WordWrap }
                        }
                        NocturneButton {
                            text: modelData.button
                            selected: true
                            onClicked: {
                                if (modelData.surface) root.openSurface(modelData.surface, modelData.page || "")
                                else if (modelData.command === "keys") backend.start([backend.home + "/.config/hypr/scripts/help"])
                                else if (modelData.command === "lock") backend.start([backend.home + "/.config/hypr/scripts/lock-screen"])
                                else if (modelData.command === "doctor") backend.start(["kitty", "--class", "nocturne-doctor", "-e", backend.home + "/.local/bin/nocturne-doctor"])
                                else if (modelData.command === "source") backend.start(["xdg-open", "https://github.com/justneeraj12/nocturne-hyprland"])
                            }
                        }
                    }
                }
            }
            Item { Layout.fillHeight: true }
        }
    }
}
