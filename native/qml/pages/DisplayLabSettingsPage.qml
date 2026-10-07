import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"

Rectangle {
    id: root
    color: backend.baseColor
    property bool active: false
    property string pendingDelete: ""
    property var state: ({monitors:[],profiles:[],autoSwitch:false,lastProfile:"",hdr:{experimental:true,managed:false}})
    readonly property string tool: backend.home + "/.config/hypr/scripts/monitor-layout"

    function refresh() {
        if (!active) return
        var next = backend.json([tool, "lab-status"], 4000)
        if (next && next.format === "nocturne-display-lab-v1") state = next
    }
    function action(args) { backend.run([tool].concat(args), 8000); refreshDelay.restart() }
    function deleteProfile(name) {
        if (pendingDelete !== name) { pendingDelete = name; deleteReset.restart(); return }
        action(["profile-delete", name]); pendingDelete = ""
    }

    ScrollView {
        anchors.fill: parent; contentWidth: availableWidth; ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        ColumnLayout {
            x: 26; width: parent.width - 52; spacing: 14
            Item { Layout.preferredHeight: 10 }
            SettingsPageHeader {
                Layout.fillWidth: true; eyebrow: "OUTPUTS + DOCKS"; title: "Display Lab"
                description: "Live geometry, scaling, rotation, refresh and monitor-set profiles. Changes use Hyprland's native output API and remain reversible until saved."
                badge: root.state.monitors.length + " ACTIVE OUTPUT" + (root.state.monitors.length === 1 ? "" : "S")
            }
            RowLayout {
                Layout.fillWidth: true; spacing: 8
                NocturneButton { Layout.fillWidth: true; text: "EXTEND"; onClicked: root.action(["extend"]) }
                NocturneButton { Layout.fillWidth: true; text: "MIRROR"; enabled: root.state.monitors.length > 1; onClicked: root.action(["mirror"]) }
                NocturneButton { Layout.fillWidth: true; text: "SAVE LOGIN LAYOUT"; selected: true; onClicked: root.action(["save"]) }
                NocturneButton { text: "REFRESH"; onClicked: root.refresh() }
            }
            Repeater {
                model: root.state.monitors || []
                SettingsCard {
                    id: monitorCard
                    required property var modelData
                    Layout.fillWidth: true; title: modelData.name + (modelData.focused ? " · ACTIVE" : ""); description: modelData.description || "Display output"; icon: "video-display"; glyph: "▣"
                    RowLayout {
                        Layout.fillWidth: true; spacing: 8
                        Text { Layout.fillWidth: true; text: modelData.width + "×" + modelData.height + " @ " + Number(modelData.refreshRate).toFixed(0) + " Hz  ·  " + modelData.x + "×" + modelData.y + "  ·  SCALE " + modelData.scale; color: backend.textColor; font.family: "monospace"; font.pixelSize: 9; font.bold: true }
                        Text { text: modelData.vrr ? "VRR ACTIVE" : "VRR READY"; color: modelData.vrr ? backend.accentColor : backend.mutedColor; font.family: "monospace"; font.pixelSize: 8 }
                        NocturneButton { text: "MAX REFRESH"; enabled: (modelData.availableModes || []).length > 0; onClicked: { var modes=modelData.availableModes || []; if (modes.length) root.action(["mode", modelData.name, modes[modes.length - 1]]) } }
                    }
                    RowLayout {
                        Layout.fillWidth: true; spacing: 6
                        Text { text: "SCALE"; color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 8; font.bold: true }
                        Repeater { model: [1,1.25,1.5,2]; NocturneButton { required property real modelData; Layout.fillWidth: true; text: modelData + "×"; selected: Math.abs(monitorCard.modelData.scale - modelData) < 0.01; onClicked: root.action(["scale", monitorCard.modelData.name, String(modelData)]) } }
                    }
                    RowLayout {
                        Layout.fillWidth: true; spacing: 6
                        Text { text: "ROTATION"; color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 8; font.bold: true }
                        Repeater { model: [{value:0,label:"NORMAL"},{value:1,label:"90°"},{value:2,label:"180°"},{value:3,label:"270°"}]; NocturneButton { required property var modelData; Layout.fillWidth: true; text: modelData.label; selected: (monitorCard.modelData.transform || 0) === modelData.value; onClicked: root.action(["rotate", monitorCard.modelData.name, String(modelData.value)]) } }
                    }
                    RowLayout {
                        Layout.fillWidth: true; spacing: 7
                        Text { text: "POSITION"; color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 8; font.bold: true }
                        TextField {
                            id: positionX
                            Layout.preferredWidth: 90
                            text: String(modelData.x)
                            validator: IntValidator {}
                            color: backend.textColor; font.family: "monospace"; font.pixelSize: 9
                            background: Rectangle { color: backend.baseColor; border.color: positionX.activeFocus ? backend.accentColor : backend.lineColor }
                        }
                        Text { text: "×"; color: backend.mutedColor; font.family: "monospace" }
                        TextField {
                            id: positionY
                            Layout.preferredWidth: 90
                            text: String(modelData.y)
                            validator: IntValidator {}
                            color: backend.textColor; font.family: "monospace"; font.pixelSize: 9
                            background: Rectangle { color: backend.baseColor; border.color: positionY.activeFocus ? backend.accentColor : backend.lineColor }
                        }
                        NocturneButton { Layout.fillWidth: true; text: "APPLY POSITION"; onClicked: root.action(["position", modelData.name, positionX.text, positionY.text]) }
                        NocturneButton { text: "DISABLE OUTPUT"; danger: true; enabled: root.state.monitors.length > 1; onClicked: root.action(["disable", modelData.name]) }
                    }
                }
            }
            SettingsCard {
                Layout.fillWidth: true; title: "DOCK + MONITOR PROFILES"; description: "Profiles match the exact connected output set. Automatic switching reuses the existing context timer and adds no resident process."; icon: "preferences-desktop-display"; glyph: "⇄"
                RowLayout {
                    Layout.fillWidth: true; spacing: 8
                    TextField { id: profileName; Layout.fillWidth: true; placeholderText: "desk-dock"; color: backend.textColor; placeholderTextColor: backend.mutedColor; font.family: "monospace"; font.pixelSize: 9; background: Rectangle { color: backend.baseColor; border.color: profileName.activeFocus ? backend.accentColor : backend.lineColor } }
                    NocturneButton { text: "SAVE CURRENT AS PROFILE"; selected: true; enabled: profileName.text.trim() !== ""; onClicked: { root.action(["profile-save", profileName.text.trim()]); profileName.clear() } }
                    Text { text: "AUTO SWITCH"; color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 8; font.bold: true }
                    NocturneToggle { checked: root.state.autoSwitch; accessibleName: "Automatically apply matching display profiles"; onToggleRequested: function(value) { root.action(["auto", value ? "true" : "false"]) } }
                }
                Text { visible: !(root.state.profiles || []).length; text: "NO SAVED DISPLAY PROFILES"; color: backend.mutedColor; font.family: "monospace"; font.pixelSize: 9 }
                Repeater {
                    model: root.state.profiles || []
                    Rectangle {
                        required property var modelData; Layout.fillWidth: true; implicitHeight: 48; color: backend.baseColor; border.color: modelData.matches ? backend.accentColor : backend.lineColor
                        RowLayout { anchors.fill: parent; anchors.margins: 8; spacing: 8
                            ColumnLayout { Layout.fillWidth: true; spacing: 1
                                Text { text: modelData.name + (modelData.matches ? " · CONNECTED SET MATCHES" : ""); color: modelData.matches ? backend.accentColor : backend.textColor; font.family: "Inter"; font.pixelSize: 9; font.bold: true }
                                Text { text: modelData.outputs + " OUTPUTS · " + modelData.created; color: backend.mutedColor; font.family: "monospace"; font.pixelSize: 8 }
                            }
                            NocturneButton { text: "APPLY"; selected: modelData.matches; onClicked: root.action(["profile-apply", modelData.name]) }
                            NocturneButton { text: root.pendingDelete === modelData.name ? "CONFIRM" : "DELETE"; danger: root.pendingDelete === modelData.name; onClicked: root.deleteProfile(modelData.name) }
                        }
                    }
                }
            }
            SettingsCard {
                Layout.fillWidth: true; title: "COLOR + HDR STATUS"; description: "Hyprland HDR and wide-gamut behaviour is still hardware- and application-sensitive. Display Lab reports capability but does not silently force an experimental color mode."; icon: "color-management"; glyph: "HDR"
                Text { Layout.fillWidth: true; text: "HDR CONTROL · EXPERIMENTAL UPSTREAM · MANUAL OPT-IN DEFERRED"; color: "#d9a85f"; font.family: "monospace"; font.pixelSize: 9; font.bold: true }
            }
            Item { Layout.preferredHeight: 16 }
        }
    }
    Timer { id: refreshDelay; interval: 900; onTriggered: root.refresh() }
    Timer { id: deleteReset; interval: 5000; onTriggered: root.pendingDelete = "" }
    onActiveChanged: if (active) Qt.callLater(refresh)
    Component.onCompleted: if (active) Qt.callLater(refresh)
}
