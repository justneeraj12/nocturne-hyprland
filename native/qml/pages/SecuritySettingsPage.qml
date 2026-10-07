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
        coverage:{ready:0,total:7},
        engine:{installed:false,version:"",database:{ready:false,ageDays:-1,fresh:false},scheduled:false},
        firewall:{backend:"none",available:false,enabled:false},
        apparmor:{available:false,enabled:false,enforcedProfiles:0},
        secureBoot:{available:false,enabled:false},
        encryption:{source:"",encrypted:false},
        updates:0,listeningSockets:0,
        lastScan:{finished:"",target:"",mode:"",scanned:0,infected:0,errors:0,result:"never"},
        idleCost:"0 resident scanner processes"
    })
    readonly property string tool: backend.home + "/.config/hypr/scripts/security-control"
    readonly property color dangerColor: "#ff6673"
    readonly property color warningColor: "#d9a85f"

    function refresh() {
        if (!active || busy) return
        var next = backend.json([tool, "status"], 9000)
        if (next && next.format === "nocturne-security-v1") state = next
    }
    function terminal(action, first, second) {
        var args = [tool, "terminal", action]
        if (first) args.push(first)
        if (second) args.push(second)
        backend.start(args)
    }
    function layerColor(ok, available) {
        return ok ? backend.accentColor : (available ? warningColor : backend.mutedColor)
    }
    function scanLabel() {
        if (state.lastScan.result === "never") return "NO SCAN YET"
        if (state.lastScan.result === "clean") return "CLEAN · " + state.lastScan.scanned + " FILES"
        if (state.lastScan.result === "detected") return state.lastScan.infected + " DETECTION(S)"
        return "SCAN NEEDS ATTENTION"
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
                eyebrow: "PREVENTION + DETECTION"
                title: "Security Hub"
                description: "Layered workstation security with an on-demand malware engine. Nothing is uploaded, deleted automatically or kept resident in memory."
                badge: root.state.coverage.ready + "/" + root.state.coverage.total + " LAYERS READY"
            }

            GridLayout {
                Layout.fillWidth: true; columns: 4; columnSpacing: 9; rowSpacing: 9
                Repeater {
                    model: [
                        {label:"ENGINE",value:root.state.engine.installed ? "READY" : "NOT INSTALLED",detail:root.state.engine.installed ? "standalone ClamAV" : "optional local scanner",good:root.state.engine.installed},
                        {label:"DEFINITIONS",value:root.state.engine.database.fresh ? "CURRENT" : (root.state.engine.database.ready ? "STALE" : "MISSING"),detail:root.state.engine.database.ageDays >= 0 ? root.state.engine.database.ageDays + " day(s) old" : "official signatures",good:root.state.engine.database.fresh},
                        {label:"LAST SCAN",value:root.scanLabel(),detail:root.state.lastScan.target ? root.state.lastScan.target + " · " + root.state.lastScan.mode : "on demand",good:root.state.lastScan.result === "clean"},
                        {label:"EXPOSURE",value:root.state.listeningSockets + " SOCKETS",detail:root.state.updates + " package updates",good:root.state.updates === 0}
                    ]
                    Rectangle {
                        required property var modelData
                        Layout.fillWidth: true; implicitHeight: 76
                        color: backend.surfaceColor; border.color: modelData.good ? backend.lineColor : "#6b5634"
                        Column { anchors.fill: parent; anchors.margins: 9; spacing: 4
                            Text { text: modelData.label; color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 8; font.bold: true; font.letterSpacing: 0.8 }
                            Text { width: parent.width; text: modelData.value; color: modelData.good ? backend.accentColor : root.warningColor; font.family: "monospace"; font.pixelSize: 11; font.bold: true; elide: Text.ElideRight }
                            Text { width: parent.width; text: modelData.detail; color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 8; elide: Text.ElideRight }
                        }
                    }
                }
            }

            SettingsCard {
                Layout.fillWidth: true
                title: "LOCAL MALWARE ENGINE"
                description: "Official signed definitions plus archive, ELF, PE, PDF and heuristic inspection. Signatures load only for a scan, then memory is released."
                icon: "security-high"; glyph: "AV"
                RowLayout {
                    Layout.fillWidth: true; spacing: 7
                    NocturneButton { Layout.fillWidth: true; text: root.state.engine.installed ? "UPDATE DEFINITIONS" : "INSTALL ENGINE"; selected: true; onClicked: root.terminal(root.state.engine.installed ? "update" : "install") }
                    NocturneButton { Layout.fillWidth: true; text: "QUICK SCAN"; enabled: root.state.engine.installed && root.state.engine.database.ready; onClicked: root.terminal("scan", "quick", "standard") }
                    NocturneButton { Layout.fillWidth: true; text: "DEEP DOWNLOADS"; enabled: root.state.engine.installed && root.state.engine.database.ready; onClicked: root.terminal("scan", "downloads", "deep") }
                    NocturneButton { text: "LOG"; enabled: root.state.lastScan.result !== "never"; onClicked: root.terminal("log") }
                }
                Text {
                    Layout.fillWidth: true
                    text: "Deep mode includes potentially-unwanted-app and encrypted-content alerts, which can produce false positives. Detections are reported for review; NOC never auto-deletes a file."
                    color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 8; wrapMode: Text.WordWrap
                }
            }

            SettingsCard {
                Layout.fillWidth: true
                title: "PREVENTION LAYERS"
                description: "Containment and platform integrity stop more attacks than signature matching alone."
                icon: "security-medium"; glyph: "▦"
                GridLayout {
                    Layout.fillWidth: true; columns: 2; columnSpacing: 9; rowSpacing: 7
                    Repeater {
                        model: [
                            {name:"APPARMOR",value:root.state.apparmor.enabled ? (root.state.apparmor.enforcedProfiles > 0 ? root.state.apparmor.enforcedProfiles + " ENFORCED" : "ENFORCEMENT ACTIVE") : "NOT ACTIVE",ok:root.state.apparmor.enabled,available:root.state.apparmor.available},
                            {name:"FIREWALL",value:root.state.firewall.enabled ? String(root.state.firewall.backend).toUpperCase() + " ACTIVE" : "DISABLED",ok:root.state.firewall.enabled,available:root.state.firewall.available},
                            {name:"SECURE BOOT",value:root.state.secureBoot.enabled ? "VERIFIED BOOT" : "NOT VERIFIED",ok:root.state.secureBoot.enabled,available:root.state.secureBoot.available},
                            {name:"DISK ENCRYPTION",value:root.state.encryption.encrypted ? "ROOT ENCRYPTED" : "NOT DETECTED",ok:root.state.encryption.encrypted,available:true}
                        ]
                        Rectangle {
                            required property var modelData
                            Layout.fillWidth: true; implicitHeight: 48
                            color: backend.baseColor; border.color: backend.lineColor
                            RowLayout { anchors.fill: parent; anchors.margins: 9; spacing: 8
                                Text { text: modelData.ok ? "●" : "○"; color: root.layerColor(modelData.ok, modelData.available); font.pixelSize: 13 }
                                Text { Layout.fillWidth: true; text: modelData.name; color: backend.textColor; font.family: "Inter"; font.pixelSize: 9; font.bold: true }
                                Text { text: modelData.value; color: root.layerColor(modelData.ok, modelData.available); font.family: "monospace"; font.pixelSize: 8; font.bold: true }
                            }
                        }
                    }
                }
                RowLayout {
                    Layout.fillWidth: true; spacing: 7
                    NocturneButton { Layout.fillWidth: true; text: root.state.firewall.enabled ? "FIREWALL ACTIVE" : "ENABLE FIREWALL"; enabled: root.state.firewall.available && !root.state.firewall.enabled; onClicked: root.terminal("firewall") }
                    NocturneButton { Layout.fillWidth: true; text: "VERIFY PACKAGES"; onClicked: root.terminal("integrity") }
                }
            }

            SettingsCard {
                Layout.fillWidth: true
                title: "AUTOMATION WITHOUT A DAEMON"
                description: root.state.idleCost + ". A systemd timer wakes briefly for definition updates and a weekly quick scan."
                icon: "appointment-new"; glyph: "◷"
                RowLayout {
                    Layout.fillWidth: true; spacing: 8
                    Text { Layout.fillWidth: true; text: root.state.engine.scheduled ? "DAILY DEFINITIONS · WEEKLY QUICK SCAN" : "SCHEDULED PROTECTION IS OFF"; color: root.state.engine.scheduled ? backend.accentColor : backend.mutedColor; font.family: "monospace"; font.pixelSize: 9; font.bold: true }
                    NocturneButton {
                        text: root.state.engine.scheduled ? "DISABLE" : "ENABLE"
                        selected: !root.state.engine.scheduled
                        enabled: root.state.engine.installed
                        onClicked: { backend.run([root.tool, "schedule", root.state.engine.scheduled ? "false" : "true"], 8000); scheduleRefresh.restart() }
                    }
                    NocturneButton { text: "FULL HOME SCAN"; enabled: root.state.engine.installed && root.state.engine.database.ready; onClicked: root.terminal("scan", "home", "standard") }
                    NocturneButton { text: "REFRESH"; onClicked: root.refresh() }
                }
            }
            Text {
                Layout.fillWidth: true
                text: "Security Hub is a control surface, not a guarantee. Keep software updated, use trusted repositories and review unexpected detections before taking action."
                color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 8; wrapMode: Text.WordWrap
            }
            Item { Layout.preferredHeight: 16 }
        }
    }

    Timer { id: scheduleRefresh; interval: 800; onTriggered: root.refresh() }
    Timer { interval: 15000; repeat: true; running: root.active; onTriggered: root.refresh() }
    onActiveChanged: if (active) Qt.callLater(refresh)
    Component.onCompleted: if (active) Qt.callLater(refresh)
}
