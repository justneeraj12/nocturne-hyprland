import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"

Rectangle {
    id: root
    color: backend.baseColor
    property bool active: false
    property var state: ({input:{kbLayout:"us",repeatRate:35,repeatDelay:350,sensitivity:0,naturalScroll:true,tapToClick:true,disableWhileTyping:true},devices:{keyboards:0,mice:0,touchpads:0},time:{timezone:"",ntp:false},defaults:[]})
    readonly property string helper: backend.home + "/.config/hypr/scripts/system-preferences"

    function refresh() { state = backend.json([helper, "status"], 8000) || state }
    function setInput(key, value) { backend.run([helper, "set-input", key, String(value)], 5000); refreshDelay.restart() }

    ScrollView {
        anchors.fill: parent; contentWidth: availableWidth
        ColumnLayout {
            x: 22; width: parent.width - 44; spacing: 9
            Text { text: "INPUT + DEFAULTS"; color: backend.textColor; font.family: "monospace"; font.pixelSize: 25; font.bold: true }
            Text { Layout.fillWidth: true; text: "Hyprland-native keyboard and touchpad settings plus XDG defaults used consistently by every application."; color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 11; wrapMode: Text.WordWrap }
            SectionLabel { text: "DETECTED INPUT · " + root.state.devices.keyboards + " KEYBOARDS · " + root.state.devices.mice + " POINTERS · " + root.state.devices.touchpads + " TOUCHPADS" }
            Rectangle {
                Layout.fillWidth: true; implicitHeight: 91; color: backend.surfaceColor; border.color: backend.lineColor
                GridLayout { anchors.fill: parent; anchors.margins: 9; columns: 3; columnSpacing: 16; rowSpacing: 7
                    Text { text: "NATURAL SCROLL"; color: backend.textColor; font.family: "monospace"; font.pixelSize: 9 }
                    Text { text: "TAP TO CLICK"; color: backend.textColor; font.family: "monospace"; font.pixelSize: 9 }
                    Text { text: "DISABLE WHILE TYPING"; color: backend.textColor; font.family: "monospace"; font.pixelSize: 9 }
                    NocturneToggle { checked: root.state.input.naturalScroll; onToggleRequested: function(value) { root.setInput("naturalScroll", value) } }
                    NocturneToggle { checked: root.state.input.tapToClick; onToggleRequested: function(value) { root.setInput("tapToClick", value) } }
                    NocturneToggle { checked: root.state.input.disableWhileTyping; onToggleRequested: function(value) { root.setInput("disableWhileTyping", value) } }
                }
            }
            Rectangle {
                Layout.fillWidth: true; implicitHeight: 122; color: backend.surfaceColor; border.color: backend.lineColor
                GridLayout { anchors.fill: parent; anchors.margins: 9; columns: 3; columnSpacing: 14; rowSpacing: 4
                    Text { text: "POINTER SPEED"; color: backend.textColor; font.family: "monospace"; font.pixelSize: 9 }
                    Text { text: "KEY REPEAT"; color: backend.textColor; font.family: "monospace"; font.pixelSize: 9 }
                    Text { text: "REPEAT DELAY"; color: backend.textColor; font.family: "monospace"; font.pixelSize: 9 }
                    NocturneSlider { id: sensitivity; Layout.fillWidth: true; from: -1; to: 1; stepSize: 0.1; value: root.state.input.sensitivity; onPressedChanged: if (!pressed) root.setInput("sensitivity", value.toFixed(1)) }
                    NocturneSlider { id: repeatRate; Layout.fillWidth: true; from: 10; to: 100; stepSize: 5; value: root.state.input.repeatRate; onPressedChanged: if (!pressed) root.setInput("repeatRate", Math.round(value)) }
                    NocturneSlider { id: repeatDelay; Layout.fillWidth: true; from: 150; to: 1000; stepSize: 50; value: root.state.input.repeatDelay; onPressedChanged: if (!pressed) root.setInput("repeatDelay", Math.round(value)) }
                    Text { text: Number(root.state.input.sensitivity).toFixed(1); color: backend.accentColor; font.family: "monospace"; font.pixelSize: 9 }
                    Text { text: root.state.input.repeatRate + " / SEC"; color: backend.accentColor; font.family: "monospace"; font.pixelSize: 9 }
                    Text { text: root.state.input.repeatDelay + " MS"; color: backend.accentColor; font.family: "monospace"; font.pixelSize: 9 }
                }
            }
            SectionLabel { text: "DEFAULT APPLICATIONS" }
            Repeater {
                model: root.state.defaults
                Rectangle {
                    required property var modelData
                    Layout.fillWidth: true; implicitHeight: 47; color: backend.surfaceColor; border.color: backend.lineColor
                    RowLayout { anchors.fill: parent; anchors.margins: 7; spacing: 8
                        ColumnLayout { Layout.fillWidth: true; spacing: 1
                            Text { text: modelData.label; color: backend.textColor; font.family: "monospace"; font.bold: true; font.pixelSize: 9 }
                            Text { Layout.fillWidth: true; text: modelData.name || modelData.current || "Not configured"; color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 8; elide: Text.ElideRight }
                        }
                        ComboBox {
                            id: applicationPicker; Layout.preferredWidth: 190; model: modelData.options; textRole: "name"
                            currentIndex: { for (var i = 0; i < model.length; ++i) if (model[i].id === modelData.current) return i; return -1 }
                            onActivated: { backend.run([root.helper, "set-default", modelData.key, model[currentIndex].id], 3000); root.refresh() }
                            contentItem: Text { leftPadding: 8; text: applicationPicker.displayText || "CHOOSE"; color: backend.textColor; font.family: "Inter"; font.pixelSize: 9; verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
                            background: Rectangle { color: backend.overlayColor; border.color: applicationPicker.activeFocus ? backend.accentColor : backend.lineColor }
                        }
                    }
                }
            }
            SectionLabel { text: "DATE + TIME" }
            RowLayout {
                Layout.fillWidth: true
                TextField { id: timezone; Layout.fillWidth: true; text: root.state.time.timezone; placeholderText: "Region/City"; color: backend.textColor; font.family: "monospace"; background: Rectangle { color: backend.surfaceColor; border.color: timezone.activeFocus ? backend.accentColor : backend.lineColor } }
                NocturneButton { text: "APPLY TIMEZONE"; onClicked: { backend.start([root.helper, "timezone", timezone.text]); refreshDelay.restart() } }
                Text { text: "NETWORK TIME"; color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 8; font.bold: true }
                NocturneToggle { checked: root.state.time.ntp; onToggleRequested: function(value) { backend.start([root.helper, "ntp", String(value)]); refreshDelay.restart() } }
            }
            Item { Layout.preferredHeight: 12 }
        }
    }
    Timer { id: refreshDelay; interval: 1100; onTriggered: root.refresh() }
    onActiveChanged: if (active) Qt.callLater(refresh)
    Component.onCompleted: if (active) Qt.callLater(refresh)
}
