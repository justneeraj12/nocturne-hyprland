import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"

Rectangle {
    id: root
    implicitWidth: 580; implicitHeight: 570
    color: backend.baseColor; border.color: backend.accent2Color; border.width: 1
    property var summary: ({active:0,doneToday:0,dueToday:0})
    property var habits: []
    property string tab: "active"
    property int target: 5
    property int pendingDelete: 0
    readonly property string tool: backend.home + "/.config/hypr/scripts/habits"

    function refresh() {
        summary = backend.json([tool, "status"], 1800) || summary
        habits = backend.json([tool, "list", tab, search.text], 2200) || []
        list.currentIndex = habits.length ? Math.max(0, Math.min(list.currentIndex, habits.length - 1)) : -1
    }
    function runAction(args) { backend.run([tool].concat(args), 4000); refresh() }
    function addHabit() {
        var value = entry.text.trim(); if (!value) return
        backend.run([tool, "add", value, String(target)], 2500)
        entry.clear(); tab = "active"; refresh(); entry.forceActiveFocus()
    }
    function navigate(delta) { if (habits.length) { list.currentIndex = Math.max(0, Math.min(habits.length - 1, list.currentIndex + delta)); list.positionViewAtIndex(list.currentIndex, ListView.Contain) } }
    function first() { if (habits.length) { list.currentIndex = 0; list.positionViewAtBeginning() } }
    function last() { if (habits.length) { list.currentIndex = habits.length - 1; list.positionViewAtEnd() } }
    function page(delta) { navigate(delta * 6) }
    function activateCurrent() { if (list.currentIndex >= 0) runAction(["check", String(habits[list.currentIndex].id)]) }
    function requestDelete(item) { if (pendingDelete !== item.id) { pendingDelete = item.id; deleteReset.restart(); return } runAction(["delete", String(item.id)]); pendingDelete = 0 }
    function deleteCurrent() { if (list.currentIndex >= 0) requestDelete(habits[list.currentIndex]) }

    ColumnLayout {
        anchors.fill: parent; anchors.margins: 12; spacing: 8
        RowLayout {
            Layout.fillWidth: true
            PanelHeader { Layout.fillWidth: true; title: "NOC Habits"; subtitle: "Private check-ins, weekly pacing and streaks" }
            NocturneButton { text: "DESK"; onClicked: backend.start([backend.home + "/.local/bin/nocturne-native", "desk"]) }
            NocturneButton { text: "VAULT"; onClicked: backend.start([backend.home + "/.local/bin/nocturne-native", "vault"]) }
            NocturneButton { text: "UNDO"; onClicked: root.runAction(["undo"]) }
            NocturneButton { text: "EXPORT"; onClicked: { var path = backend.run([root.tool, "export"], 3500).trim(); if (path) backend.start(["notify-send", "-a", "Nocturne", "Habits exported", path]) } }
        }
        RowLayout {
            Layout.fillWidth: true; spacing: 6
            Repeater { model: [{v:root.summary.active || 0,l:"ACTIVE"},{v:root.summary.doneToday || 0,l:"CHECKED TODAY"},{v:root.summary.dueToday || 0,l:"PACED DUE"}]
                Rectangle { required property var modelData; Layout.fillWidth: true; implicitHeight: 46; color: backend.surfaceColor; border.color: modelData.l === "PACED DUE" && modelData.v > 0 ? "#e17780" : backend.lineColor
                    Column { anchors.centerIn: parent; spacing: 1
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.v; color: backend.accentColor; font.family: "monospace"; font.pixelSize: 13; font.bold: true }
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.l; color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 7; font.bold: true }
                    }
                }
            }
        }
        RowLayout {
            Layout.fillWidth: true; spacing: 5
            TextField { id: entry; Layout.fillWidth: true; implicitHeight: 37; placeholderText: "Add a habit…"; color: backend.textColor; placeholderTextColor: backend.mutedColor; font.family: "monospace"; font.pixelSize: 10; leftPadding: 10; background: Rectangle { color: backend.surfaceColor; border.color: entry.activeFocus ? backend.accentColor : backend.lineColor } onAccepted: root.addHabit() }
            NocturneButton { text: target + "× / WEEK"; onClicked: target = target === 1 ? 3 : (target === 3 ? 5 : (target === 5 ? 7 : 1)) }
            NocturneButton { text: "ADD"; selected: true; enabled: entry.text.trim().length > 0; onClicked: root.addHabit() }
        }
        RowLayout {
            Layout.fillWidth: true; spacing: 5
            Repeater { model: [{k:"active",l:"ACTIVE"},{k:"archived",l:"ARCHIVED"},{k:"all",l:"ALL"}]
                NocturneButton { required property var modelData; Layout.fillWidth: true; text: modelData.l; selected: root.tab === modelData.k; onClicked: { root.tab = modelData.k; search.clear(); root.refresh() } }
            }
        }
        TextField { id: search; Layout.fillWidth: true; implicitHeight: 31; placeholderText: "Filter habits"; color: backend.textColor; placeholderTextColor: backend.mutedColor; font.family: "Inter"; font.pixelSize: 9; leftPadding: 10; background: Rectangle { color: backend.baseColor; border.color: search.activeFocus ? backend.accentColor : backend.lineColor } onTextChanged: root.refresh() }
        ListView {
            id: list; Layout.fillWidth: true; Layout.fillHeight: true; model: root.habits; spacing: 5; clip: true; currentIndex: count ? 0 : -1
            Text { anchors.centerIn: parent; visible: !root.habits.length; text: root.tab === "archived" ? "NO ARCHIVED HABITS" : "ADD THE FIRST SIGNAL"; color: backend.mutedColor; font.family: "monospace"; font.pixelSize: 10 }
            delegate: Rectangle {
                required property var modelData; required property int index
                id: row; property bool editing: false
                width: ListView.view.width; height: 62; color: ListView.isCurrentItem ? backend.overlayColor : backend.surfaceColor; border.color: modelData.doneToday ? backend.accentColor : (ListView.isCurrentItem ? backend.accent2Color : backend.lineColor)
                RowLayout { anchors.fill: parent; anchors.margins: 7; spacing: 7
                    NocturneButton { text: modelData.doneToday ? "✓" : "○"; selected: modelData.doneToday; onClicked: root.runAction(["check", String(modelData.id)]) }
                    ColumnLayout { Layout.fillWidth: true; spacing: 2
                        Text { visible: !row.editing; Layout.fillWidth: true; text: modelData.name; color: modelData.archived ? backend.mutedColor : backend.textColor; font.family: "Inter"; font.pixelSize: 10; font.bold: modelData.streak > 2; elide: Text.ElideRight }
                        TextField { id: edit; visible: row.editing; Layout.fillWidth: true; implicitHeight: 24; text: modelData.name; color: backend.textColor; font.family: "Inter"; font.pixelSize: 9; background: Rectangle { color: backend.baseColor; border.color: backend.accentColor } }
                        RowLayout { spacing: 9
                            Text { text: modelData.weekCount + "/" + modelData.target + " THIS WEEK"; color: backend.accentColor; font.family: "monospace"; font.pixelSize: 7; font.bold: true }
                            Text { text: modelData.progress + "%"; color: backend.mutedColor; font.family: "monospace"; font.pixelSize: 7 }
                            Text { text: modelData.streak + " DAY STREAK"; color: modelData.streak > 0 ? "#ffb36a" : backend.mutedColor; font.family: "monospace"; font.pixelSize: 7 }
                        }
                    }
                    NocturneButton { text: row.editing ? "SAVE" : "EDIT"; onClicked: { if (row.editing && edit.text.trim()) { backend.run([root.tool,"edit",String(modelData.id),edit.text.trim(),String(modelData.target)], 2500); row.editing=false; root.refresh() } else { row.editing=true; edit.forceActiveFocus(); edit.selectAll() } } }
                    NocturneButton { text: modelData.archived ? "RESTORE" : "ARCHIVE"; onClicked: root.runAction(["archive", String(modelData.id)]) }
                    NocturneButton { text: root.pendingDelete === modelData.id ? "CONFIRM ×" : "×"; danger: true; onClicked: root.requestDelete(modelData) }
                }
                MouseArea { anchors.fill: parent; z: -1; hoverEnabled: true; onEntered: list.currentIndex = index }
            }
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
        }
        Text { Layout.fillWidth: true; text: "ENTER CHECKS · WEEKLY TARGETS NEVER PUNISH MISSED DAYS · DATA STAYS LOCAL"; color: backend.mutedColor; font.family: "monospace"; font.pixelSize: 8 }
    }
    Timer { id: deleteReset; interval: 6000; onTriggered: root.pendingDelete = 0 }
    Component.onCompleted: { refresh(); entry.forceActiveFocus() }
}
