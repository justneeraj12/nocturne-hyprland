import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "components"
import "pages"

ApplicationWindow {
    id: root
    visible: true
    width: 1040
    height: 720
    minimumWidth: 780
    minimumHeight: 560
    title: "Settings // Nocturne"
    color: backend.baseColor

    property bool navExpanded: width >= 920
    property bool initialized: false
    property int section: 0
    property var filteredNavigation: []
    readonly property string statePath: backend.home + "/.config/nocturne/settings-last-page"
    readonly property var navigation: [
        {key:"overview", label:"Overview", group:"HOME", icon:"go-home", glyph:"⌂", keywords:"status health dashboard machine"},
        {key:"appearance", label:"Appearance", group:"HOME", icon:"preferences-desktop-theme", glyph:"◈", keywords:"wallpaper theme color accent day cycle"},
        {key:"bar", label:"Bar Studio", group:"HOME", icon:"video-display", glyph:"▤", keywords:"status bar modules density icons displays layout"},
        {key:"connectivity", label:"Connectivity", group:"DEVICES", icon:"network-wireless", glyph:"⌁", keywords:"wifi bluetooth vpn network internet"},
        {key:"sound", label:"Sound & displays", group:"DEVICES", icon:"audio-volume-high", glyph:"♪", keywords:"audio volume mixer brightness monitor night shift"},
        {key:"input", label:"Input & defaults", group:"DEVICES", icon:"input-keyboard", glyph:"⌨", keywords:"keyboard mouse touchpad default apps time timezone"},
        {key:"system", label:"System & accounts", group:"SYSTEM", icon:"computer", glyph:"▣", keywords:"google account hardware integration portal phone"},
        {key:"workflow", label:"Workflow", group:"SYSTEM", icon:"system-run", glyph:"↯", keywords:"pomodoro screenshot recorder shortcuts"},
        {key:"automation", label:"Scenes & automation", group:"SYSTEM", icon:"view-calendar-timeline", glyph:"◎", keywords:"workspace scenes context dock automation"},
        {key:"privacy", label:"Privacy & gaming", group:"SYSTEM", icon:"security-high", glyph:"◉", keywords:"microphone camera gpu steam notification"},
        {key:"efficiency", label:"Efficiency", group:"SYSTEM", icon:"utilities-system-monitor", glyph:"≋", keywords:"memory ram cpu startup resources optimize cleanup performance"},
        {key:"power", label:"Power & session", group:"SYSTEM", icon:"battery", glyph:"⚡", keywords:"performance balanced saver maintenance lock"},
        {key:"setup", label:"Setup & recovery", group:"RECOVERY", icon:"document-save", glyph:"↶", keywords:"backup restore checkpoint profile portable"},
        {key:"about", label:"About", group:"RECOVERY", icon:"help-about", glyph:"?", keywords:"version github source doctor diagnostics"}
    ]

    function indexForKey(key) {
        for (var i = 0; i < navigation.length; ++i) if (navigation[i].key === key) return i
        return 0
    }
    function selectSection(key) { section = indexForKey(key); search.clear() }
    function revealSelectedSection() {
        if (!navRepeater || !navFlick) return
        var item = navRepeater.itemAt(section)
        if (!item) return
        var top = item.y
        var bottom = top + item.height
        if (top < navFlick.contentY) navFlick.contentY = Math.max(0, top - 4)
        else if (bottom > navFlick.contentY + navFlick.height)
            navFlick.contentY = Math.min(navFlick.contentHeight - navFlick.height, bottom - navFlick.height + 4)
    }
    function refreshSearch() {
        var query = search.text.trim().toLowerCase()
        if (!query) { filteredNavigation = []; return }
        var matches = []
        for (var i = 0; i < navigation.length; ++i) {
            var item = navigation[i]
            if ((item.label + " " + item.group + " " + item.keywords).toLowerCase().indexOf(query) >= 0) matches.push(item)
        }
        filteredNavigation = matches
    }
    function applyBackendPage() {
        var requested = backend.page || ""
        if (requested) section = indexForKey(requested)
    }
    function restoreSection() {
        var requested = backend.page || ""
        if (requested) section = indexForKey(requested)
        else {
            var saved = backend.readText(root.statePath).trim()
            if (saved) section = indexForKey(saved)
        }
        initialized = true
    }
    Connections { target: backend; function onPageChanged() { root.applyBackendPage() } }
    Timer { id: navRevealTimer; interval: 100; onTriggered: root.revealSelectedSection() }
    Component.onCompleted: { restoreSection(); navRevealTimer.restart() }
    onSectionChanged: {
        navRevealTimer.restart()
        if (initialized && section >= 0 && section < navigation.length)
            backend.writeText(statePath, navigation[section].key + "\n")
    }

    Shortcut { sequence: "Ctrl+K"; onActivated: search.forceActiveFocus() }
    Shortcut { sequence: "Ctrl+F"; onActivated: search.forceActiveFocus() }
    Shortcut { sequence: "Alt+Down"; onActivated: root.section = (root.section + 1) % root.navigation.length }
    Shortcut { sequence: "Alt+Up"; onActivated: root.section = (root.section + root.navigation.length - 1) % root.navigation.length }
    Shortcut { sequence: "Alt+Right"; onActivated: root.section = (root.section + 1) % root.navigation.length }
    Shortcut { sequence: "Alt+Left"; onActivated: root.section = (root.section + root.navigation.length - 1) % root.navigation.length }
    Shortcut { sequence: "Ctrl+Home"; onActivated: root.section = 0 }
    Shortcut { sequence: "Ctrl+End"; onActivated: root.section = root.navigation.length - 1 }
    Shortcut { sequence: "Ctrl+B"; onActivated: root.navExpanded = !root.navExpanded }
    Shortcut { sequence: "Ctrl+0"; onActivated: root.selectSection("overview") }
    Shortcut { sequence: "Escape"; onActivated: { if (search.text !== "") search.clear(); else root.close() } }

    readonly property var pageComponents: [
        overviewPage, appearancePage, barPage, connectivityPage, soundPage,
        inputPage, systemPage, workflowPage, automationPage, privacyPage,
        efficiencyPage, powerPage, setupPage, aboutPage
    ]
    Component { id: overviewPage; OverviewSettingsPage { active: true; onSectionRequested: function(key) { root.selectSection(key) } } }
    Component { id: appearancePage; AppearanceSettingsPage { active: true } }
    Component { id: barPage; BarSettingsPage { active: true } }
    Component { id: connectivityPage; SettingsActionsPage {
        pageEyebrow: "DEVICES"; pageTitle: "Connectivity"
        pageDescription: "Wi-Fi, Bluetooth and VPN use the standard Linux backends with one compact Nocturne interface."
        pageBadge: "NETWORKMANAGER + BLUEZ"
        actions: [
            {icon:"network-wireless",glyph:"⌁",label:"Wi-Fi",detail:"Networks, signal, connection state and live throughput.",button:"MANAGE",surface:"connectivity",page:"wifi"},
            {icon:"preferences-system-bluetooth",glyph:"ᛒ",label:"Bluetooth",detail:"Radio state, discovered devices and active connections.",button:"MANAGE",surface:"connectivity",page:"bluetooth"},
            {icon:"network-vpn",glyph:"◇",label:"VPN",detail:"Start and stop saved NetworkManager VPN profiles.",button:"MANAGE",surface:"connectivity",page:"vpn"}
        ]
    } }
    Component { id: soundPage; SettingsActionsPage {
        pageEyebrow: "HARDWARE"; pageTitle: "Sound & displays"
        pageDescription: "Live PipeWire routing, hardware-synced brightness and persistent monitor layouts."
        pageBadge: "LIVE HARDWARE STATE"
        actions: [
            {icon:"audio-volume-high",glyph:"♪",label:"Output & app mixer",detail:"Master volume, device routing and every active audio stream.",button:"OPEN",surface:"audio"},
            {icon:"display-brightness",glyph:"☼",label:"Brightness & night shift",detail:"Backlight control plus scheduled native color temperature.",button:"OPEN",surface:"brightness"},
            {icon:"camera-web",glyph:"󰄀",label:"Camera quality",detail:"Zero-idle hardware exposure, white balance, anti-flicker and low-light profiles.",button:"TUNE",surface:"camera"},
            {icon:"video-display",glyph:"▣",label:"Display layout",detail:"Scale, rotate, mirror, extend and save connected monitors.",button:"OPEN",surface:"display"}
        ]
    } }
    Component { id: inputPage; SystemSettingsPage { active: true } }
    Component { id: systemPage; IntegrationsPage { active: true } }
    Component { id: workflowPage; SettingsActionsPage {
        pageEyebrow: "DAILY USE"; pageTitle: "Workflow"
        pageDescription: "Focused tools for work, capture and keyboard-first navigation."
        actions: [
            {icon:"chronometer",glyph:"◷",label:"Focus timer",detail:"Pomodoro presets, pause, skip and cycle progress.",button:"OPEN",surface:"pomodoro"},
            {icon:"spectacle",glyph:"⌗",label:"Screenshot",detail:"Capture an area with Hyprshot and copy it to the clipboard.",button:"CAPTURE",command:"screenshot"},
            {icon:"media-record",glyph:"●",label:"Screen recorder",detail:"Record an area or display with desktop and microphone audio.",button:"OPEN",command:"recorder"},
            {icon:"input-keyboard",glyph:"⌨",label:"Shortcut guide",detail:"Open the complete keyboard and mouse reference.",button:"SHOW",command:"keys"}
        ]
    } }
    Component { id: automationPage; SettingsActionsPage {
        pageEyebrow: "CONTEXT"; pageTitle: "Scenes & automation"
        pageDescription: "Save complete working contexts or safely react to dock and power changes without launching apps unexpectedly."
        actions: [
            {icon:"view-grid",glyph:"▦",label:"Workspace overview",detail:"Inspect all workspaces and move, focus or close windows.",button:"OPEN",surface:"overview"},
            {icon:"document-save",glyph:"◫",label:"Session & audio scenes",detail:"Save applications, monitor layout, wallpaper, power and routing.",button:"MANAGE",surface:"scenes"},
            {icon:"preferences-system-time",glyph:"◎",label:"Context engine",detail:"Assign settings-only scenes to docked, mobile, AC and battery states.",button:"CONFIGURE",surface:"scenes"},
            {icon:"view-history",glyph:"↶",label:"Nocturne Trace",detail:"See why the desktop adapted, inspect its private decision history and reverse automatic settings.",button:"EXPLAIN",surface:"automation"}
        ]
    } }
    Component { id: privacyPage; SettingsActionsPage {
        pageEyebrow: "VISIBILITY + PERFORMANCE"; pageTitle: "Privacy & gaming"
        pageDescription: "Inspect live privacy clients and GPU behavior only when the dashboard is open."
        actions: [
            {icon:"security-high",glyph:"◉",label:"Privacy dashboard",detail:"Identify apps using the microphone or camera and stop a client.",button:"INSPECT",surface:"privacy"},
            {icon:"applications-games",glyph:"◆",label:"Gaming dashboard",detail:"GPU telemetry, automatic rollback and optional MangoHud.",button:"OPEN",surface:"gaming"},
            {icon:"preferences-desktop-notification",glyph:"◌",label:"Notification control",detail:"Focus modes, grouped history and timed app muting.",button:"OPEN",surface:"notifications"}
        ]
    } }
    Component { id: efficiencyPage; EfficiencySettingsPage { active: true } }
    Component { id: powerPage; SettingsActionsPage {
        pageEyebrow: "ENERGY + SESSION"; pageTitle: "Power & session"
        pageDescription: "Hardware power profiles, reversible gaming boosts and guarded session actions."
        pageBadge: "DEEP SLEEP ENABLED"
        actions: [
            {icon:"battery",glyph:"⚡",label:"Power & gaming",detail:"Performance profiles and automatic Steam game detection.",button:"OPEN",surface:"power"},
            {icon:"system-software-update",glyph:"↻",label:"System maintenance",detail:"System packages, Flatpaks, firmware and failed-service health.",button:"OPEN",surface:"maintenance"},
            {icon:"system-lock-screen",glyph:"■",label:"Lock this session",detail:"Lock immediately with the themed Hyprlock session.",button:"LOCK",command:"lock",danger:true}
        ]
    } }
    Component { id: setupPage; SetupSettingsPage { active: true } }
    Component { id: aboutPage; SettingsActionsPage {
        pageEyebrow: "NOCTURNE 0.8.0"; pageTitle: "About"
        pageDescription: "A coherent Hyprland desktop layer built from standard, replaceable Linux services—with a recovery path."
        pageBadge: "OPEN SOURCE"
        actions: [
            {icon:"dialog-ok",glyph:"✓",label:"System check",detail:"Run the complete read-only Nocturne diagnostics.",button:"RUN",command:"doctor"},
            {icon:"document-send",glyph:"⇧",label:"Private support report",detail:"Generate a small diagnostics archive without configs, logs, SSIDs, clipboard or personal files.",button:"CREATE",command:"support"},
            {icon:"applications-development",glyph:"<>",label:"Source & documentation",detail:"Configuration, native shell, installer and validation pipeline.",button:"GITHUB",command:"source"}
        ]
    } }

    header: Rectangle {
        implicitHeight: 56
        color: backend.surfaceColor
        border.color: backend.lineColor
        RowLayout {
            anchors.fill: parent
            spacing: 0
            Item {
                Layout.preferredWidth: root.navExpanded ? 214 : 60
                Layout.fillHeight: true
                Behavior on Layout.preferredWidth { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 13
                    anchors.rightMargin: 10
                    spacing: 9
                    Rectangle {
                        implicitWidth: 29; implicitHeight: 29
                        color: backend.baseColor; border.color: backend.accent2Color
                        Text { anchors.centerIn: parent; text: "N"; color: backend.accentColor; font.family: "monospace"; font.pixelSize: 14; font.bold: true }
                    }
                    ColumnLayout {
                        visible: root.navExpanded
                        Layout.fillWidth: true; spacing: 0
                        Text { text: "NOCTURNE"; color: backend.textColor; font.family: "Inter"; font.pixelSize: 11; font.bold: true; font.letterSpacing: 1.1 }
                        Text { text: "SYSTEM SETTINGS"; color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 7; font.letterSpacing: 0.8 }
                    }
                }
            }
            Rectangle { Layout.preferredWidth: 1; Layout.fillHeight: true; color: backend.lineColor }
            RowLayout {
                Layout.fillWidth: true; Layout.fillHeight: true
                Layout.leftMargin: 17; Layout.rightMargin: 14; spacing: 12
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 0
                    Text { text: "SETTINGS"; color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 8; font.bold: true; font.letterSpacing: 1.2 }
                    Text { text: root.navigation[root.section].label; color: backend.textColor; font.family: "Inter"; font.pixelSize: 11; font.bold: true }
                }
                TextField {
                    id: search
                    Layout.preferredWidth: Math.min(300, Math.max(200, root.width * 0.28))
                    implicitHeight: 34
                    placeholderText: "Search settings   Ctrl+K"
                    color: backend.textColor; placeholderTextColor: backend.mutedColor
                    font.family: "Inter"; font.pixelSize: 10
                    leftPadding: 34; rightPadding: search.text === "" ? 10 : 34
                    onTextChanged: root.refreshSearch()
                    background: Rectangle {
                        color: backend.baseColor
                        border.color: search.activeFocus ? backend.accentColor : backend.lineColor
                        Text { anchors.left: parent.left; anchors.leftMargin: 11; anchors.verticalCenter: parent.verticalCenter; text: "⌕"; color: backend.mutedColor; font.family: "MesloLGS Nerd Font Mono"; font.pixelSize: 14 }
                    }
                    Text {
                        visible: search.text !== ""
                        anchors.right: parent.right; anchors.rightMargin: 11; anchors.verticalCenter: parent.verticalCenter
                        text: "×"; color: clearSearch.containsMouse ? backend.accentColor : backend.mutedColor
                        font.family: "Inter"; font.pixelSize: 14
                        MouseArea { id: clearSearch; anchors.fill: parent; anchors.margins: -8; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { search.clear(); search.forceActiveFocus() } }
                    }
                }
                Rectangle {
                    implicitWidth: liveLabel.implicitWidth + 18; implicitHeight: 27
                    color: backend.baseColor; border.color: backend.lineColor
                    Row {
                        anchors.centerIn: parent; spacing: 6
                        Rectangle { width: 5; height: 5; radius: 3; color: backend.accentColor; anchors.verticalCenter: parent.verticalCenter }
                        Text { id: liveLabel; text: "WAYLAND"; color: backend.mutedColor; font.family: "monospace"; font.pixelSize: 8; font.bold: true }
                    }
                }
            }
        }
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0
        Rectangle {
            Layout.preferredWidth: root.navExpanded ? 214 : 60
            Layout.fillHeight: true
            color: "#080b0c"; border.color: backend.lineColor; clip: true
            Behavior on Layout.preferredWidth { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
            ColumnLayout {
                anchors.fill: parent
                anchors.topMargin: 9; anchors.bottomMargin: 9
                spacing: 0
                Flickable {
                    id: navFlick
                    Layout.fillWidth: true; Layout.fillHeight: true
                    contentHeight: navColumn.implicitHeight
                    clip: true; boundsBehavior: Flickable.StopAtBounds
                    ColumnLayout {
                        id: navColumn
                        x: 8; width: parent.width - 16; spacing: 3
                        Repeater {
                            id: navRepeater
                            model: root.navigation
                            Item {
                                required property int index
                                required property var modelData
                                Layout.fillWidth: true
                                implicitHeight: navItem.implicitHeight + (index === 0 || root.navigation[index - 1].group !== modelData.group ? (root.navExpanded ? 26 : 11) : 0)
                                Text {
                                    visible: root.navExpanded && (index === 0 || root.navigation[index - 1].group !== modelData.group)
                                    anchors.left: parent.left; anchors.leftMargin: 8; anchors.top: parent.top
                                    text: modelData.group; color: backend.mutedColor
                                    font.family: "Inter"; font.pixelSize: 7; font.bold: true; font.letterSpacing: 1.2
                                }
                                Rectangle {
                                    visible: !root.navExpanded && index > 0 && root.navigation[index - 1].group !== modelData.group
                                    anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                                    height: 1; color: backend.lineColor
                                }
                                SettingsNavItem {
                                    id: navItem
                                    anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
                                    iconName: modelData.icon; glyph: modelData.glyph; label: modelData.label; expanded: root.navExpanded
                                    selected: root.section === index && search.text === ""
                                    onClicked: { root.section = index; search.clear() }
                                }
                            }
                        }
                    }
                }
                Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: backend.lineColor }
                Button {
                    Layout.fillWidth: true; Layout.leftMargin: 8; Layout.rightMargin: 8
                    implicitHeight: 38; hoverEnabled: true
                    onClicked: root.navExpanded = !root.navExpanded
                    Accessible.name: root.navExpanded ? "Collapse settings sidebar" : "Expand settings sidebar"
                    contentItem: RowLayout {
                        spacing: 11
                        Text { Layout.preferredWidth: 18; text: root.navExpanded ? "‹" : "›"; color: backend.accentColor; font.family: "Inter"; font.pixelSize: 20; horizontalAlignment: Text.AlignHCenter }
                        Text { visible: root.navExpanded; Layout.fillWidth: true; text: "COLLAPSE SIDEBAR"; color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 8; font.bold: true }
                    }
                    background: Rectangle { color: parent.hovered ? backend.surfaceColor : "transparent"; border.color: parent.hovered ? backend.lineColor : "transparent" }
                    ToolTip.visible: !root.navExpanded && hovered; ToolTip.text: "Expand sidebar"
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true; Layout.fillHeight: true; color: backend.baseColor
            Loader {
                anchors.fill: parent
                visible: search.text === ""
                asynchronous: true
                sourceComponent: root.pageComponents[root.section]
            }
            Rectangle {
                anchors.fill: parent; visible: search.text !== ""; color: backend.baseColor
                ColumnLayout {
                    anchors.fill: parent; anchors.margins: 26; spacing: 12
                    SettingsPageHeader {
                        Layout.fillWidth: true; eyebrow: "SEARCH"
                        title: root.filteredNavigation.length + (root.filteredNavigation.length === 1 ? " result" : " results")
                        description: "Settings matching “" + search.text + "”"
                    }
                    ListView {
                        Layout.fillWidth: true; Layout.fillHeight: true; clip: true; spacing: 8
                        model: root.filteredNavigation
                        delegate: SettingsAction {
                            required property var modelData
                            width: ListView.view.width
                            iconName: modelData.icon; glyph: modelData.glyph; title: modelData.label
                            description: modelData.group + " · " + modelData.keywords
                            actionText: "GO"
                            onClicked: root.selectSection(modelData.key)
                        }
                        Text {
                            anchors.centerIn: parent; visible: root.filteredNavigation.length === 0
                            text: "No setting matches this search"; color: backend.mutedColor
                            font.family: "Inter"; font.pixelSize: 11
                        }
                    }
                }
            }
        }
    }
}
