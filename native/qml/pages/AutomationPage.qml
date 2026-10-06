import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"

Rectangle {
    id: root
    implicitWidth: 570
    implicitHeight: 500
    color: backend.baseColor; border.color: backend.accent2Color; border.width: 1
    property var decision: ({enabled:false,context:"unknown",power:"unknown",profile:"normal",selectedScene:"",reason:"",previousScene:"",changed:false})
    property var events: []
    property bool clearArmed: false
    readonly property string contextTool: backend.home + "/.config/hypr/scripts/context-engine"
    readonly property string traceTool: backend.home + "/.config/hypr/scripts/automation-trace"

    function refresh() {
        decision = backend.json([contextTool, "decision"], 3000) || decision
        events = backend.json([traceTool, "list", "20"], 1800) || []
    }
    function toggleAutomation(enabled) {
        backend.run([contextTool, enabled ? "enable" : "disable"], 6000)
        refresh()
    }
    function clearHistory() {
        if (!clearArmed) { clearArmed = true; clearReset.restart(); return }
        backend.run([traceTool, "clear"], 1500); clearArmed = false; refresh()
    }
    function eventLabel(value) {
        return String(value || "EVENT").replace(/-/g, " ").toUpperCase()
    }
    function reasonLabel(value) {
        return String(value || "manual").replace(/:/g, " · ").replace(/-/g, " ").toUpperCase()
    }

    ColumnLayout {
        anchors.fill: parent; anchors.margins: 12; spacing: 8
        RowLayout {
            Layout.fillWidth: true
            PanelHeader { Layout.fillWidth: true; title: "Nocturne Trace"; subtitle: "Explainable, reversible context automation" }
            NocturneToggle {
                accessibleName: "Context automation"
                checked: Boolean(root.decision.enabled)
                onToggleRequested: function(enabled) { root.toggleAutomation(enabled) }
            }
        }
        Rectangle {
            Layout.fillWidth: true; implicitHeight: 104
            color: backend.surfaceColor
            border.color: root.decision.enabled ? backend.accentColor : backend.lineColor
            ColumnLayout {
                anchors.fill: parent; anchors.margins: 10; spacing: 5
                RowLayout {
                    Layout.fillWidth: true
                    Text { text: root.decision.enabled ? "● AUTOMATION ACTIVE" : "○ AUTOMATION PAUSED"; color: root.decision.enabled ? backend.accentColor : backend.mutedColor; font.family: "monospace"; font.bold: true; font.pixelSize: 10 }
                    Item { Layout.fillWidth: true }
                    Text { text: root.decision.changed ? "CHANGE PENDING" : "STATE STABLE"; color: root.decision.changed ? "#ffb36a" : backend.mutedColor; font.family: "monospace"; font.pixelSize: 8 }
                }
                Text {
                    Layout.fillWidth: true
                    text: "DETECTED  " + String(root.decision.context || "unknown").toUpperCase() + " · " + String(root.decision.power || "unknown").toUpperCase() + " · " + String(root.decision.profile || "normal").toUpperCase()
                    color: backend.textColor; font.family: "Inter"; font.bold: true; font.pixelSize: 9
                }
                Text {
                    Layout.fillWidth: true
                    text: root.decision.selectedScene
                        ? "WHY  " + root.reasonLabel(root.decision.reason) + "   →   " + String(root.decision.selectedScene).toUpperCase()
                        : "WHY  No scene is assigned to the current context, so nothing changes."
                    color: root.decision.selectedScene ? backend.accentColor : backend.mutedColor
                    font.family: "monospace"; font.pixelSize: 9; elide: Text.ElideRight
                }
                Text { Layout.fillWidth: true; text: "Only display, power, audio, wallpaper and theme settings adapt automatically. Applications are never launched by the context engine."; color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 8; wrapMode: Text.WordWrap }
            }
        }
        RowLayout {
            Layout.fillWidth: true
            SectionLabel { Layout.fillWidth: true; text: "LOCAL DECISION HISTORY" }
            Text { text: root.events.length + (root.events.length === 1 ? " EVENT" : " EVENTS"); color: backend.mutedColor; font.family: "monospace"; font.pixelSize: 8 }
            NocturneButton { text: "SCENES"; onClicked: backend.start([backend.home + "/.local/bin/nocturne-native", "scenes"]) }
            NocturneButton { text: root.clearArmed ? "CONFIRM CLEAR" : "CLEAR"; danger: true; enabled: root.events.length > 0; onClicked: root.clearHistory() }
        }
        ListView {
            id: history
            Layout.fillWidth: true; Layout.fillHeight: true
            model: root.events; spacing: 4; clip: true
            Text {
                anchors.centerIn: parent; visible: root.events.length === 0
                text: "NO AUTOMATIC CHANGE HAS BEEN RECORDED"
                color: backend.mutedColor; font.family: "monospace"; font.pixelSize: 9
            }
            delegate: Rectangle {
                required property var modelData
                required property int index
                width: ListView.view.width; height: 48
                color: backend.surfaceColor; border.color: index === 0 ? backend.accent2Color : backend.lineColor
                RowLayout {
                    anchors.fill: parent; anchors.margins: 8; spacing: 9
                    Text { text: modelData.event === "scene-applied" ? "◎" : (modelData.event === "baseline-restored" ? "↶" : "·"); color: backend.accentColor; font.family: "monospace"; font.pixelSize: 15 }
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 1
                        Text { Layout.fillWidth: true; text: root.eventLabel(modelData.event) + (modelData.scene ? "  ·  " + String(modelData.scene).toUpperCase() : ""); color: backend.textColor; font.family: "monospace"; font.bold: true; font.pixelSize: 9; elide: Text.ElideRight }
                        Text { Layout.fillWidth: true; text: root.reasonLabel(modelData.trigger) + (modelData.detail ? "  ·  " + modelData.detail : ""); color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 8; elide: Text.ElideRight }
                    }
                    Text { text: String(modelData.time || "").substring(11, 16); color: backend.mutedColor; font.family: "monospace"; font.pixelSize: 8 }
                }
            }
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
        }
        Text { Layout.fillWidth: true; text: "PRIVATE BY DESIGN · NO APP NAMES, WINDOW TITLES, NETWORKS OR CONTENT"; color: backend.mutedColor; horizontalAlignment: Text.AlignHCenter; font.family: "monospace"; font.pixelSize: 8 }
    }
    Timer { interval: 5000; running: true; repeat: true; triggeredOnStart: true; onTriggered: root.refresh() }
    Timer { id: clearReset; interval: 5000; onTriggered: root.clearArmed = false }
}
