import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"

Rectangle {
    id: root
    implicitWidth: 430
    implicitHeight: panel.implicitHeight + 20
    color: backend.baseColor; border.color: backend.accent2Color; border.width: 1
    property var state: ({available:false,controller:false,busy:false,name:"Camera",holder:"",profile:"default",format:"",idleCost:"",installCommand:"Install v4l-utils with your package manager"})
    property bool applying: false
    readonly property string helper: backend.home + "/.config/hypr/scripts/camera-control"

    function refresh() { state = backend.json([helper, "status"], 1800) || state }
    function applyProfile(profile) {
        applying = true
        backend.run([helper, "apply", profile], 5000)
        applying = false
        refresh()
    }

    ColumnLayout {
        id: panel; x: 10; y: 10; width: parent.width - 20; spacing: 8
        PanelHeader { Layout.fillWidth: true; title: "Camera"; subtitle: "Smooth capture · hardware-first image tuning" }
        Rectangle {
            Layout.fillWidth: true; implicitHeight: 62
            color: backend.surfaceColor
            border.color: root.state.busy ? "#c08a55" : (root.state.available ? backend.lineColor : "#8d4b54")
            RowLayout {
                anchors.fill: parent; anchors.margins: 9; spacing: 9
                Text { text: "󰄀"; color: root.state.available ? backend.accentColor : "#ff8c96"; font.family: "MesloLGS Nerd Font Mono"; font.pixelSize: 20 }
                ColumnLayout { Layout.fillWidth: true; spacing: 2
                    Text { text: String(root.state.name || "CAMERA").toUpperCase(); color: backend.textColor; font.family: "Inter"; font.bold: true; font.pixelSize: 10 }
                    Text { Layout.fillWidth: true; text: root.state.busy ? "In use by " + (root.state.holder || "another application") : (root.state.available ? root.state.format : "No camera device detected"); color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 9; elide: Text.ElideRight }
                }
                Text { text: String(root.state.profile || "default").toUpperCase(); color: backend.accentColor; font.family: "monospace"; font.pixelSize: 8; font.bold: true }
            }
        }
        SectionLabel { text: "ADAPTIVE SENSOR PROFILE" }
        RowLayout {
            Layout.fillWidth: true; spacing: 5
            Repeater {
                model: [{key:"smart",label:"SMART"},{key:"natural",label:"NATURAL"},{key:"low-light",label:"LOW LIGHT"}]
                NocturneButton {
                    required property var modelData
                    Layout.fillWidth: true; text: modelData.label
                    selected: root.state.profile === modelData.key
                    enabled: root.state.available && root.state.controller && !root.state.busy && !root.applying
                    onClicked: root.applyProfile(modelData.key)
                }
            }
        }
        SettingsCard {
            Layout.fillWidth: true
            title: root.state.controller ? "HARDWARE-FIRST PIPELINE" : "V4L2 CONTROLS NEEDED"
            description: root.state.controller
                ? "The profile programs the webcam's own exposure, white balance, focus, backlight and local mains anti-flicker controls. Meet and Discord keep using the normal camera."
                : "Install the small v4l-utils package once to expose the sensor controls. No virtual camera, AI model or idle processing service is added."
            glyph: root.state.controller ? "ISP" : "!"
            Text {
                Layout.fillWidth: true
                text: root.state.controller ? root.state.idleCost : root.state.installCommand
                color: root.state.controller ? backend.accentColor : "#ffb36a"
                font.family: "monospace"; font.pixelSize: 9; wrapMode: Text.Wrap
            }
        }
        Text {
            Layout.fillWidth: true
            text: root.state.busy ? "Close the app currently holding the camera before changing its hardware controls." : "SMART is the everyday profile. NATURAL disables backlight compensation. LOW LIGHT allows exposure to trade frame cadence for a cleaner image when supported."
            color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 8; wrapMode: Text.WordWrap
        }
        NocturneButton { Layout.fillWidth: true; text: "REFRESH CAMERA STATE"; onClicked: root.refresh() }
    }
    Timer { interval: 2500; running: true; repeat: true; triggeredOnStart: true; onTriggered: root.refresh() }
}
