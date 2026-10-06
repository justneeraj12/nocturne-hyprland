import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"

Rectangle {
    id: root
    implicitWidth: 610; implicitHeight: 530
    color: backend.baseColor; border.color: backend.accent2Color
    property var scenes: []; property var audioScenes: []; property var context: ({enabled:false,mappings:{}})
    property var preview: ({})
    property string pendingScene: ""
    property string pendingDelete: ""
    function refresh() {
        scenes = backend.json([backend.home + "/.config/hypr/scripts/scene-manager", "list"], 2500) || []
        audioScenes = backend.json([backend.home + "/.config/hypr/scripts/audio-scene", "list"], 2500) || []
        context = backend.json([backend.home + "/.config/hypr/scripts/context-engine", "status"], 2500) || context
    }
    function requestRestore(scene) {
        if (pendingScene !== scene.slug) {
            preview = backend.json([backend.home + "/.config/hypr/scripts/scene-manager", "preview", scene.slug], 3500) || ({})
            pendingScene = scene.slug; pendingDelete = ""; confirmReset.restart(); return
        }
        backend.start([backend.home + "/.config/hypr/scripts/scene-manager", "apply", scene.slug])
        pendingScene = ""; preview = ({})
    }
    function requestDelete(scene) {
        if (pendingDelete !== scene.slug) { pendingDelete = scene.slug; pendingScene = ""; preview = ({}); confirmReset.restart(); return }
        backend.run([backend.home + "/.config/hypr/scripts/scene-manager", "delete", scene.slug])
        pendingDelete = ""; refresh()
    }
    ColumnLayout {
        anchors.fill: parent; anchors.margins: 12; spacing: 8
        RowLayout {
            Layout.fillWidth: true
            PanelHeader { Layout.fillWidth: true; title: "Session Scenes"; subtitle: "Applications, workspaces, displays, wallpaper and audio" }
            NocturneButton { text: "WHY DID IT CHANGE?"; onClicked: backend.start([backend.home + "/.local/bin/nocturne-native", "automation"]) }
        }
        RowLayout {
            Layout.fillWidth: true
            TextField { id: sceneName; Layout.fillWidth: true; placeholderText: "Scene name"; color: backend.textColor; font.family: "monospace"; background: Rectangle { color: backend.surfaceColor; border.color: sceneName.activeFocus ? backend.accentColor : backend.lineColor } }
            NocturneButton { text: "SAVE CURRENT"; selected: true; enabled: sceneName.text.trim().length > 0; onClicked: { backend.run([backend.home + "/.config/hypr/scripts/scene-manager", "save", sceneName.text], 15000); sceneName.clear(); root.refresh() } }
        }
        SectionLabel { text: "DESKTOP SCENES" }
        Rectangle {
            visible: root.pendingScene !== "" && root.preview.format === "nocturne-scene-preview-v1"
            Layout.fillWidth: true; implicitHeight: 34
            color: backend.overlayColor; border.color: backend.accent2Color
            RowLayout { anchors.fill: parent; anchors.leftMargin: 9; anchors.rightMargin: 9; spacing: 8
                Text { text: "PREVIEW"; color: backend.accentColor; font.family: "monospace"; font.bold: true; font.pixelSize: 8 }
                Text { Layout.fillWidth: true; text: root.preview.appsToLaunch + " APPS TO LAUNCH  ·  " + root.preview.windows + " WINDOW PLACEMENTS  ·  " + root.preview.displays + " DISPLAYS  ·  " + root.preview.settingsChanges + " SETTINGS"; color: backend.textColor; font.family: "Inter"; font.pixelSize: 8; elide: Text.ElideRight }
                Text { text: "CLICK CONFIRM TO RESTORE"; color: backend.mutedColor; font.family: "monospace"; font.pixelSize: 7 }
            }
        }
        ScrollView {
            Layout.fillWidth: true; Layout.preferredHeight: root.pendingScene !== "" ? 142 : 180; clip: true; contentWidth: availableWidth
            ColumnLayout {
                width: parent.width; spacing: 4
                Repeater { model: root.scenes; Rectangle {
                    required property var modelData; Layout.fillWidth: true; implicitHeight: 47; color: backend.surfaceColor; border.color: modelData.active ? backend.accentColor : backend.lineColor
                    RowLayout { anchors.fill: parent; anchors.margins: 7
                        ColumnLayout { Layout.fillWidth: true; spacing: 1
                            Text { text: modelData.name.toUpperCase(); color: backend.textColor; font.family: "monospace"; font.bold: true; font.pixelSize: 10 }
                            Text { text: modelData.windows + " WINDOWS · " + modelData.created; color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 8 }
                        }
                        NocturneButton { text: root.pendingScene === modelData.slug ? "CONFIRM" : "PREVIEW"; selected: root.pendingScene === modelData.slug; onClicked: root.requestRestore(modelData) }
                        NocturneButton { text: root.pendingDelete === modelData.slug ? "CONFIRM ×" : "×"; danger: true; onClicked: root.requestDelete(modelData) }
                    }
                } }
            }
        }
        RowLayout {
            Layout.fillWidth: true
            SectionLabel { Layout.fillWidth: true; text: "AUDIO SCENES" }
            NocturneButton { text: "MEETING"; onClicked: backend.run([backend.home + "/.config/hypr/scripts/audio-scene", "meeting"]) }
            NocturneButton { text: "SAVE AUDIO"; onClicked: { var name = sceneName.text.trim() || "Audio " + new Date().toLocaleTimeString(); backend.run([backend.home + "/.config/hypr/scripts/audio-scene", "save", name], 10000); root.refresh() } }
        }
        Flow {
            Layout.fillWidth: true; Layout.preferredHeight: childrenRect.height; spacing: 5
            Repeater { model: root.audioScenes; NocturneButton { required property var modelData; text: modelData.name.toUpperCase(); onClicked: backend.start([backend.home + "/.config/hypr/scripts/audio-scene", "apply", modelData.name]) } }
        }
        RowLayout {
            Layout.fillWidth: true
            ColumnLayout { Layout.fillWidth: true; spacing: 1
                SectionLabel { text: "CONTEXT AUTOMATION" }
                Text { text: "Apply settings-only scenes for displays, power, focus, meetings or games. App relaunch is never automatic."; color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 9 }
            }
            NocturneToggle { checked: root.context.enabled; onToggleRequested: function(enabled) { backend.run([backend.home + "/.config/hypr/scripts/context-engine", enabled ? "enable" : "disable"], 3000); root.refresh() } }
        }
        GridLayout {
            Layout.fillWidth: true; columns: 4; columnSpacing: 5; rowSpacing: 5
            Repeater { model: [{key:"docked",label:"DOCKED"},{key:"mobile",label:"MOBILE"},{key:"ac",label:"AC"},{key:"battery",label:"BATTERY"},{key:"meeting",label:"MEETING"},{key:"focus",label:"FOCUS"},{key:"gaming",label:"GAMING"}]
                ColumnLayout { required property var modelData; Layout.fillWidth: true; spacing: 2
                    Text { text: modelData.label + (root.context.profile === modelData.key ? "  ●" : ""); color: root.context.profile === modelData.key ? backend.accentColor : backend.mutedColor; font.family: "Inter"; font.pixelSize: 7; font.bold: true }
                    ComboBox { Layout.fillWidth: true; model: ["None"].concat(root.scenes.map(function(item){ return item.slug }))
                        currentIndex: Math.max(0, model.indexOf((root.context.mappings || {})[modelData.key] || "None"))
                        onActivated: { backend.run([backend.home + "/.config/hypr/scripts/context-engine", "assign", modelData.key, currentText === "None" ? "" : currentText]); root.refresh() }
                    }
                }
            }
        }
        Item { Layout.fillHeight: true }
    }
    Timer { id: confirmReset; interval: 7000; onTriggered: { root.pendingScene = ""; root.pendingDelete = ""; root.preview = ({}) } }
    Component.onCompleted: refresh()
}
