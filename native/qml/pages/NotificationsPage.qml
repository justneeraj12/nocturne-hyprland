import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"

Rectangle {
    id: root
    implicitWidth: 480
    implicitHeight: Math.min(530, Math.max(278, 184 + shownItems.length * 75))
    color: backend.baseColor
    border.color: backend.accent2Color
    border.width: 1

    property var activeItems: []
    property var historyItems: []
    property bool dnd: false
    property var focusState: ({active:false, remaining:0, label:"Off"})
    property string tab: "current"
    property string query: ""
    property int currentIndex: 0
    readonly property var sourceItems: tab === "current" ? activeItems : historyItems
    readonly property var shownItems: sourceItems.filter(function(item) { var q = root.query.toLowerCase(); return !q || String(item.displayApp + " " + item.summary + " " + item.body).toLowerCase().indexOf(q) >= 0 })

    function refresh() {
        activeItems = backend.notifications("list")
        historyItems = backend.notifications("history")
        dnd = backend.run(["makoctl", "mode"], 1000).split("\n").indexOf("do-not-disturb") >= 0
        focusState = backend.json([backend.home + "/.config/hypr/scripts/focus-mode", "status"], 1200) || focusState
    }

    function dismiss(id) {
        backend.run(["makoctl", "dismiss", "-n", String(id)], 1200)
        refresh()
    }
    function navigate(delta) { if (shownItems.length > 0) currentIndex = (currentIndex + delta + shownItems.length) % shownItems.length }
    function activateCurrent() {
        if (currentIndex < 0 || currentIndex >= shownItems.length) return
        var item = shownItems[currentIndex]
        if (item.hasAction && tab === "current") { backend.run(["makoctl", "invoke", "-n", String(item.id)], 1200); refresh() }
    }
    function deleteCurrent() { if (tab === "current" && currentIndex >= 0 && currentIndex < shownItems.length) dismiss(shownItems[currentIndex].id) }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 7

        RowLayout {
            Layout.fillWidth: true
            PanelHeader { Layout.fillWidth: true; title: "Notifications"; subtitle: root.dnd ? "Do not disturb is on" : "Alerts and recent history" }
            Text { text: "DND"; color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 9; font.bold: true }
            NocturneToggle {
                checked: root.dnd
                onToggleRequested: function(enabled) {
                    backend.run([backend.home + "/.config/hypr/scripts/focus-mode", enabled ? "toggle" : "off"], 1200)
                    root.refresh()
                }
            }
        }

        TextField {
            Layout.fillWidth: true; implicitHeight: 30; placeholderText: "Filter apps and messages"; text: root.query
            color: backend.textColor; placeholderTextColor: backend.mutedColor; font.family: "Inter"; font.pixelSize: 9
            onTextChanged: { root.query = text; root.currentIndex = 0 }
            background: Rectangle { color: backend.surfaceColor; border.color: parent.activeFocus ? backend.accentColor : backend.lineColor }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 5
            Text {
                Layout.fillWidth: true
                text: root.focusState.active ? "FOCUS · " + root.focusState.label.toUpperCase() : "FOCUS TIMER"
                color: root.focusState.active ? backend.accentColor : backend.mutedColor
                font.family: "Inter"; font.pixelSize: 9; font.bold: true
            }
            NocturneButton { text: "30M"; selected: root.focusState.active && root.focusState.remaining > 0 && root.focusState.remaining <= 30; onClicked: { backend.run([backend.home + "/.config/hypr/scripts/focus-mode", "on", "30"], 1500); root.refresh() } }
            NocturneButton { text: "1H"; onClicked: { backend.run([backend.home + "/.config/hypr/scripts/focus-mode", "on", "60"], 1500); root.refresh() } }
            NocturneButton { text: "MORNING"; onClicked: { backend.run([backend.home + "/.config/hypr/scripts/focus-mode", "morning"], 1500); root.refresh() } }
            NocturneButton { visible: root.dnd; text: "OFF"; danger: true; onClicked: { backend.run([backend.home + "/.config/hypr/scripts/focus-mode", "off"], 1200); root.refresh() } }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 5
            NocturneButton {
                Layout.fillWidth: true
                text: "CURRENT  " + root.activeItems.length
                selected: root.tab === "current"
                onClicked: root.tab = "current"
            }
            NocturneButton {
                Layout.fillWidth: true
                text: "HISTORY  " + root.historyItems.length
                selected: root.tab === "history"
                onClicked: root.tab = "history"
            }
        }

        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentWidth: availableWidth

            ColumnLayout {
                width: parent.width
                spacing: 5

                Item {
                    Layout.fillWidth: true
                    implicitHeight: 70
                    visible: root.shownItems.length === 0
                    Text {
                        anchors.centerIn: parent
                        text: root.tab === "current" ? "NO NEW NOTIFICATIONS" : "HISTORY IS EMPTY"
                        color: backend.mutedColor
                        font.family: "monospace"
                        font.pixelSize: 10
                        font.letterSpacing: 0.8
                    }
                }

                Repeater {
                    model: root.shownItems
                    delegate: Rectangle {
                        id: notification
                        required property int index
                        required property var modelData
                        Layout.fillWidth: true
                        implicitHeight: notification.modelData.body ? 88 : 74
                        color: backend.surfaceColor
                        border.width: 1
                        border.color: modelData.urgency === "critical" ? "#c75c66" : (index === root.currentIndex ? backend.accent2Color : backend.lineColor)

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 8

                            Rectangle {
                                implicitWidth: 36
                                implicitHeight: 36
                                color: backend.overlayColor
                                border.color: backend.lineColor
                                Image {
                                    id: notificationIcon
                                    anchors.centerIn: parent
                                    width: 25
                                    height: 25
                                    sourceSize.width: 25
                                    sourceSize.height: 25
                                    fillMode: Image.PreserveAspectFit
                                    source: notification.modelData.icon
                                        ? "image://theme/" + encodeURIComponent(notification.modelData.icon)
                                        : ""
                                    asynchronous: true
                                }
                                Text {
                                    anchors.centerIn: parent
                                    visible: notificationIcon.status !== Image.Ready
                                    text: String(notification.modelData.displayApp || "S").substring(0, 1).toUpperCase()
                                    color: backend.accentColor
                                    font.family: "monospace"
                                    font.pixelSize: 15
                                    font.bold: true
                                }
                                Rectangle {
                                    Layout.fillWidth: true; implicitHeight: 3
                                    visible: Number(notification.modelData.progress) > 0
                                    color: backend.baseColor
                                    Rectangle { width: parent.width * Math.max(0, Math.min(100, Number(notification.modelData.progress))) / 100; height: parent.height; color: backend.accentColor }
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2
                                Text {
                                    Layout.fillWidth: true
                                    text: String(notification.modelData.displayApp || "System").toUpperCase() + (notification.modelData.groupCount > 1 ? "  ×" + notification.modelData.groupCount : "")
                                    color: notification.modelData.urgency === "critical" ? "#ff8c96" : backend.mutedColor
                                    font.family: "Inter"
                                    font.pixelSize: 8
                                    font.bold: true
                                    elide: Text.ElideRight
                                }
                                Text {
                                    Layout.fillWidth: true
                                    text: notification.modelData.summary || "Notification"
                                    color: backend.textColor
                                    font.family: "monospace"
                                    font.pixelSize: 11
                                    font.bold: true
                                    elide: Text.ElideRight
                                }
                                Text {
                                    Layout.fillWidth: true
                                    visible: Boolean(notification.modelData.body)
                                    text: notification.modelData.body || ""
                                    color: backend.mutedColor
                                    font.family: "Inter"
                                    font.pixelSize: 8
                                    elide: Text.ElideRight
                                }
                                Text {
                                    text: root.tab === "current" ? "NOW" : "RECENT"
                                    color: backend.mutedColor
                                    font.family: "Inter"
                                    font.pixelSize: 8
                                }
                            }

                            NocturneButton {
                                visible: Boolean(notification.modelData.code)
                                text: "COPY " + notification.modelData.code
                                onClicked: backend.copyText(notification.modelData.code)
                            }
                            NocturneButton {
                                visible: Boolean(notification.modelData.app)
                                text: "MUTE 1H"
                                onClicked: { backend.run([backend.home + "/.config/hypr/scripts/notification-rules", "mute", notification.modelData.app, "60"], 1500); root.refresh() }
                            }
                            NocturneButton {
                                visible: root.tab === "current" && Boolean(notification.modelData.hasAction)
                                text: "OPEN"
                                onClicked: {
                                    backend.run(["makoctl", "invoke", "-n", String(notification.modelData.id)], 1200)
                                    root.refresh()
                                }
                            }
                            NocturneButton {
                                visible: root.tab === "current"
                                text: "×"
                                danger: true
                                onClicked: root.dismiss(notification.modelData.id)
                            }
                        }
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Text {
                Layout.fillWidth: true
                text: root.tab === "current" ? "Dismissed alerts move to history" : "Mako keeps recent dismissed alerts"
                color: backend.mutedColor
                font.family: "Inter"
                font.pixelSize: 8
                elide: Text.ElideRight
            }
            NocturneButton {
                visible: root.tab === "current" && root.activeItems.length > 0
                text: "ARCHIVE ALL"
                danger: true
                onClicked: { backend.run(["makoctl", "dismiss", "--all"], 1200); root.refresh() }
            }
            NocturneButton {
                visible: root.tab === "history" && root.historyItems.length > 0
                text: "RESTORE LATEST"
                onClicked: { backend.run(["makoctl", "restore"], 1200); root.refresh(); root.tab = "current" }
            }
        }
    }

    Timer { interval: 5000; running: true; repeat: true; onTriggered: root.refresh() }
    Component.onCompleted: refresh()
}
