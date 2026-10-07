import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"

Rectangle {
    id: root
    color: backend.baseColor
    property bool active: false
    property bool busy: false
    property var state: ({
        cpu:{model:"Checking…",threads:0,profile:"unavailable",governor:"unknown"},
        memory:{totalKiB:0,availableKiB:0,cachedKiB:0,pressureAvg10:0},
        swap:{totalKiB:0,usedKiB:0}, cache:{policy:"KERNEL MANAGED",swappiness:0,vfsCachePressure:0},
        storage:{model:"Checking…",scheduler:"unknown",readaheadKiB:0},
        zram:{active:false,sizeKiB:0,usedKiB:0,algorithm:""},
        services:{generator:false,oomd:"unknown",thermald:"unknown"},
        adaptive:{installed:false,rebootRequired:false}, recommendations:[]
    })
    readonly property string helper: backend.home + "/.config/hypr/scripts/performance-control"

    function refresh() {
        if (!active || busy) return
        var value = backend.json([helper, "status"], 7000)
        if (value) state = value
    }
    function gib(kib) { return (Number(kib || 0) / 1048576).toFixed(1) + " GiB" }
    function pct(used, total) { return Number(total || 0) > 0 ? Math.round(Number(used || 0) * 100 / Number(total)) : 0 }
    function openTerminal(action) {
        var command = ["kitty", "--title", "NOC Performance Lab", "-e", helper, action]
        if (action === "apply") command.push("adaptive")
        backend.start(command)
    }

    ScrollView {
        anchors.fill: parent
        contentWidth: availableWidth
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        ColumnLayout {
            x: 26; width: parent.width - 52; spacing: 14
            Item { Layout.preferredHeight: 10 }
            SettingsPageHeader {
                Layout.fillWidth: true
                eyebrow: "PRESSURE-AWARE COMPUTE"
                title: "Performance Lab"
                description: "Faster under real load without cache purges, unsafe overclocks or a resident optimizer. Hardware is measured only while this page is open."
                badge: root.state.adaptive.installed ? (root.state.adaptive.rebootRequired ? "RESTART TO ACTIVATE" : "ADAPTIVE PROFILE") : "BASELINE"
            }

            GridLayout {
                Layout.fillWidth: true; columns: 4; columnSpacing: 9; rowSpacing: 9
                Repeater {
                    model: [
                        {label:"AVAILABLE RAM",value:root.gib(root.state.memory.availableKiB),detail:root.gib(root.state.memory.cachedKiB) + " reusable cache",good:Number(root.state.memory.pressureAvg10) < 5},
                        {label:"MEMORY PRESSURE",value:Number(root.state.memory.pressureAvg10 || 0).toFixed(2),detail:"10 second average",good:Number(root.state.memory.pressureAvg10) < 5},
                        {label:"ZRAM",value:root.state.zram.active ? root.gib(root.state.zram.sizeKiB) : "OFF",detail:root.state.zram.active ? (root.state.zram.algorithm || "compressed") : "disk swap remains fallback",good:root.state.zram.active || root.state.services.generator},
                        {label:"POWER PROFILE",value:String(root.state.cpu.profile || "unavailable").toUpperCase(),detail:root.state.cpu.governor + " governor",good:root.state.cpu.profile !== "unavailable"}
                    ]
                    Rectangle {
                        required property var modelData
                        Layout.fillWidth: true; implicitHeight: 75
                        color: backend.surfaceColor; border.color: modelData.good ? backend.lineColor : "#8d4b54"
                        Column { anchors.fill: parent; anchors.margins: 10; spacing: 3
                            Text { text: modelData.label; color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 8; font.bold: true; font.letterSpacing: 0.7 }
                            Text { text: modelData.value; color: modelData.good ? backend.accentColor : "#ff8c96"; font.family: "monospace"; font.pixelSize: 14; font.bold: true; elide: Text.ElideRight; width: parent.width }
                            Text { text: modelData.detail; color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 8; elide: Text.ElideRight; width: parent.width }
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true; spacing: 9
                SettingsCard {
                    Layout.fillWidth: true
                    title: "SMART MEMORY"
                    description: "Compressed RAM absorbs bursts before the much slower disk swap. It consumes memory only as pages are stored."
                    glyph: "RAM"
                    GridLayout { Layout.fillWidth: true; columns: 2; rowSpacing: 6
                        Text { text: "SWAP USED"; color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 8; font.bold: true }
                        Text { Layout.fillWidth: true; text: root.gib(root.state.swap.usedKiB) + " / " + root.gib(root.state.swap.totalKiB); horizontalAlignment: Text.AlignRight; color: backend.textColor; font.family: "monospace"; font.pixelSize: 9 }
                        Text { text: "SWAPPINESS"; color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 8; font.bold: true }
                        Text { Layout.fillWidth: true; text: root.state.cache.swappiness; horizontalAlignment: Text.AlignRight; color: backend.accentColor; font.family: "monospace"; font.pixelSize: 9 }
                        Text { text: "OOM GUARD"; color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 8; font.bold: true }
                        Text { Layout.fillWidth: true; text: String(root.state.services.oomd).toUpperCase(); horizontalAlignment: Text.AlignRight; color: backend.textColor; font.family: "monospace"; font.pixelSize: 9 }
                    }
                }
                SettingsCard {
                    Layout.fillWidth: true
                    title: "CACHE + STORAGE"
                    description: "Hot files stay in Linux's page cache automatically. NOC never runs drop_caches or oversized read-ahead."
                    glyph: "NVMe"
                    GridLayout { Layout.fillWidth: true; columns: 2; rowSpacing: 6
                        Text { text: "POLICY"; color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 8; font.bold: true }
                        Text { Layout.fillWidth: true; text: root.state.cache.policy; horizontalAlignment: Text.AlignRight; color: backend.accentColor; font.family: "monospace"; font.pixelSize: 9 }
                        Text { text: "SCHEDULER"; color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 8; font.bold: true }
                        Text { Layout.fillWidth: true; text: root.state.storage.scheduler; horizontalAlignment: Text.AlignRight; color: backend.textColor; font.family: "monospace"; font.pixelSize: 9 }
                        Text { text: "READ-AHEAD"; color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 8; font.bold: true }
                        Text { Layout.fillWidth: true; text: root.state.storage.readaheadKiB + " KiB"; horizontalAlignment: Text.AlignRight; color: backend.textColor; font.family: "monospace"; font.pixelSize: 9 }
                    }
                }
            }

            SettingsCard {
                Layout.fillWidth: true
                title: "ADAPTIVE RECOMMENDATIONS"
                description: root.state.cpu.model + " · " + root.state.cpu.threads + " threads · " + root.state.storage.model
                glyph: "↯"
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 0
                    Repeater {
                        model: root.state.recommendations || []
                        Rectangle {
                            required property var modelData; required property int index
                            Layout.fillWidth: true; implicitHeight: 48
                            color: index % 2 ? backend.baseColor : "transparent"
                            RowLayout { anchors.fill: parent; anchors.leftMargin: 9; anchors.rightMargin: 9; spacing: 10
                                Text { Layout.preferredWidth: 62; text: modelData.impact; color: modelData.impact === "HIGH" || modelData.impact === "REQUIRED" ? "#ffbf69" : backend.accent2Color; font.family: "monospace"; font.pixelSize: 8; font.bold: true }
                                ColumnLayout { Layout.fillWidth: true; spacing: 1
                                    Text { Layout.fillWidth: true; text: modelData.label; color: backend.textColor; font.family: "Inter"; font.pixelSize: 9; font.bold: true; elide: Text.ElideRight }
                                    Text { Layout.fillWidth: true; text: modelData.detail; color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 8; elide: Text.ElideRight }
                                }
                            }
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true; spacing: 9
                NocturneButton { Layout.fillWidth: true; text: root.state.adaptive.installed ? "REAPPLY ADAPTIVE PROFILE" : "APPLY ADAPTIVE PROFILE"; selected: !root.state.adaptive.installed; enabled: root.state.services.generator; onClicked: root.openTerminal("apply") }
                NocturneButton { Layout.fillWidth: true; text: "ROLL BACK"; danger: true; enabled: root.state.adaptive.installed; onClicked: root.openTerminal("rollback") }
                NocturneButton { Layout.fillWidth: true; text: "REFRESH"; onClicked: root.refresh() }
            }
            Text { Layout.fillWidth: true; text: "Applying opens a terminal, shows every system file, and requires typing APPLY. Restart is deliberate: active swap is never replaced underneath a running session."; color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 8; wrapMode: Text.WordWrap }
            Item { Layout.preferredHeight: 16 }
        }
    }

    Timer { interval: 5000; repeat: true; running: root.active; onTriggered: root.refresh() }
    onActiveChanged: if (active) Qt.callLater(refresh)
    Component.onCompleted: if (active) Qt.callLater(refresh)
}
