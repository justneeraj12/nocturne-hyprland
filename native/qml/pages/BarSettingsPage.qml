import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"

Rectangle {
    id: root
    color: backend.baseColor
    property bool active: false
    property string scopeMonitor: ""
    property var state: ({density:"auto", iconScale:1, separators:true, trayCount:true, modules:{}, displays:[]})
    readonly property string tool: backend.home + "/.config/hypr/scripts/bar-preferences"
    readonly property var moduleOptions: [
        {key:"pomodoro", label:"Focus timer", glyph:"◷"}, {key:"media", label:"Media", glyph:"♪"},
        {key:"caffeine", label:"Caffeine", glyph:"☕"}, {key:"tray", label:"Background apps", glyph:"•••"},
        {key:"kdeconnect", label:"KDE Connect", glyph:"◇"}, {key:"audio", label:"Audio", glyph:"◖"},
        {key:"microphone", label:"Microphone", glyph:"●"}, {key:"brightness", label:"Brightness", glyph:"☼"},
        {key:"system", label:"Resources", glyph:"▦"}, {key:"connectivity", label:"Network", glyph:"⌁"},
        {key:"notifications", label:"Notifications", glyph:"◌"}, {key:"power", label:"Power", glyph:"⚡"}
    ]
    function refresh() { state = backend.json([tool, "status"], 2500) || state }
    function setValue(key, value) { backend.run([tool, "set", key, String(value)], 2500); refresh() }
    function moduleValue(key) {
        var local = (((state.monitors || {})[scopeMonitor] || {}).modules || {})
        if (scopeMonitor && local[key] !== undefined) return local[key] !== false
        return (state.modules || {})[key] !== false
    }
    function setModule(key, enabled) {
        if (scopeMonitor) backend.run([tool, "monitor-module", scopeMonitor, key, String(enabled)], 2500)
        else backend.run([tool, "set", "module." + key, String(enabled)], 2500)
        refresh()
    }

    ScrollView {
        anchors.fill: parent; contentWidth: availableWidth
        ColumnLayout {
            x: 26; width: parent.width - 52; spacing: 14
            Item { Layout.preferredHeight: 10 }
            SettingsPageHeader { Layout.fillWidth: true; eyebrow: "SHELL LAYOUT"; title: "Bar Studio"; description: "Choose density, scale and visible modules. The bar adapts each display independently and restarts in place."; badge: "LIVE" }
            SettingsCard {
                Layout.fillWidth: true; title: "LIVE PREVIEW"; description: "A compact structural preview—not a second bar process."; icon: "video-display"; glyph: "▤"
                Rectangle {
                    Layout.fillWidth: true; implicitHeight: 48; color: backend.baseColor; border.color: backend.lineColor
                    RowLayout { anchors.fill: parent; anchors.margins: 7; spacing: 5
                        Text { text: "N  1  2  3"; color: backend.textColor; font.family: "monospace"; font.pixelSize: 10 * Number(root.state.iconScale || 1) }
                        Item { Layout.fillWidth: true }
                        Text { text: "SUN 05 OCT  ·  5:24−"; color: backend.accentColor; font.family: "monospace"; font.pixelSize: 10 * Number(root.state.iconScale || 1) }
                        Item { Layout.fillWidth: true }
                        Text { text: "◷  ♪  ☕  •••  ◖  ☼  ⌁  ◌  ⚡"; color: backend.textColor; font.family: "monospace"; font.pixelSize: 10 * Number(root.state.iconScale || 1) }
                    }
                }
            }
            SettingsCard {
                Layout.fillWidth: true; title: "DENSITY + SCALE"; description: "Auto follows available width. A per-display override wins over the global setting."; icon: "preferences-desktop-display"; glyph: "↔"
                RowLayout { Layout.fillWidth: true; spacing: 5
                    Repeater { model: ["auto","compact","standard","full","detail"]
                        NocturneButton { required property string modelData; Layout.fillWidth: true; text: modelData.toUpperCase(); selected: root.state.density === modelData; onClicked: root.setValue("density", modelData) }
                    }
                }
                RowLayout { Layout.fillWidth: true
                    Text { text: "ICON SCALE"; color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 8; font.bold: true }
                    NocturneSlider { id: scale; Layout.fillWidth: true; from: .8; to: 1.35; stepSize: .05; value: Number(root.state.iconScale || 1); onPressedChanged: if (!pressed) root.setValue("iconScale", value.toFixed(2)) }
                    Text { text: Math.round(scale.value * 100) + "%"; color: backend.textColor; font.family: "monospace"; font.pixelSize: 9 }
                }
                Repeater { model: root.state.displays || []
                    RowLayout { required property var modelData; Layout.fillWidth: true
                        Text { Layout.fillWidth: true; text: modelData.name + "  ·  " + modelData.width + "×" + modelData.height; color: backend.textColor; font.family: "Inter"; font.pixelSize: 9; elide: Text.ElideRight }
                        NocturneComboBox { model: ["auto","compact","standard","full","detail"]; currentIndex: Math.max(0, model.indexOf(((root.state.monitors || {})[modelData.name] || {}).density || "auto")); onActivated: { backend.run([root.tool, "monitor", modelData.name, currentText], 2500); root.refresh() } }
                    }
                }
            }
            SettingsCard {
                Layout.fillWidth: true; title: "MODULES"; description: "Disable what you do not use. Core workspaces and clock remain available."; icon: "view-grid"; glyph: "▦"
                RowLayout { Layout.fillWidth: true
                    Text { text: "EDITING"; color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 8; font.bold: true }
                    NocturneButton { text: "ALL DISPLAYS"; selected: root.scopeMonitor === ""; onClicked: root.scopeMonitor = "" }
                    Repeater { model: root.state.displays || []
                        NocturneButton { required property var modelData; text: modelData.name.toUpperCase(); selected: root.scopeMonitor === modelData.name; onClicked: root.scopeMonitor = modelData.name }
                    }
                    Item { Layout.fillWidth: true }
                    Text { visible: root.scopeMonitor !== ""; text: "Overrides inherit until changed"; color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 8 }
                }
                GridLayout { Layout.fillWidth: true; columns: 3; columnSpacing: 7; rowSpacing: 7
                    Repeater { model: root.moduleOptions
                        Rectangle { required property var modelData; Layout.fillWidth: true; implicitHeight: 44; color: backend.baseColor; border.color: backend.lineColor
                            RowLayout { anchors.fill: parent; anchors.margins: 8
                                Text { text: modelData.glyph; color: backend.accentColor; font.family: "monospace"; font.pixelSize: 12 }
                                Text { Layout.fillWidth: true; text: modelData.label.toUpperCase(); color: backend.textColor; font.family: "Inter"; font.pixelSize: 8; font.bold: true; elide: Text.ElideRight }
                                NocturneToggle { checked: root.moduleValue(modelData.key); onToggleRequested: function(enabled) { root.setModule(modelData.key, enabled) } }
                            }
                        }
                    }
                }
                RowLayout { Layout.fillWidth: true
                    Text { Layout.fillWidth: true; text: "SEPARATORS"; color: backend.textColor; font.family: "Inter"; font.pixelSize: 9 }
                    NocturneToggle { checked: root.state.separators !== false; onToggleRequested: function(enabled) { root.setValue("separators", enabled) } }
                    Text { Layout.leftMargin: 18; text: "TRAY COUNT"; color: backend.textColor; font.family: "Inter"; font.pixelSize: 9 }
                    NocturneToggle { checked: root.state.trayCount !== false; onToggleRequested: function(enabled) { root.setValue("trayCount", enabled) } }
                    NocturneButton { Layout.leftMargin: 18; text: "RESET"; danger: true; onClicked: { backend.run([root.tool, "reset"], 2500); root.refresh() } }
                }
            }
            Item { Layout.preferredHeight: 22 }
        }
    }
    onActiveChanged: if (active) refresh()
    Component.onCompleted: refresh()
}
