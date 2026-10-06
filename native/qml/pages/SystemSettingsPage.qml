import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"

Rectangle {
    id: root
    color: backend.baseColor
    property bool active: false
    property var state: ({input:{kbLayout:"us",repeatRate:35,repeatDelay:350,sensitivity:0,naturalScroll:true,tapToClick:true,disableWhileTyping:true,workspaceSwipe:true,accelProfile:"adaptive"},devices:{keyboards:0,mice:0,touchpads:0},time:{timezone:"",ntp:false},defaults:[]})
    readonly property string helper: backend.home + "/.config/hypr/scripts/system-preferences"

    function refresh() { state = backend.json([helper, "status"], 8000) || state }
    function setInput(key, value) { backend.run([helper, "set-input", key, String(value)], 5000); refreshDelay.restart() }

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
                eyebrow: "INPUT + APPLICATIONS"
                title: "Input & defaults"
                description: "Hyprland-native keyboard and touchpad behavior, plus the applications every desktop action opens."
                badge: root.state.devices.keyboards + " KB · " + root.state.devices.mice + " POINTERS"
            }

            SettingsCard {
                Layout.fillWidth: true
                title: "TOUCHPAD & POINTER"
                description: root.state.devices.touchpads + " touchpad" + (root.state.devices.touchpads === 1 ? "" : "s") + " detected"
                icon: "input-touchpad"
                glyph: "◇"
                GridLayout {
                    Layout.fillWidth: true
                    columns: 3
                    columnSpacing: 12
                    rowSpacing: 8
                    Repeater {
                        model: [
                            {label:"Natural scrolling",detail:"Content follows finger movement",key:"naturalScroll",value:root.state.input.naturalScroll},
                            {label:"Tap to click",detail:"One-finger tap activates",key:"tapToClick",value:root.state.input.tapToClick},
                            {label:"Disable while typing",detail:"Prevents accidental pointer movement",key:"disableWhileTyping",value:root.state.input.disableWhileTyping}
                        ]
                        Rectangle {
                            required property var modelData
                            Layout.fillWidth: true
                            implicitHeight: 58
                            color: backend.baseColor
                            border.color: backend.lineColor
                            RowLayout {
                                anchors.fill: parent; anchors.margins: 9; spacing: 8
                                ColumnLayout {
                                    Layout.fillWidth: true; spacing: 2
                                    Text { Layout.fillWidth: true; text: modelData.label; color: backend.textColor; font.family: "Inter"; font.pixelSize: 9; font.bold: true; elide: Text.ElideRight }
                                    Text { Layout.fillWidth: true; text: modelData.detail; color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 8; elide: Text.ElideRight }
                                }
                                NocturneToggle { checked: modelData.value; onToggleRequested: function(value) { root.setInput(modelData.key, value) } }
                            }
                        }
                    }
                }
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 4
                        RowLayout { Layout.fillWidth: true
                            Text { Layout.fillWidth: true; text: "POINTER SPEED"; color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 8; font.bold: true }
                            Text { text: Number(root.state.input.sensitivity).toFixed(1); color: backend.accentColor; font.family: "monospace"; font.pixelSize: 9 }
                        }
                        NocturneSlider { Layout.fillWidth: true; from: -1; to: 1; stepSize: 0.1; value: root.state.input.sensitivity; onPressedChanged: if (!pressed) root.setInput("sensitivity", value.toFixed(1)) }
                    }
                }
                RowLayout {
                    Layout.fillWidth: true; spacing: 10
                    Rectangle { Layout.fillWidth: true; implicitHeight: 52; color: backend.baseColor; border.color: backend.lineColor
                        RowLayout { anchors.fill: parent; anchors.margins: 9
                            ColumnLayout { Layout.fillWidth: true; spacing: 2; Text { text: "WORKSPACE SWIPE"; color: backend.textColor; font.family: "Inter"; font.pixelSize: 9; font.bold: true } Text { text: "Three-finger native workspace navigation"; color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 8 } }
                            NocturneToggle { checked: root.state.input.workspaceSwipe; onToggleRequested: function(v) { root.setInput("workspaceSwipe", v) } }
                        }
                    }
                    RowLayout { Layout.fillWidth: true; Text { Layout.fillWidth: true; text: "POINTER ACCELERATION"; color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 8; font.bold: true } NocturneComboBox { model: ["adaptive","flat"]; currentIndex: root.state.input.accelProfile === "flat" ? 1 : 0; onActivated: root.setInput("accelProfile", model[currentIndex]) } }
                }
            }

            SettingsCard {
                Layout.fillWidth: true
                title: "KEYBOARD"
                description: "Layout and repeat behavior apply immediately after validation."
                icon: "input-keyboard"
                glyph: "⌨"
                GridLayout {
                    Layout.fillWidth: true
                    columns: 3
                    columnSpacing: 12
                    rowSpacing: 6
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 4
                        Text { text: "LAYOUT"; color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 8; font.bold: true }
                        RowLayout {
                            Layout.fillWidth: true
                            TextField {
                                id: keyboardLayout
                                Layout.fillWidth: true
                                text: root.state.input.kbLayout
                                placeholderText: "us"
                                color: backend.textColor; font.family: "monospace"; font.pixelSize: 9; leftPadding: 9
                                background: Rectangle { color: backend.baseColor; border.color: keyboardLayout.activeFocus ? backend.accentColor : backend.lineColor }
                            }
                            NocturneButton { text: "APPLY"; enabled: keyboardLayout.text.trim() !== root.state.input.kbLayout; onClicked: root.setInput("kbLayout", keyboardLayout.text.trim()) }
                        }
                    }
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 4
                        RowLayout { Layout.fillWidth: true
                            Text { Layout.fillWidth: true; text: "REPEAT RATE"; color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 8; font.bold: true }
                            Text { text: root.state.input.repeatRate + "/s"; color: backend.accentColor; font.family: "monospace"; font.pixelSize: 9 }
                        }
                        NocturneSlider { Layout.fillWidth: true; from: 10; to: 100; stepSize: 5; value: root.state.input.repeatRate; onPressedChanged: if (!pressed) root.setInput("repeatRate", Math.round(value)) }
                    }
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 4
                        RowLayout { Layout.fillWidth: true
                            Text { Layout.fillWidth: true; text: "REPEAT DELAY"; color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 8; font.bold: true }
                            Text { text: root.state.input.repeatDelay + " ms"; color: backend.accentColor; font.family: "monospace"; font.pixelSize: 9 }
                        }
                        NocturneSlider { Layout.fillWidth: true; from: 150; to: 1000; stepSize: 50; value: root.state.input.repeatDelay; onPressedChanged: if (!pressed) root.setInput("repeatDelay", Math.round(value)) }
                    }
                }
            }

            SettingsCard {
                Layout.fillWidth: true
                title: "DEFAULT APPLICATIONS"
                description: "One source of truth for links, folders, documents and media."
                icon: "preferences-desktop-default-applications"
                glyph: "◫"
                GridLayout {
                    Layout.fillWidth: true
                    columns: width >= 650 ? 2 : 1
                    columnSpacing: 9
                    rowSpacing: 9
                    Repeater {
                        model: root.state.defaults
                        Rectangle {
                            required property var modelData
                            Layout.fillWidth: true
                            implicitHeight: 62
                            color: backend.baseColor
                            border.color: backend.lineColor
                            RowLayout {
                                anchors.fill: parent; anchors.margins: 8; spacing: 9
                                ColumnLayout {
                                    Layout.fillWidth: true; spacing: 2
                                    Text { text: modelData.label; color: backend.textColor; font.family: "Inter"; font.pixelSize: 9; font.bold: true }
                                    Text { Layout.fillWidth: true; text: modelData.name || modelData.current || "Not configured"; color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 8; elide: Text.ElideRight }
                                }
                                NocturneComboBox {
                                    id: applicationPicker
                                    Layout.preferredWidth: 178
                                    model: modelData.options
                                    textRole: "name"
                                    currentIndex: {
                                        for (var i = 0; i < model.length; ++i) if (model[i].id === modelData.current) return i
                                        return -1
                                    }
                                    enabled: model.length > 0
                                    onActivated: {
                                        backend.run([root.helper, "set-default", modelData.key, model[currentIndex].id], 3000)
                                        root.refresh()
                                    }
                                }
                            }
                        }
                    }
                }
            }

            SettingsCard {
                Layout.fillWidth: true
                title: "FILES"
                description: "Nocturne Files uses clean tabs, split view, rich previews, devices and network locations without background indexing."
                icon: "system-file-manager"
                glyph: "▦"
                RowLayout {
                    Layout.fillWidth: true
                    NocturneButton { Layout.fillWidth: true; text: "HOME"; selected: true; onClicked: backend.start([backend.home + "/.local/bin/nocturne-files", backend.home]) }
                    NocturneButton { Layout.fillWidth: true; text: "DOWNLOADS"; onClicked: backend.start([backend.home + "/.local/bin/nocturne-files", backend.home + "/Downloads"]) }
                    NocturneButton { Layout.fillWidth: true; text: "PICTURES"; onClicked: backend.start([backend.home + "/.local/bin/nocturne-files", backend.home + "/Pictures"]) }
                }
            }

            SettingsCard {
                Layout.fillWidth: true
                title: "DATE & TIME"
                description: "The world clock remains independent; this changes the computer's local timezone."
                icon: "preferences-system-time"
                glyph: "◷"
                RowLayout {
                    Layout.fillWidth: true
                    TextField {
                        id: timezone
                        Layout.fillWidth: true
                        text: root.state.time.timezone
                        placeholderText: "Region/City"
                        color: backend.textColor; font.family: "monospace"; font.pixelSize: 9; leftPadding: 9
                        background: Rectangle { color: backend.baseColor; border.color: timezone.activeFocus ? backend.accentColor : backend.lineColor }
                    }
                    NocturneButton { text: "APPLY TIMEZONE"; enabled: timezone.text.trim() !== root.state.time.timezone; onClicked: { backend.start([root.helper, "timezone", timezone.text.trim()]); refreshDelay.restart() } }
                    Text { text: "NETWORK TIME"; color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 8; font.bold: true }
                    NocturneToggle { checked: root.state.time.ntp; onToggleRequested: function(value) { backend.start([root.helper, "ntp", String(value)]); refreshDelay.restart() } }
                }
            }
            Item { Layout.preferredHeight: 16 }
        }
    }
    Timer { id: refreshDelay; interval: 1100; onTriggered: root.refresh() }
    onActiveChanged: if (active) Qt.callLater(refresh)
    Component.onCompleted: if (active) Qt.callLater(refresh)
}
