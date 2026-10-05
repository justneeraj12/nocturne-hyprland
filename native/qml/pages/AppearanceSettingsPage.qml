import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"

Rectangle {
    id: root
    color: backend.baseColor
    property bool active: false
    property var images: []
    property var studio: ({preview:false,remaining:0,themes:[]})
    property var wallpaperState: ({enabled:false,current:"",source:"",mode:"day-cycle",monitors:[],mapped_monitors:[]})
    property string selectedWallpaper: wallpaperState.current || ""
    property string selectedAccent: ""
    readonly property string wallpaperTool: backend.home + "/.local/bin/nocturne-wallpaper-cycle"
    readonly property string themeTool: backend.home + "/.config/hypr/scripts/theme-studio"
    readonly property var accents: [
        {name:"Green", color:"#5f8f76"}, {name:"Teal", color:"#3f9b91"},
        {name:"Cyan", color:"#42a5b3"}, {name:"Ice", color:"#8abac7"},
        {name:"Slate", color:"#70828d"}, {name:"Blue", color:"#5687b8"},
        {name:"Indigo", color:"#6f78b8"}, {name:"Purple", color:"#8b6fb5"},
        {name:"Magenta", color:"#b3669a"}, {name:"Pink", color:"#c47799"},
        {name:"Red", color:"#b95f68"}, {name:"Rose", color:"#c8787f"},
        {name:"Orange", color:"#bd7b50"}, {name:"Amber", color:"#c29852"},
        {name:"Yellow", color:"#b9ad63"}, {name:"Lime", color:"#88a85a"}
    ]

    function baseName(path) {
        if (!path) return "No wallpaper selected"
        var pieces = path.split("/")
        return pieces[pieces.length - 1]
    }
    function refresh() {
        images = backend.wallpapers()
        wallpaperState = backend.json([wallpaperTool, "status"], 2500) || wallpaperState
        studio = backend.json([themeTool, "status"], 1800) || studio
        if (wallpaperState.current) selectedWallpaper = wallpaperState.current
    }
    function applyWallpaper(path) {
        if (!path) return
        backend.run([wallpaperTool, "disable"], 10000)
        backend.start([wallpaperTool, "apply-file", path])
        selectedWallpaper = path
        wallpaperRefresh.restart()
    }
    function applyDesign(name) {
        backend.run([themeTool, "preview", name, "-"], 12000)
        backend.refreshTheme()
        previewRefresh.restart()
    }
    function applyAccent(name) {
        selectedAccent = name
        backend.run([themeTool, "preview", "-", name], 12000)
        backend.refreshTheme()
        previewRefresh.restart()
    }

    ScrollView {
        anchors.fill: parent
        contentWidth: availableWidth
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        ColumnLayout {
            x: 26
            width: parent.width - 52
            spacing: 14
            Item { Layout.preferredHeight: 10 }
            SettingsPageHeader {
                Layout.fillWidth: true
                eyebrow: "PERSONALIZATION"
                title: "Appearance"
                description: "Wallpaper, day-cycle behavior and the shared Nocturne palette. Changes preview live and can be reverted before they become permanent."
                badge: wallpaperState.enabled ? "DAY CYCLE ON" : "STATIC"
            }

            SettingsCard {
                Layout.fillWidth: true
                title: "CURRENT WALLPAPER"
                description: "Preview and display state are separate from the wallpaper library."
                icon: "preferences-desktop-wallpaper"
                glyph: "▣"
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 13
                    Rectangle {
                        Layout.preferredWidth: Math.min(310, Math.max(220, root.width * 0.34))
                        Layout.preferredHeight: 164
                        color: backend.baseColor
                        border.color: backend.accent2Color
                        Image {
                            anchors.fill: parent
                            anchors.margins: 2
                            source: root.selectedWallpaper ? "file://" + root.selectedWallpaper : ""
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            cache: false
                        }
                        Text {
                            anchors.centerIn: parent
                            visible: !root.selectedWallpaper
                            text: "NO PREVIEW"
                            color: backend.mutedColor
                            font.family: "monospace"
                            font.pixelSize: 9
                        }
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 7
                        Text { Layout.fillWidth: true; text: root.baseName(root.selectedWallpaper); color: backend.textColor; font.family: "Inter"; font.pixelSize: 12; font.bold: true; elide: Text.ElideMiddle }
                        Text { Layout.fillWidth: true; text: (wallpaperState.mapped_monitors || []).length + " / " + (wallpaperState.monitors || []).length + " displays mapped"; color: backend.accentColor; font.family: "monospace"; font.pixelSize: 9 }
                        Text { Layout.fillWidth: true; text: wallpaperState.enabled ? "Follows the configured morning, afternoon, evening and night schedule." : "Pinned until you choose another wallpaper or enable the day cycle."; color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 9; wrapMode: Text.WordWrap }
                        Item { Layout.fillHeight: true }
                        RowLayout {
                            Layout.fillWidth: true
                            NocturneButton {
                                Layout.fillWidth: true
                                text: wallpaperState.enabled ? "DISABLE DAY CYCLE" : "ENABLE DAY CYCLE"
                                selected: wallpaperState.enabled
                                onClicked: {
                                    backend.run([root.wallpaperTool, wallpaperState.enabled ? "disable" : "enable"], 10000)
                                    wallpaperRefresh.restart()
                                }
                            }
                            NocturneButton { text: "OPEN LIBRARY"; onClicked: backend.start([backend.home + "/.local/bin/nocturne-files", backend.home + "/Pictures/Wallpapers"]) }
                        }
                    }
                }
            }

            SettingsCard {
                Layout.fillWidth: true
                title: "WALLPAPER LIBRARY"
                description: "Everything in ~/Pictures/Wallpapers and the installed Nocturne collections."
                icon: "folder-pictures"
                glyph: "▦"
                GridView {
                    id: wallpaperGrid
                    Layout.fillWidth: true
                    Layout.preferredHeight: 208
                    clip: true
                    cellWidth: width / Math.max(2, Math.floor(width / 156))
                    cellHeight: 96
                    model: root.images
                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                    delegate: Item {
                        required property var modelData
                        width: wallpaperGrid.cellWidth
                        height: wallpaperGrid.cellHeight
                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 4
                            color: backend.baseColor
                            border.width: root.selectedWallpaper === modelData.path ? 2 : 1
                            border.color: root.selectedWallpaper === modelData.path ? backend.accentColor : backend.lineColor
                            Image { anchors.fill: parent; anchors.margins: 2; source: "file://" + modelData.path; fillMode: Image.PreserveAspectCrop; asynchronous: true }
                            Rectangle {
                                anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
                                height: 21; color: "#cc07090a"
                                Text { anchors.fill: parent; anchors.margins: 5; text: root.baseName(modelData.path); color: backend.textColor; font.family: "Inter"; font.pixelSize: 8; elide: Text.ElideMiddle; verticalAlignment: Text.AlignVCenter }
                            }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.applyWallpaper(modelData.path) }
                        }
                    }
                }
            }

            SettingsCard {
                Layout.fillWidth: true
                title: "DESIGN PRESET"
                description: "Layout density, surfaces and borders. A preview automatically rolls back unless you keep it."
                icon: "preferences-desktop-theme"
                glyph: "◆"
                Flow {
                    Layout.fillWidth: true
                    spacing: 6
                    Repeater {
                        model: ["Obsidian Grid", "Carbon Compact", "Midnight Circuit", "Phosphor Terminal", "Crimson Relay", "Copper Blue", "Copper Deep Green", "Copper Deep Gold"]
                        NocturneButton { required property string modelData; text: modelData.toUpperCase(); onClicked: root.applyDesign(modelData) }
                    }
                }
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 43
                    visible: root.studio.preview
                    color: backend.baseColor
                    border.color: backend.accentColor
                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 7
                        Text { Layout.fillWidth: true; text: "LIVE PREVIEW · " + root.studio.remaining + "s remaining"; color: backend.textColor; font.family: "monospace"; font.pixelSize: 9; font.bold: true }
                        NocturneButton { text: "KEEP"; selected: true; onClicked: { backend.run([root.themeTool, "keep"]); root.refresh() } }
                        NocturneButton { text: "REVERT"; danger: true; onClicked: { backend.run([root.themeTool, "rollback"]); backend.refreshTheme(); root.refresh() } }
                    }
                }
            }

            SettingsCard {
                Layout.fillWidth: true
                title: "ACCENT COLOR"
                description: "Visible swatches share one palette across the bar, cards, settings and lock screen."
                icon: "color-management"
                glyph: "●"
                GridLayout {
                    Layout.fillWidth: true
                    columns: Math.max(4, Math.floor(width / 100))
                    columnSpacing: 6
                    rowSpacing: 6
                    Repeater {
                        model: root.accents
                        Button {
                            required property var modelData
                            Layout.fillWidth: true
                            implicitHeight: 42
                            hoverEnabled: true
                            onClicked: root.applyAccent(modelData.name)
                            contentItem: RowLayout {
                                spacing: 7
                                Rectangle { implicitWidth: 14; implicitHeight: 14; radius: 7; color: modelData.color; border.color: "#80ffffff" }
                                Text { Layout.fillWidth: true; text: modelData.name.toUpperCase(); color: backend.textColor; font.family: "Inter"; font.pixelSize: 8; font.bold: true; elide: Text.ElideRight }
                            }
                            background: Rectangle {
                                color: root.selectedAccent === modelData.name ? backend.overlayColor : backend.baseColor
                                border.color: root.selectedAccent === modelData.name || parent.hovered ? modelData.color : backend.lineColor
                            }
                        }
                    }
                }
            }

            SettingsCard {
                Layout.fillWidth: true
                title: "THEME STUDIO"
                description: "Derive a palette from the current wallpaper or save the active combination as your own preset."
                icon: "applications-graphics"
                glyph: "◇"
                RowLayout {
                    Layout.fillWidth: true
                    TextField {
                        id: customThemeName
                        Layout.fillWidth: true
                        placeholderText: "Preset name"
                        color: backend.textColor
                        font.family: "Inter"
                        font.pixelSize: 10
                        leftPadding: 10
                        background: Rectangle { color: backend.baseColor; border.color: customThemeName.activeFocus ? backend.accentColor : backend.lineColor }
                    }
                    NocturneButton { text: "DERIVE FROM WALLPAPER"; enabled: root.selectedWallpaper !== ""; onClicked: { backend.run([root.themeTool, "derive", root.selectedWallpaper], 12000); backend.refreshTheme(); root.refresh() } }
                    NocturneButton { text: "SAVE PRESET"; selected: true; enabled: customThemeName.text.trim().length > 0; onClicked: { backend.run([root.themeTool, "save", customThemeName.text.trim()]); customThemeName.clear(); root.refresh() } }
                }
                Flow {
                    Layout.fillWidth: true
                    spacing: 6
                    Repeater { model: root.studio.themes || []; NocturneButton { required property var modelData; text: modelData.name.toUpperCase(); onClicked: { backend.run([root.themeTool, "apply", modelData.name], 12000); backend.refreshTheme(); root.refresh() } } }
                }
            }
            Item { Layout.preferredHeight: 16 }
        }
    }
    Timer { id: wallpaperRefresh; interval: 900; onTriggered: root.refresh() }
    Timer { id: previewRefresh; interval: 350; onTriggered: root.refresh() }
    onActiveChanged: if (active) Qt.callLater(refresh)
    Component.onCompleted: if (active) Qt.callLater(refresh)
}
