import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "components"
import "pages"

ApplicationWindow {
    id: root
    visible: true
    width: 860
    height: 600
    minimumWidth: 720
    minimumHeight: 500
    title: "System Settings // Nocturne"
    color: backend.baseColor
    readonly property var sectionKeys: ["appearance", "connectivity", "sound", "input", "system", "workflow", "scenes", "privacy", "power", "setup", "about"]
    property int section: Math.max(0, sectionKeys.indexOf(backend.page || "appearance"))

    function openSurface(surface, page) {
        var args = [backend.home + "/.local/bin/nocturne-native", surface]
        if (page) args.push(page)
        backend.start(args)
    }
    Connections {
        target: backend
        function onPageChanged() {
            var next = root.sectionKeys.indexOf(backend.page)
            if (next >= 0) root.section = next
        }
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
            Layout.preferredWidth: 196
            color: "#090d0e"
            border.color: backend.lineColor
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 5
                SectionLabel { text: "CONTROL GROUPS" }
                Repeater {
                    model: ["APPEARANCE", "CONNECTIVITY", "SOUND + DISPLAY", "INPUT + DEFAULTS", "SYSTEM + ACCOUNTS", "WORKFLOW", "SCENES + AUTOMATION", "PRIVACY + GAMING", "POWER + SESSION", "SETUP + RECOVERY", "ABOUT"]
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
                SectionLabel { text: "NOCTURNE CORE" }
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
                    {label:"BRIGHTNESS + NIGHT SHIFT", detail:"Hardware-synced brightness plus scheduled native color temperature.", button:"OPEN", surface:"brightness"},
                    {label:"DISPLAY LAYOUT", detail:"Scale, rotate, mirror, extend and persist every connected monitor.", button:"OPEN", surface:"display"}
                ]
            }
            SystemSettingsPage { active: root.section === 3 }
            IntegrationsPage { active: root.section === 4 }
            SettingsPage {
                title: "WORKFLOW"
                description: "The command center searches applications, running windows and safe desktop actions from one keyboard-first surface."
                actions: [
                    {label:"FOCUS TIMER", detail:"Pomodoro presets, pause, skip and cycle progress.", button:"OPEN", surface:"pomodoro"},
                    {label:"SCREENSHOT", detail:"Select an area with the stable upstream Hyprshot utility.", button:"CAPTURE", command:"screenshot"},
                    {label:"SCREEN RECORDER", detail:"Open Kooha for area or display recording with desktop and microphone audio.", button:"OPEN", command:"recorder"},
                    {label:"KEY GUIDE", detail:"Open the complete shortcut reference in a terminal.", button:"SHOW", command:"keys"}
                ]
            }
            SettingsPage {
                title: "SCENES + AUTOMATION"
                description: "Save complete working contexts, restore them on demand, or apply only safe settings when your dock or power state changes."
                actions: [
                    {label:"WORKSPACE OVERVIEW", detail:"See all nine workspaces, focus windows, close them or drag them between workspaces.", button:"OPEN", surface:"overview"},
                    {label:"SESSION + AUDIO SCENES", detail:"Save applications, layouts, monitors, wallpaper, power and audio routing.", button:"MANAGE", surface:"scenes"},
                    {label:"CONTEXT ENGINE", detail:"Assign scenes to docked, mobile, AC and battery states without automatic app launches.", button:"CONFIGURE", surface:"scenes"}
                ]
            }
            SettingsPage {
                title: "PRIVACY + GAMING"
                description: "Live inspection is intentionally sampled only while its dashboard is open; background automation remains event-driven."
                actions: [
                    {label:"PRIVACY DASHBOARD", detail:"Identify applications using your microphone or camera and stop a suspicious client.", button:"INSPECT", surface:"privacy"},
                    {label:"GAMING DASHBOARD", detail:"GPU telemetry, reversible automatic game mode and optional MangoHud.", button:"OPEN", surface:"gaming"},
                    {label:"NOTIFICATION CONTROL", detail:"Focus modes, grouped history and per-application timed muting.", button:"OPEN", surface:"notifications"}
                ]
            }
            SettingsPage {
                title: "POWER + SESSION"
                description: "Profiles are backed by power-profiles-daemon; gaming sessions can apply performance, focus and caffeine automatically with rollback."
                actions: [
                    {label:"POWER + GAMING", detail:"Profiles plus automatic Steam game detection and exact state rollback.", button:"OPEN", surface:"power"},
                    {label:"SYSTEM MAINTENANCE", detail:"System packages, Flatpaks, firmware and failed-service health.", button:"OPEN", surface:"maintenance"},
                    {label:"LOCK", detail:"Lock now using the themed Hyprlock session.", button:"LOCK", command:"lock"}
                ]
            }
            SetupPage {}
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

    component SetupPage: Rectangle {
        id: setup
        color: backend.baseColor
        property var hardware: ({current:"unconfigured", recommended:"desktop", battery:false, bluetooth:false, displays:0})
        property var backup: ({latest:"", exists:false})
        property var recovery: ({exists:false,size:0,modified:"",failures:0})
        property bool confirmRestore: false
        readonly property string profileHelper: backend.home + "/.config/hypr/scripts/setup-profile"
        readonly property string portable: backend.home + "/.local/bin/nocturne-portable"

        function refresh() {
            hardware = backend.json([profileHelper, "status"], 2500) || hardware
            backup = backend.json([portable, "status"], 2500) || backup
            recovery = backend.json([backend.home + "/.local/bin/nocturne-recovery", "status"], 2500) || recovery
        }
        function applyProfile(name) {
            backend.start([profileHelper, "apply", name])
            refreshDelay.restart()
        }

        ColumnLayout {
            anchors.fill: parent; anchors.margins: 22; spacing: 10
            Text { text: "SETUP + RECOVERY"; color: backend.textColor; font.family: "monospace"; font.pixelSize: 25; font.bold: true }
            Text {
                Layout.fillWidth: true
                text: "Hardware-aware profiles and portable preferences. Profiles change only optional background services; the shell workflow stays intact."
                wrapMode: Text.WordWrap; color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 11
            }
            SectionLabel { text: "DETECTED HARDWARE" }
            Rectangle {
                Layout.fillWidth: true; implicitHeight: 60; color: backend.surfaceColor; border.color: backend.lineColor
                RowLayout {
                    anchors.fill: parent; anchors.margins: 9
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 2
                        Text { text: setup.hardware.displays + " DISPLAY" + (setup.hardware.displays === 1 ? "" : "S") + "  ·  " + (setup.hardware.battery ? "BATTERY" : "DESKTOP") + "  ·  " + (setup.hardware.bluetooth ? "BLUETOOTH" : "NO BLUETOOTH"); color: backend.textColor; font.family: "monospace"; font.bold: true; font.pixelSize: 10 }
                        Text { text: "Current: " + setup.hardware.current.toUpperCase() + "  ·  Recommended: " + setup.hardware.recommended.toUpperCase(); color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 9 }
                    }
                    NocturneButton { text: "RECHECK"; onClicked: setup.refresh() }
                }
            }
            SectionLabel { text: "USAGE PROFILE" }
            RowLayout {
                Layout.fillWidth: true; spacing: 5
                Repeater {
                    model: [
                        {key:"minimal", label:"MINIMAL", detail:"Core shell only"},
                        {key:"desktop", label:"DESKTOP", detail:"Visuals + EQ"},
                        {key:"laptop", label:"LAPTOP", detail:"All hardware helpers"}
                    ]
                    NocturneButton {
                        required property var modelData
                        Layout.fillWidth: true; text: modelData.label
                        selected: setup.hardware.current === modelData.key
                        onClicked: setup.applyProfile(modelData.key)
                        ToolTip.visible: hovered; ToolTip.text: modelData.detail
                    }
                }
            }
            SectionLabel { text: "PORTABLE CONFIGURATION" }
            Rectangle {
                Layout.fillWidth: true; implicitHeight: 66; color: backend.surfaceColor; border.color: backend.lineColor
                RowLayout {
                    anchors.fill: parent; anchors.margins: 9
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 2
                        Text { text: setup.backup.exists ? "LATEST BACKUP READY" : "NO PORTABLE BACKUP YET"; color: backend.textColor; font.family: "monospace"; font.bold: true; font.pixelSize: 10 }
                        Text { Layout.fillWidth: true; text: setup.backup.exists ? setup.backup.latest : "Saved under ~/Documents/Nocturne-Backups"; color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 9; elide: Text.ElideMiddle }
                    }
                }
            }
            RowLayout {
                Layout.fillWidth: true; spacing: 5
                NocturneButton {
                    Layout.fillWidth: true; text: "EXPORT CONFIG"; selected: true
                    onClicked: { backend.run([setup.portable, "export"], 15000); setup.refresh() }
                }
                NocturneButton {
                    Layout.fillWidth: true
                    text: setup.confirmRestore ? "CONFIRM RESTORE" : "RESTORE LATEST"
                    danger: setup.confirmRestore; enabled: setup.backup.exists
                    onClicked: {
                        if (!setup.confirmRestore) setup.confirmRestore = true
                        else { backend.run([setup.portable, "restore-latest"], 15000); setup.confirmRestore = false; setup.refresh() }
                    }
                }
                NocturneButton { text: "OPEN FOLDER"; onClicked: backend.start(["pcmanfm-qt", backend.home + "/Documents/Nocturne-Backups"]) }
            }
            Text {
                Layout.fillWidth: true
                text: "Bundles contain Nocturne preferences and monitor layout—not passwords, Wi-Fi credentials, browser data or wallpapers."
                color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 9; wrapMode: Text.WordWrap
            }
            SectionLabel { text: "LAST-KNOWN-GOOD RECOVERY" }
            RowLayout {
                Layout.fillWidth: true; spacing: 5
                Text {
                    Layout.fillWidth: true
                    text: setup.recovery.exists ? "CHECKPOINT READY · " + Math.round(setup.recovery.size / 1024 / 1024) + " MiB" : "NO RECOVERY CHECKPOINT"
                    color: setup.recovery.exists ? backend.accentColor : backend.mutedColor; font.family: "monospace"; font.pixelSize: 9
                }
                NocturneButton { text: "CHECKPOINT"; onClicked: { backend.run([backend.home + "/.local/bin/nocturne-recovery", "checkpoint"], 20000); setup.refresh() } }
                NocturneButton { text: "RESTORE"; danger: true; enabled: setup.recovery.exists; onClicked: { backend.run([backend.home + "/.local/bin/nocturne-recovery", "restore"], 20000); setup.refresh() } }
            }
            Item { Layout.fillHeight: true }
        }
        Timer { id: refreshDelay; interval: 900; onTriggered: setup.refresh() }
        Component.onCompleted: refresh()
    }

    component AppearancePage: Rectangle {
        id: appearance
        color: backend.baseColor
        property var images: backend.wallpapers()
        property var studio: ({preview:false,themes:[]})
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
            backend.run([backend.home + "/.config/hypr/scripts/theme-studio", "preview", name, "-"], 12000)
            backend.refreshTheme(); refreshStudio()
        }
        function applyAccent(name) {
            backend.run([backend.home + "/.config/hypr/scripts/theme-studio", "preview", "-", name], 12000)
            backend.refreshTheme(); refreshStudio()
        }
        function refreshStudio() { studio = backend.json([backend.home + "/.config/hypr/scripts/theme-studio", "status"], 1800) || studio }
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
                Rectangle {
                    Layout.fillWidth: true; implicitHeight: 45; visible: appearance.studio.preview
                    color: backend.overlayColor; border.color: backend.accentColor
                    RowLayout { anchors.fill: parent; anchors.margins: 7
                        Text { Layout.fillWidth: true; text: "30-SECOND THEME PREVIEW"; color: backend.textColor; font.family: "monospace"; font.bold: true; font.pixelSize: 9 }
                        NocturneButton { text: "KEEP"; selected: true; onClicked: { backend.run([backend.home + "/.config/hypr/scripts/theme-studio", "keep"]); appearance.refreshStudio() } }
                        NocturneButton { text: "REVERT"; danger: true; onClicked: { backend.run([backend.home + "/.config/hypr/scripts/theme-studio", "rollback"]); backend.refreshTheme(); appearance.refreshStudio() } }
                    }
                }
                SectionLabel { text: "THEME STUDIO" }
                RowLayout {
                    Layout.fillWidth: true
                    TextField { id: customThemeName; Layout.fillWidth: true; placeholderText: "Custom theme name"; color: backend.textColor; font.family: "monospace"; background: Rectangle { color: backend.surfaceColor; border.color: customThemeName.activeFocus ? backend.accentColor : backend.lineColor } }
                    NocturneButton { text: "DERIVE FROM WALLPAPER"; enabled: appearance.current.length > 0; onClicked: { backend.run([backend.home + "/.config/hypr/scripts/theme-studio", "derive", appearance.current], 12000); backend.refreshTheme(); appearance.refreshStudio() } }
                    NocturneButton { text: "SAVE"; selected: true; enabled: customThemeName.text.trim().length > 0; onClicked: { backend.run([backend.home + "/.config/hypr/scripts/theme-studio", "save", customThemeName.text]); customThemeName.clear(); appearance.refreshStudio() } }
                }
                Flow {
                    Layout.fillWidth: true; Layout.preferredHeight: childrenRect.height; spacing: 5
                    Repeater { model: appearance.studio.themes || []; NocturneButton { required property var modelData; text: modelData.name.toUpperCase(); onClicked: { backend.run([backend.home + "/.config/hypr/scripts/theme-studio", "apply", modelData.name], 12000); backend.refreshTheme(); appearance.refreshStudio() } } }
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
        Component.onCompleted: refreshStudio()
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
                                else if (modelData.command === "screenshot") backend.start([backend.home + "/.local/bin/hyprshot", "-m", "region", "-o", backend.home + "/Pictures/Screenshots"])
                                else if (modelData.command === "recorder") backend.start(["flatpak", "run", "io.github.seadve.Kooha"])
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
