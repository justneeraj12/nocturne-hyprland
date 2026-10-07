import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"

Rectangle {
    id: root
    color: backend.baseColor
    property bool active: false
    property string pendingRemove: ""
    property var state: ({count:0, active:0, rules:[], clients:[]})
    readonly property string tool: backend.home + "/.local/bin/nocturne-window-rules"
    readonly property var actions: ["tile", "float", "workspace", "opacity", "monitor", "size", "pin", "idle-inhibit"]

    function refresh() {
        if (!active) return
        var next = backend.json([tool, "status"], 4500)
        if (next && next.format === "nocturne-window-rules-v1") state = next
    }
    function chooseClient(index) {
        if (index < 0 || index >= (root.state.clients || []).length) return
        classField.text = root.state.clients[index].class
        titleField.text = root.state.clients[index].title
        if (!nameField.text) nameField.text = root.state.clients[index].class
    }
    function needsValue() { return ["workspace", "opacity", "monitor", "size"].indexOf(actionBox.currentText) >= 0 }
    function placeholder() {
        if (actionBox.currentText === "workspace") return "2 or special:scratch"
        if (actionBox.currentText === "opacity") return "0.90"
        if (actionBox.currentText === "monitor") return "HDMI-A-1"
        if (actionBox.currentText === "size") return "960x720"
        return "No value needed"
    }
    function addRule() {
        backend.run([tool, "add", nameField.text.trim(), classField.text.trim(), titleField.text.trim() || "-", actionBox.currentText, valueField.text.trim()], 5000)
        nameField.clear(); classField.clear(); titleField.clear(); valueField.clear(); refresh()
    }
    function removeRule(id) {
        if (pendingRemove !== id) { pendingRemove = id; removeReset.restart(); return }
        backend.run([tool, "remove", id], 4000); pendingRemove = ""; refresh()
    }

    ScrollView {
        anchors.fill: parent; contentWidth: availableWidth; ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        ColumnLayout {
            x: 26; width: parent.width - 52; spacing: 14
            Item { Layout.preferredHeight: 10 }
            SettingsPageHeader {
                Layout.fillWidth: true; eyebrow: "APP BEHAVIOUR"; title: "Window Rules Studio"
                description: "Turn a currently open application into an exact, readable Hyprland rule without editing Lua or guessing its class. Generated rules are isolated from the base desktop."
                badge: root.state.active + " ACTIVE RULES"
            }
            SettingsCard {
                Layout.fillWidth: true; title: "NEW WINDOW RULE"; description: "Choose an open window, keep or clear the exact title match, then select one bounded action."; icon: "window-new"; glyph: "+"
                NocturneComboBox { id: clientBox; Layout.fillWidth: true; model: root.state.clients || []; textRole: "label"; accessibleName: "Choose an open window"; onActivated: function(index) { root.chooseClient(index) } }
                GridLayout {
                    Layout.fillWidth: true; columns: 3; columnSpacing: 8; rowSpacing: 8
                    TextField { id: nameField; Layout.fillWidth: true; placeholderText: "Rule name"; color: backend.textColor; placeholderTextColor: backend.mutedColor; font.family: "Inter"; font.pixelSize: 9; background: Rectangle { color: backend.baseColor; border.color: nameField.activeFocus ? backend.accentColor : backend.lineColor } }
                    TextField { id: classField; Layout.fillWidth: true; placeholderText: "Application class"; color: backend.textColor; placeholderTextColor: backend.mutedColor; font.family: "monospace"; font.pixelSize: 9; background: Rectangle { color: backend.baseColor; border.color: classField.activeFocus ? backend.accentColor : backend.lineColor } }
                    TextField { id: titleField; Layout.fillWidth: true; placeholderText: "Exact title (optional)"; color: backend.textColor; placeholderTextColor: backend.mutedColor; font.family: "monospace"; font.pixelSize: 9; background: Rectangle { color: backend.baseColor; border.color: titleField.activeFocus ? backend.accentColor : backend.lineColor } }
                    NocturneComboBox { id: actionBox; Layout.fillWidth: true; model: root.actions; accessibleName: "Rule action"; onCurrentTextChanged: valueField.clear() }
                    TextField { id: valueField; Layout.fillWidth: true; enabled: root.needsValue(); placeholderText: root.placeholder(); color: backend.textColor; placeholderTextColor: backend.mutedColor; font.family: "monospace"; font.pixelSize: 9; background: Rectangle { color: backend.baseColor; border.color: valueField.activeFocus ? backend.accentColor : backend.lineColor } }
                    NocturneButton { Layout.fillWidth: true; text: "ADD RULE"; selected: true; enabled: nameField.text.trim() !== "" && classField.text.trim() !== "" && (!root.needsValue() || valueField.text.trim() !== ""); onClicked: root.addRule() }
                }
            }
            SettingsCard {
                Layout.fillWidth: true; title: "MANAGED RULES"; description: "Rules use escaped exact matches. No pattern or command entered here is executed as shell text."; icon: "view-list-details"; glyph: "≡"
                Text { visible: !(root.state.rules || []).length; text: "NO MANAGED RULES"; color: backend.mutedColor; font.family: "monospace"; font.pixelSize: 9 }
                Repeater {
                    model: root.state.rules || []
                    Rectangle {
                        required property var modelData; Layout.fillWidth: true; implicitHeight: 58
                        color: backend.baseColor; border.color: modelData.enabled ? backend.accent2Color : backend.lineColor
                        RowLayout { anchors.fill: parent; anchors.margins: 8; spacing: 8
                            ColumnLayout { Layout.fillWidth: true; spacing: 2
                                Text { text: modelData.name; color: backend.textColor; font.family: "Inter"; font.pixelSize: 9; font.bold: true }
                                Text { Layout.fillWidth: true; text: modelData.class + (modelData.title ? " · “" + modelData.title + "”" : "") + "  →  " + String(modelData.action).toUpperCase() + (modelData.value ? " · " + modelData.value : ""); color: backend.mutedColor; font.family: "monospace"; font.pixelSize: 8; elide: Text.ElideRight }
                            }
                            NocturneToggle { checked: modelData.enabled; accessibleName: "Enable " + modelData.name; onToggleRequested: function(value) { backend.run([root.tool, value ? "enable" : "disable", modelData.id], 4000); root.refresh() } }
                            NocturneButton { text: root.pendingRemove === modelData.id ? "CONFIRM" : "REMOVE"; danger: root.pendingRemove === modelData.id; onClicked: root.removeRule(modelData.id) }
                        }
                    }
                }
            }
            Text { Layout.fillWidth: true; text: "Rules apply after a Hyprland reload. A malformed generated file is loaded with pcall, so it cannot prevent the base session from starting."; color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 8; wrapMode: Text.WordWrap }
            Item { Layout.preferredHeight: 16 }
        }
    }
    Timer { id: removeReset; interval: 5000; onTriggered: root.pendingRemove = "" }
    onActiveChanged: if (active) Qt.callLater(refresh)
    Component.onCompleted: if (active) Qt.callLater(refresh)
}
