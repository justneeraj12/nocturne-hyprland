import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"

Rectangle {
    id: root
    color: backend.baseColor
    property bool active: false
    property string pendingRemove: ""
    property var state: ({installed:0, enabled:0, extensions:[], contract:{version:1, declarative:true, arbitraryCode:false, residentProcesses:0}})
    readonly property string tool: backend.home + "/.local/bin/nocturne-extensions"

    function refresh() {
        if (!active) return
        var next = backend.json([tool, "status"], 3000)
        if (next && next.format === "nocturne-extensions-state-v1") state = next
    }
    function installManifest() {
        if (!manifestPath.text.trim()) return
        backend.run([tool, "install", manifestPath.text.trim()], 5000); manifestPath.clear(); refresh()
    }
    function removeExtension(id) {
        if (pendingRemove !== id) { pendingRemove = id; removeReset.restart(); return }
        backend.run([tool, "remove", id], 4000); pendingRemove = ""; refresh()
    }

    ScrollView {
        anchors.fill: parent; contentWidth: availableWidth; ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        ColumnLayout {
            x: 26; width: parent.width - 52; spacing: 14
            Item { Layout.preferredHeight: 10 }
            SettingsPageHeader {
                Layout.fillWidth: true; eyebrow: "CAPABILITY-GATED"; title: "Extensions"
                description: "Small integrations without an arbitrary-code marketplace. Version 1 can open reviewed native surfaces, credential-free HTTPS pages or installed desktop entries."
                badge: root.state.enabled + " ENABLED · ZERO IDLE"
            }
            GridLayout {
                Layout.fillWidth: true; columns: 4; columnSpacing: 9
                Repeater {
                    model: [
                        {label:"CONTRACT",value:"V" + root.state.contract.version,detail:"declarative manifest"},
                        {label:"ARBITRARY CODE",value:root.state.contract.arbitraryCode ? "ALLOWED" : "BLOCKED",detail:"no shell, QML or native code"},
                        {label:"INSTALLED",value:String(root.state.installed),detail:root.state.enabled + " currently enabled"},
                        {label:"IDLE COST",value:root.state.contract.residentProcesses + " PROCESSES",detail:"launch-time resolution only"}
                    ]
                    Rectangle {
                        required property var modelData; Layout.fillWidth: true; implicitHeight: 70; color: backend.surfaceColor; border.color: backend.lineColor
                        Column { anchors.fill: parent; anchors.margins: 9; spacing: 3
                            Text { text: modelData.label; color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 8; font.bold: true }
                            Text { text: modelData.value; color: backend.accentColor; font.family: "monospace"; font.pixelSize: 12; font.bold: true }
                            Text { width: parent.width; text: modelData.detail; color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 8; elide: Text.ElideRight }
                        }
                    }
                }
            }
            SettingsCard {
                Layout.fillWidth: true; title: "INSTALL REVIEWED MANIFEST"; description: "Install from a local JSON file after reading it. Remote stores and automatic code downloads are intentionally absent."; icon: "archive-insert"; glyph: "+"
                RowLayout {
                    Layout.fillWidth: true; spacing: 8
                    TextField { id: manifestPath; Layout.fillWidth: true; placeholderText: "/home/me/Downloads/example-extension.json"; color: backend.textColor; placeholderTextColor: backend.mutedColor; font.family: "monospace"; font.pixelSize: 9; background: Rectangle { color: backend.baseColor; border.color: manifestPath.activeFocus ? backend.accentColor : backend.lineColor } }
                    NocturneButton { text: "VALIDATE + INSTALL"; selected: true; enabled: manifestPath.text.trim() !== ""; onClicked: root.installManifest() }
                }
            }
            SettingsCard {
                Layout.fillWidth: true; title: "INSTALLED EXTENSIONS"; description: "Permission requests stay visible. Disabled entries consume no resources and cannot launch."; icon: "preferences-plugin"; glyph: "◇"
                Text { visible: !(root.state.extensions || []).length; text: "NO EXTENSIONS INSTALLED · THE CORE DESKTOP REMAINS COMPLETE"; color: backend.mutedColor; font.family: "monospace"; font.pixelSize: 9 }
                Repeater {
                    model: root.state.extensions || []
                    Rectangle {
                        required property var modelData; Layout.fillWidth: true; implicitHeight: 76; color: backend.baseColor; border.color: modelData.enabled ? backend.accent2Color : backend.lineColor
                        RowLayout { anchors.fill: parent; anchors.margins: 9; spacing: 9
                            ColumnLayout { Layout.fillWidth: true; spacing: 2
                                Text { text: modelData.name + "  ·  " + modelData.version; color: backend.textColor; font.family: "Inter"; font.pixelSize: 10; font.bold: true }
                                Text { Layout.fillWidth: true; text: modelData.description; color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 8; elide: Text.ElideRight }
                                Text { text: "ENTRY " + String(modelData.entry.type).toUpperCase() + " · PERMISSIONS " + ((modelData.permissions || []).length ? modelData.permissions.join(", ").toUpperCase() : "NONE"); color: backend.accent2Color; font.family: "monospace"; font.pixelSize: 8 }
                            }
                            NocturneButton { text: "OPEN"; selected: true; enabled: modelData.enabled; onClicked: backend.start([root.tool, "launch", modelData.id]) }
                            NocturneToggle { checked: modelData.enabled; accessibleName: "Enable " + modelData.name; onToggleRequested: function(value) { backend.run([root.tool, value ? "enable" : "disable", modelData.id], 3500); root.refresh() } }
                            NocturneButton { text: root.pendingRemove === modelData.id ? "CONFIRM" : "REMOVE"; danger: root.pendingRemove === modelData.id; onClicked: root.removeExtension(modelData.id) }
                        }
                    }
                }
            }
            Text { Layout.fillWidth: true; text: "Executable extensions will not be added until process isolation, accessibility, lifecycle supervision and enforceable memory/CPU budgets exist."; color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 8; wrapMode: Text.WordWrap }
            Item { Layout.preferredHeight: 16 }
        }
    }
    Timer { id: removeReset; interval: 5000; onTriggered: root.pendingRemove = "" }
    onActiveChanged: if (active) Qt.callLater(refresh)
    Component.onCompleted: if (active) Qt.callLater(refresh)
}
