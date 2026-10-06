import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"

Rectangle {
    id: root
    implicitWidth: 460
    implicitHeight: Math.min(620, panel.implicitHeight + 20)
    color: backend.baseColor
    border.color: backend.accent2Color
    border.width: 1
    property var monitors: []
    readonly property string helper: backend.home + "/.config/hypr/scripts/monitor-layout"

    function refresh() { monitors = backend.json([helper, "status"], 2500) || [] }
    function action(arguments) {
        backend.start([helper].concat(arguments))
        delayed.restart()
    }

    ScrollView {
        anchors.fill: parent
        contentWidth: availableWidth
        ColumnLayout {
            id: panel
            x: 10; y: 10; width: parent.width - 20; spacing: 8
            PanelHeader { Layout.fillWidth: true; title: "Displays"; subtitle: root.monitors.length + " active output" + (root.monitors.length === 1 ? "" : "s") }

            RowLayout {
                Layout.fillWidth: true; spacing: 5
                NocturneButton { Layout.fillWidth: true; text: "EXTEND"; onClicked: root.action(["extend"]) }
                NocturneButton { Layout.fillWidth: true; text: "MIRROR"; enabled: root.monitors.length > 1; onClicked: root.action(["mirror"]) }
                NocturneButton { Layout.fillWidth: true; text: "SAVE LAYOUT"; selected: true; onClicked: root.action(["save"]) }
            }

            Repeater {
                model: root.monitors
                delegate: Rectangle {
                    id: monitorCard
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: content.implicitHeight + 16
                    color: backend.surfaceColor
                    border.color: modelData.focused ? backend.accentColor : backend.lineColor
                    ColumnLayout {
                        id: content
                        anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                        anchors.margins: 8; spacing: 6
                        RowLayout {
                            Layout.fillWidth: true
                            ColumnLayout {
                                Layout.fillWidth: true; spacing: 1
                                Text { text: modelData.name + (modelData.focused ? "  ·  ACTIVE" : ""); color: backend.textColor; font.family: "monospace"; font.bold: true }
                                Text {
                                    text: modelData.width + "×" + modelData.height + " @ " + Math.round(modelData.refreshRate) + " Hz  ·  " + modelData.description
                                    color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 9; elide: Text.ElideRight; Layout.fillWidth: true
                                }
                            }
                            Text { text: "×" + modelData.scale; color: backend.textColor; font.family: "monospace"; font.bold: true }
                        }
                        RowLayout {
                            Layout.fillWidth: true; spacing: 5
                            Text { Layout.fillWidth: true; text: "VRR " + (modelData.vrr ? "ACTIVE" : "AVAILABLE WHEN SUPPORTED") + " · " + (modelData.wideColorGamut ? "WIDE GAMUT" : "SDR") + " · " + ((modelData.availableModes || []).length) + " MODES"; color: backend.mutedColor; font.family: "monospace"; font.pixelSize: 7 }
                            NocturneButton { text: "MAX REFRESH"; enabled: (modelData.availableModes || []).length > 0; onClicked: { var modes=modelData.availableModes||[]; if(modes.length) root.action(["mode",modelData.name,modes[modes.length-1]]) } }
                        }
                        RowLayout {
                            Layout.fillWidth: true; spacing: 4
                            Repeater {
                                model: [1, 1.25, 1.5, 2]
                                NocturneButton {
                                    required property real modelData
                                    Layout.fillWidth: true
                                    text: modelData + "×"
                                    selected: Math.abs(monitorCard.modelData.scale - modelData) < 0.01
                                    onClicked: root.action(["scale", monitorCard.modelData.name, String(modelData)])
                                }
                            }
                        }
                        RowLayout {
                            Layout.fillWidth: true; spacing: 4
                            Repeater {
                                model: [{value:0,label:"NORMAL"},{value:1,label:"90°"},{value:2,label:"180°"},{value:3,label:"270°"}]
                                NocturneButton {
                                    required property var modelData
                                    Layout.fillWidth: true; text: modelData.label
                                    selected: (monitorCard.modelData.transform || 0) === modelData.value
                                    onClicked: root.action(["rotate", monitorCard.modelData.name, String(modelData.value)])
                                }
                            }
                        }
                    }
                }
            }
            Text {
                Layout.fillWidth: true
                text: "Changes apply live. SAVE LAYOUT makes the current geometry persistent."
                color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 9; wrapMode: Text.WordWrap
            }
        }
    }
    Timer { id: delayed; interval: 900; onTriggered: root.refresh() }
    Component.onCompleted: refresh()
}
