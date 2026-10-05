import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"

Rectangle {
    id: root
    color: backend.baseColor
    property bool active: false
    property bool cleanupArmed: false
    property bool busy: false
    property var state: ({
        memory:{percent:0,pressureAvg10:0}, swap:{totalKiB:0,usedKiB:0},
        shell:{barMiB:0,barRssMiB:0,barCpu:0,legacyProcesses:0},
        session:{activeUnits:0,failedUnits:0,portal:false,healthTimer:false,slowestStartup:"Checking…"},
        cleanup:{staleThumbnailLabel:"0 B",last:"",reclaimed:""}, top:[]
    })
    readonly property string helper: backend.home + "/.config/hypr/scripts/efficiency-control"

    function refresh() {
        if (!active || busy) return
        var value = backend.json([helper, "status"], 7000)
        if (value) state = value
    }
    function optimize() {
        if (!cleanupArmed) { cleanupArmed = true; cleanupReset.restart(); return }
        busy = true
        var value = backend.json([helper, "optimize"], 12000)
        if (value) state = value
        busy = false
        cleanupArmed = false
    }
    function gib(kib) { return (Number(kib || 0) / 1048576).toFixed(1) + " GiB" }

    Timer { id: refreshTimer; interval: 5000; repeat: true; running: root.active; onTriggered: root.refresh() }
    Timer { id: cleanupReset; interval: 5000; onTriggered: root.cleanupArmed = false }

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
                eyebrow: "RESOURCES + STARTUP"
                title: "Efficiency center"
                description: "Live pressure, shell cost and session health. Nothing polls in the background while this page is closed."
                badge: root.state.session.failedUnits === 0 ? "SESSION HEALTHY" : root.state.session.failedUnits + " FAILED UNITS"
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 4
                columnSpacing: 9
                rowSpacing: 9
                Repeater {
                    model: [
                        {label:"MEMORY",value:root.state.memory.percent + "%",detail:root.gib(root.state.memory.usedKiB) + " in use",good:root.state.memory.percent < 80},
                        {label:"PRESSURE",value:Number(root.state.memory.pressureAvg10 || 0).toFixed(2),detail:"10 second average",good:Number(root.state.memory.pressureAvg10 || 0) < 5},
                        {label:"NATIVE BAR",value:root.state.shell.barMiB + " MiB",detail:"PSS · " + root.state.shell.barRssMiB + " MiB RSS · " + Number(root.state.shell.barCpu || 0).toFixed(1) + "% CPU",good:Number(root.state.shell.barCpu || 0) < 5},
                        {label:"SESSION",value:root.state.session.activeUnits + " units",detail:root.state.session.failedUnits + " failed",good:root.state.session.failedUnits === 0}
                    ]
                    Rectangle {
                        required property var modelData
                        Layout.fillWidth: true
                        implicitHeight: 72
                        color: backend.surfaceColor
                        border.color: modelData.good ? backend.lineColor : "#8d4b54"
                        Column {
                            anchors.fill: parent; anchors.margins: 10; spacing: 3
                            Text { text: modelData.label; color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 8; font.bold: true; font.letterSpacing: 0.8 }
                            Text { text: modelData.value; color: modelData.good ? backend.accentColor : "#ff8c96"; font.family: "monospace"; font.pixelSize: 15; font.bold: true }
                            Text { text: modelData.detail; color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 8 }
                        }
                    }
                }
            }

            SettingsCard {
                Layout.fillWidth: true
                title: "TOP MEMORY CONSUMERS"
                description: "A snapshot only; process names are shown without inspecting application content."
                icon: "utilities-system-monitor"
                glyph: "RAM"
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    Repeater {
                        model: root.state.top || []
                        Rectangle {
                            required property var modelData
                            required property int index
                            Layout.fillWidth: true
                            implicitHeight: 32
                            color: index % 2 ? backend.baseColor : "transparent"
                            RowLayout {
                                anchors.fill: parent; anchors.leftMargin: 9; anchors.rightMargin: 9; spacing: 8
                                Text { Layout.preferredWidth: 22; text: String(index + 1).padStart(2, "0"); color: backend.accent2Color; font.family: "monospace"; font.pixelSize: 8 }
                                Text { Layout.fillWidth: true; text: modelData.name + (Number(modelData.count || 1) > 1 ? "  ×" + modelData.count : ""); color: backend.textColor; font.family: "Inter"; font.pixelSize: 9; elide: Text.ElideRight }
                                Text { Layout.preferredWidth: 72; text: Number(modelData.mib).toFixed(0) + " MiB"; color: backend.textColor; font.family: "monospace"; font.pixelSize: 9; horizontalAlignment: Text.AlignRight }
                                Text { Layout.preferredWidth: 54; text: Number(modelData.cpu).toFixed(1) + "%"; color: backend.mutedColor; font.family: "monospace"; font.pixelSize: 9; horizontalAlignment: Text.AlignRight }
                            }
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 9
                SettingsCard {
                    Layout.fillWidth: true
                    title: "SESSION HEALTH"
                    description: root.state.session.slowestStartup
                    icon: "dialog-ok"
                    glyph: "✓"
                    GridLayout {
                        Layout.fillWidth: true; columns: 2; columnSpacing: 8; rowSpacing: 7
                        Text { text: "SCREEN SHARE PORTAL"; color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 8; font.bold: true }
                        Text { text: root.state.session.portal ? "ACTIVE" : "OFFLINE"; color: root.state.session.portal ? backend.accentColor : "#ff8c96"; font.family: "monospace"; font.pixelSize: 8; font.bold: true; horizontalAlignment: Text.AlignRight; Layout.fillWidth: true }
                        Text { text: "STARTUP RECOVERY"; color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 8; font.bold: true }
                        Text { text: root.state.session.healthTimer ? "ARMED" : "DISABLED"; color: root.state.session.healthTimer ? backend.accentColor : "#ff8c96"; font.family: "monospace"; font.pixelSize: 8; font.bold: true; horizontalAlignment: Text.AlignRight; Layout.fillWidth: true }
                        Text { text: "LEGACY SHELLS"; color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 8; font.bold: true }
                        Text { text: root.state.shell.legacyProcesses === 0 ? "NONE" : root.state.shell.legacyProcesses; color: root.state.shell.legacyProcesses === 0 ? backend.accentColor : "#ff8c96"; font.family: "monospace"; font.pixelSize: 8; font.bold: true; horizontalAlignment: Text.AlignRight; Layout.fillWidth: true }
                    }
                }
                SettingsCard {
                    Layout.fillWidth: true
                    title: "SAFE CLEANUP"
                    description: root.state.cleanup.last ? "Last: " + root.state.cleanup.last + " · reclaimed " + root.state.cleanup.reclaimed : "No cleanup has been run yet."
                    icon: "edit-clear-history"
                    glyph: "⌫"
                    Text {
                        Layout.fillWidth: true
                        text: root.state.cleanup.staleThumbnailLabel + " of regenerable thumbnails older than 30 days. User logs are retained for 14 days. Personal files and packages are never touched."
                        color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 9; wrapMode: Text.WordWrap
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 9
                NocturneButton { Layout.fillWidth: true; text: "OPEN RESOURCE DASHBOARD"; selected: true; onClicked: backend.start([backend.home + "/.local/bin/nocturne-dashboard"]) }
                NocturneButton { Layout.fillWidth: true; text: root.busy ? "OPTIMIZING…" : (root.cleanupArmed ? "CLICK AGAIN TO CONFIRM" : "SAFE CLEANUP"); danger: root.cleanupArmed; enabled: !root.busy; onClicked: root.optimize() }
                NocturneButton { Layout.fillWidth: true; text: "REFRESH"; enabled: !root.busy; onClicked: root.refresh() }
            }
            Item { Layout.preferredHeight: 16 }
        }
    }

    onActiveChanged: if (active) Qt.callLater(refresh)
    Component.onCompleted: if (active) Qt.callLater(refresh)
}
