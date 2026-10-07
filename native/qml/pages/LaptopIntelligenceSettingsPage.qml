import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"

Rectangle {
    id: root
    color: backend.baseColor
    property bool active: false
    property var state: ({battery:{capacity:-1,status:"unknown",health:-1,cycles:-1,onAc:false},charge:{supported:false,threshold:-1},sleep:{modes:"",current:"",deepAvailable:false},adaptiveSaver:false,lowBattery:20,brightness:{step:5,floor:5},refresh:{lowerOnBattery:false,target:60,limited:false},bluetooth:{startup:"remember",powered:false}})
    readonly property string tool: backend.home + "/.config/hypr/scripts/power-lab"

    function refresh() {
        if (!active) return
        var next = backend.json([tool, "status"], 3500)
        if (next && next.format === "nocturne-power-lab-v2") state = next
    }
    function configure(key, value) {
        backend.run([tool, "configure", key, String(value)], 3500)
        backend.run([tool, "evaluate"], 6000)
        refreshDelay.restart()
    }

    ScrollView {
        anchors.fill: parent; contentWidth: availableWidth; ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        ColumnLayout {
            x: 26; width: parent.width - 52; spacing: 14
            Item { Layout.preferredHeight: 10 }
            SettingsPageHeader {
                Layout.fillWidth: true; eyebrow: "BATTERY + MOBILE HARDWARE"; title: "Laptop Intelligence"
                description: "Hardware-aware policies that wake through the existing context timer, apply reversible changes and add no new resident process."
                badge: root.state.battery.capacity >= 0 ? root.state.battery.capacity + "% · " + String(root.state.battery.status).toUpperCase() : "NO BATTERY DETECTED"
            }
            GridLayout {
                Layout.fillWidth: true; columns: 4; columnSpacing: 9
                Repeater {
                    model: [
                        {label:"BATTERY HEALTH",value:root.state.battery.health >= 0 ? root.state.battery.health + "%" : "UNKNOWN",detail:root.state.battery.cycles >= 0 ? root.state.battery.cycles + " cycles" : "cycle count unavailable"},
                        {label:"POWER SOURCE",value:root.state.battery.onAc ? "AC POWER" : "BATTERY",detail:String(root.state.battery.status).toUpperCase()},
                        {label:"SLEEP MODE",value:String(root.state.sleep.current).toUpperCase() || "UNKNOWN",detail:root.state.sleep.deepAvailable ? "deep sleep available" : "firmware limited"},
                        {label:"REFRESH POLICY",value:root.state.refresh.limited ? "LIMITED" : "NATIVE",detail:root.state.refresh.lowerOnBattery ? root.state.refresh.target + " Hz target" : "automatic limit off"}
                    ]
                    Rectangle { required property var modelData; Layout.fillWidth: true; implicitHeight: 70; color: backend.surfaceColor; border.color: backend.lineColor
                        Column { anchors.fill: parent; anchors.margins: 9; spacing: 3
                            Text { text: modelData.label; color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 8; font.bold: true }
                            Text { text: modelData.value; color: backend.accentColor; font.family: "monospace"; font.pixelSize: 12; font.bold: true }
                            Text { text: modelData.detail; color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 8 }
                        }
                    }
                }
            }
            SettingsCard {
                Layout.fillWidth: true; title: "ADAPTIVE BATTERY SAVER"; description: "Switch to power saver only while discharging below the selected threshold, then restore the exact prior profile on AC or recovery."; icon: "battery-low"; glyph: "⚡"
                RowLayout {
                    Layout.fillWidth: true
                    Text { Layout.fillWidth: true; text: root.state.adaptiveSaver ? "ADAPTIVE SAVER ARMED" : "ADAPTIVE SAVER OFF"; color: root.state.adaptiveSaver ? backend.accentColor : backend.mutedColor; font.family: "monospace"; font.pixelSize: 9; font.bold: true }
                    NocturneToggle { checked: root.state.adaptiveSaver; accessibleName: "Adaptive battery saver"; onToggleRequested: function(value) { root.configure("adaptiveSaver", value ? "true" : "false") } }
                }
                RowLayout {
                    Layout.fillWidth: true; spacing: 6
                    Text { text: "ACTIVATE BELOW"; color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 8; font.bold: true }
                    Repeater { model: [15,20,25,30,40,50]; NocturneButton { required property int modelData; Layout.fillWidth: true; text: modelData + "%"; selected: root.state.lowBattery === modelData; onClicked: root.configure("lowBattery", modelData) } }
                }
            }
            SettingsCard {
                Layout.fillWidth: true; title: "DISPLAY EFFICIENCY"; description: "Optionally select the highest available mode at or below the target while on battery. Original per-monitor modes are recorded and restored on AC."; icon: "video-display"; glyph: "Hz"
                RowLayout {
                    Layout.fillWidth: true
                    Text { Layout.fillWidth: true; text: root.state.refresh.lowerOnBattery ? "BATTERY REFRESH LIMIT ON" : "USE NATIVE REFRESH EVERYWHERE"; color: root.state.refresh.lowerOnBattery ? backend.accentColor : backend.mutedColor; font.family: "monospace"; font.pixelSize: 9; font.bold: true }
                    NocturneToggle { checked: root.state.refresh.lowerOnBattery; accessibleName: "Lower refresh rate on battery"; onToggleRequested: function(value) { root.configure("lowerRefreshOnBattery", value ? "true" : "false") } }
                }
                RowLayout {
                    Layout.fillWidth: true; spacing: 6
                    Text { text: "BATTERY TARGET"; color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 8; font.bold: true }
                    Repeater { model: [40,48,50,60,75,90]; NocturneButton { required property int modelData; Layout.fillWidth: true; text: modelData + " Hz"; selected: root.state.refresh.target === modelData; enabled: root.state.refresh.lowerOnBattery; onClicked: root.configure("batteryRefresh", modelData) } }
                }
            }
            SettingsCard {
                Layout.fillWidth: true; title: "BACKLIGHT BEHAVIOUR"; description: "The hardware keys and brightness card share these values, including a floor that prevents an accidental black screen."; icon: "display-brightness"; glyph: "☼"
                RowLayout {
                    Layout.fillWidth: true; spacing: 6
                    Text { Layout.preferredWidth: 90; text: "KEY STEP"; color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 8; font.bold: true }
                    Repeater { model: [1,2,5,10]; NocturneButton { required property int modelData; Layout.fillWidth: true; text: modelData + "%"; selected: root.state.brightness.step === modelData; onClicked: root.configure("brightnessStep", modelData) } }
                }
                RowLayout {
                    Layout.fillWidth: true; spacing: 6
                    Text { Layout.preferredWidth: 90; text: "MINIMUM"; color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 8; font.bold: true }
                    Repeater { model: [1,2,5,10,15,20]; NocturneButton { required property int modelData; Layout.fillWidth: true; text: modelData + "%"; selected: root.state.brightness.floor === modelData; onClicked: root.configure("brightnessFloor", modelData) } }
                }
            }
            GridLayout {
                Layout.fillWidth: true; columns: 2; columnSpacing: 10
                SettingsCard {
                    Layout.fillWidth: true; Layout.fillHeight: true; title: "BLUETOOTH AT LOGIN"; description: "Remember the last known radio state, or enforce a clear startup policy once when the session starts."; icon: "preferences-system-bluetooth"; glyph: "ᛒ"
                    RowLayout { Layout.fillWidth: true; spacing: 6
                        Repeater { model: [{key:"remember",label:"REMEMBER"},{key:"on",label:"ALWAYS ON"},{key:"off",label:"ALWAYS OFF"}]; NocturneButton { required property var modelData; Layout.fillWidth: true; text: modelData.label; selected: root.state.bluetooth.startup === modelData.key; onClicked: root.configure("bluetoothStartup", modelData.key) } }
                    }
                    Text { text: "RADIO NOW · " + (root.state.bluetooth.powered ? "ON" : "OFF"); color: root.state.bluetooth.powered ? backend.accentColor : backend.mutedColor; font.family: "monospace"; font.pixelSize: 8 }
                }
                SettingsCard {
                    Layout.fillWidth: true; Layout.fillHeight: true; title: "CHARGE LIMIT"; description: root.state.charge.supported ? "Firmware-supported upper charge threshold." : "This firmware does not expose a writable charge threshold."; icon: "battery"; glyph: "%"
                    RowLayout { Layout.fillWidth: true; spacing: 5
                        Repeater { model: [60,70,80,90,100]; NocturneButton { required property int modelData; Layout.fillWidth: true; text: modelData + "%"; selected: root.state.charge.threshold === modelData; enabled: root.state.charge.supported; onClicked: { backend.start([root.tool, "threshold", String(modelData)]); refreshDelay.restart() } } }
                    }
                }
            }
            Item { Layout.preferredHeight: 16 }
        }
    }
    Timer { id: refreshDelay; interval: 1100; onTriggered: root.refresh() }
    Timer { interval: 15000; repeat: true; running: root.active; onTriggered: root.refresh() }
    onActiveChanged: if (active) Qt.callLater(refresh)
    Component.onCompleted: if (active) Qt.callLater(refresh)
}
