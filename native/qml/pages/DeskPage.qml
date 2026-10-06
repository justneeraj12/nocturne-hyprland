import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"

Rectangle {
    id: root
    implicitWidth: 660
    implicitHeight: 575
    color: backend.baseColor; border.color: backend.accent2Color; border.width: 1
    property var summary: ({open:0,today:0,overdue:0,completedToday:0,focus:null})
    property var tasks: []
    property string tab: "open"
    property string priority: "normal"
    property string due: "none"
    property int pendingDelete: 0
    property bool clearArmed: false
    property bool noteLoaded: false
    property bool noteDirty: false
    readonly property string tool: backend.home + "/.config/hypr/scripts/desk"
    readonly property string today: Qt.formatDate(new Date(), "yyyy-MM-dd")
    readonly property var tabs: [
        {key:"open",label:"OPEN"}, {key:"today",label:"TODAY"},
        {key:"done",label:"DONE"}, {key:"all",label:"ALL"}, {key:"note",label:"QUICK NOTE"}
    ]

    function refresh() {
        summary = backend.json([tool, "status"], 1800) || summary
        if (tab === "note") {
            if (!noteLoaded) { note.text = backend.run([tool, "note"], 1200); noteLoaded = true; noteDirty = false }
            tasks = []
        } else {
            tasks = backend.json([tool, "list", tab, search.text], 1800) || []
            if (tasks.length === 0) taskList.currentIndex = -1
            else taskList.currentIndex = Math.max(0, Math.min(taskList.currentIndex, tasks.length - 1))
        }
    }
    function runAction(args) { backend.run([tool].concat(args), 4500); refresh() }
    function addTask() {
        var value = entry.text.trim()
        if (!value) return
        backend.run([tool, "add", value, priority, due], 2500)
        entry.clear(); priority = "normal"; due = "none"; tab = "open"; refresh(); entry.forceActiveFocus()
    }
    function setTab(value) { tab = value; search.clear(); refresh() }
    function navigate(delta) {
        if (!tasks.length) return
        taskList.currentIndex = Math.max(0, Math.min(tasks.length - 1, taskList.currentIndex + delta))
        taskList.positionViewAtIndex(taskList.currentIndex, ListView.Contain)
    }
    function first() { if (tasks.length) { taskList.currentIndex = 0; taskList.positionViewAtBeginning() } }
    function last() { if (tasks.length) { taskList.currentIndex = tasks.length - 1; taskList.positionViewAtEnd() } }
    function page(delta) { navigate(delta * 6) }
    function activateCurrent() { if (taskList.currentIndex >= 0) runAction(["toggle", String(tasks[taskList.currentIndex].id)]) }
    function requestDelete(task) {
        if (pendingDelete !== task.id) { pendingDelete = task.id; deleteReset.restart(); return }
        runAction(["delete", String(task.id)]); pendingDelete = 0
    }
    function deleteCurrent() { if (taskList.currentIndex >= 0) requestDelete(tasks[taskList.currentIndex]) }
    function clearDone() {
        if (!clearArmed) { clearArmed = true; clearReset.restart(); return }
        runAction(["clear-completed"]); clearArmed = false
    }
    function saveNote() { backend.run([tool, "note-set", note.text], 2500); noteDirty = false; summary = backend.json([tool, "status"], 1200) || summary }
    function dueLabel(task) {
        if (!task.due) return "NO DUE DATE"
        if (task.due < today && !task.done) return "OVERDUE · " + task.due
        if (task.due === today) return "TODAY"
        return task.due
    }

    ColumnLayout {
        anchors.fill: parent; anchors.margins: 12; spacing: 8
        RowLayout {
            Layout.fillWidth: true
            PanelHeader { Layout.fillWidth: true; title: "NOC Desk"; subtitle: "Local task inbox, focus deck and scratch note" }
            NocturneButton { text: "HABITS"; onClicked: backend.start([backend.home + "/.local/bin/nocturne-native", "habits"]) }
            NocturneButton { text: "VAULT"; onClicked: backend.start([backend.home + "/.local/bin/nocturne-native", "vault"]) }
            NocturneButton { text: "UNDO"; onClicked: root.runAction(["undo"]) }
            NocturneButton { text: "BRIEF"; onClicked: backend.run([root.tool, "brief"], 1800) }
            NocturneButton {
                text: "EXPORT"
                onClicked: {
                    var path = backend.run([root.tool, "export"], 3500).trim()
                    if (path) backend.start(["notify-send", "-a", "Nocturne", "Desk exported", path])
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true; implicitHeight: 52
            color: backend.surfaceColor; border.color: backend.lineColor
            RowLayout {
                anchors.fill: parent; anchors.margins: 8; spacing: 6
                Repeater {
                    model: [
                        {value:root.summary.open || 0,label:"OPEN",danger:false},
                        {value:root.summary.today || 0,label:"TODAY",danger:false},
                        {value:root.summary.overdue || 0,label:"OVERDUE",danger:(root.summary.overdue || 0) > 0},
                        {value:root.summary.completedToday || 0,label:"DONE TODAY",danger:false}
                    ]
                    Rectangle {
                        required property var modelData
                        Layout.fillWidth: true; Layout.fillHeight: true
                        color: backend.baseColor; border.color: modelData.danger ? "#c75c66" : backend.lineColor
                        Column { anchors.centerIn: parent; spacing: 1
                            Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.value; color: modelData.danger ? "#e17780" : backend.accentColor; font.family: "monospace"; font.pixelSize: 13; font.bold: true }
                            Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.label; color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 7; font.bold: true }
                        }
                    }
                }
                Rectangle {
                    Layout.preferredWidth: 235; Layout.fillHeight: true
                    color: backend.baseColor; border.color: root.summary.focus ? backend.accent2Color : backend.lineColor
                    ColumnLayout { anchors.fill: parent; anchors.margins: 7; spacing: 1
                        Text { text: root.summary.focus ? "CURRENT FOCUS" : "NO ACTIVE FOCUS"; color: root.summary.focus ? backend.accentColor : backend.mutedColor; font.family: "monospace"; font.pixelSize: 7; font.bold: true }
                        Text { Layout.fillWidth: true; text: root.summary.focus ? root.summary.focus.text : "Choose FOCUS on a task"; color: backend.textColor; font.family: "Inter"; font.pixelSize: 9; elide: Text.ElideRight }
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true; spacing: 5
            TextField {
                id: entry; Layout.fillWidth: true; implicitHeight: 38
                placeholderText: "Capture a task…"; color: backend.textColor; placeholderTextColor: backend.mutedColor
                font.family: "monospace"; font.pixelSize: 11; leftPadding: 11
                background: Rectangle { color: backend.surfaceColor; border.color: entry.activeFocus ? backend.accentColor : backend.lineColor }
                Keys.onReturnPressed: root.addTask()
                Keys.onEnterPressed: root.addTask()
            }
            NocturneButton { text: root.priority === "high" ? "HIGH" : (root.priority === "low" ? "LOW" : "NORMAL"); selected: root.priority === "high"; onClicked: root.priority = root.priority === "normal" ? "high" : (root.priority === "high" ? "low" : "normal") }
            NocturneButton { text: root.due === "today" ? "TODAY" : (root.due === "tomorrow" ? "TOMORROW" : "NO DATE"); onClicked: root.due = root.due === "none" ? "today" : (root.due === "today" ? "tomorrow" : "none") }
            NocturneButton { text: "ADD"; selected: true; enabled: entry.text.trim().length > 0; onClicked: root.addTask() }
        }

        RowLayout {
            Layout.fillWidth: true; spacing: 5
            Repeater { model: root.tabs
                NocturneButton { required property var modelData; Layout.fillWidth: true; text: modelData.label; selected: root.tab === modelData.key; onClicked: root.setTab(modelData.key) }
            }
        }

        TextField {
            id: search
            visible: root.tab !== "note"; Layout.fillWidth: true; implicitHeight: 31
            placeholderText: "Filter this view"; color: backend.textColor; placeholderTextColor: backend.mutedColor
            font.family: "Inter"; font.pixelSize: 9; leftPadding: 10
            background: Rectangle { color: backend.baseColor; border.color: search.activeFocus ? backend.accentColor : backend.lineColor }
            onTextChanged: root.refresh()
        }

        ListView {
            id: taskList
            visible: root.tab !== "note"; Layout.fillWidth: true; Layout.fillHeight: true
            model: root.tasks; spacing: 4; clip: true; currentIndex: count ? 0 : -1
            Text {
                anchors.centerIn: parent; visible: root.tasks.length === 0
                text: root.tab === "done" ? "NO COMPLETED TASKS" : "THIS VIEW IS CLEAR"
                color: backend.mutedColor; font.family: "monospace"; font.pixelSize: 10
            }
            delegate: Rectangle {
                required property var modelData; required property int index
                id: taskRow
                property bool editing: false
                width: ListView.view.width; height: 55
                color: ListView.isCurrentItem ? backend.overlayColor : backend.surfaceColor
                border.color: modelData.focus ? backend.accentColor : (ListView.isCurrentItem ? backend.accent2Color : backend.lineColor)
                RowLayout {
                    anchors.fill: parent; anchors.margins: 7; spacing: 7
                    NocturneButton { text: modelData.done ? "✓" : "○"; selected: modelData.done; onClicked: root.runAction(["toggle", String(modelData.id)]) }
                    ColumnLayout { Layout.fillWidth: true; spacing: 1
                        Text { visible: !taskRow.editing; Layout.fillWidth: true; text: modelData.text; color: modelData.done ? backend.mutedColor : backend.textColor; font.family: "Inter"; font.pixelSize: 10; font.bold: modelData.focus || modelData.priority === "high"; font.strikeout: modelData.done; elide: Text.ElideRight }
                        TextField {
                            id: taskEdit; visible: taskRow.editing; Layout.fillWidth: true; implicitHeight: 24
                            text: modelData.text; color: backend.textColor; font.family: "Inter"; font.pixelSize: 9
                            background: Rectangle { color: backend.baseColor; border.color: backend.accentColor }
                            onAccepted: { if (text.trim()) { backend.run([root.tool, "edit", String(modelData.id), text.trim()]); taskRow.editing = false; root.refresh() } }
                        }
                        RowLayout { Layout.fillWidth: true; spacing: 7
                            Text { text: modelData.priority.toUpperCase(); color: modelData.priority === "high" ? "#e17780" : backend.mutedColor; font.family: "monospace"; font.pixelSize: 7; font.bold: true }
                            Text { text: root.dueLabel(modelData); color: modelData.due && modelData.due < root.today && !modelData.done ? "#e17780" : backend.mutedColor; font.family: "monospace"; font.pixelSize: 7 }
                            Text { visible: modelData.pinned; text: "PINNED"; color: backend.accentColor; font.family: "monospace"; font.pixelSize: 7 }
                        }
                    }
                    NocturneButton { visible: !modelData.done; text: modelData.focus ? "FOCUSING" : "FOCUS"; selected: modelData.focus; onClicked: root.runAction(["start", String(modelData.id)]) }
                    NocturneButton { text: modelData.pinned ? "★" : "☆"; selected: modelData.pinned; onClicked: root.runAction(["pin", String(modelData.id)]) }
                    NocturneButton { text: taskRow.editing ? "SAVE" : "EDIT"; onClicked: { if (taskRow.editing && taskEdit.text.trim()) { backend.run([root.tool, "edit", String(modelData.id), taskEdit.text.trim()]); taskRow.editing = false; root.refresh() } else { taskRow.editing = true; taskEdit.forceActiveFocus(); taskEdit.selectAll() } } }
                    NocturneButton { text: root.pendingDelete === modelData.id ? "CONFIRM ×" : "×"; danger: true; onClicked: root.requestDelete(modelData) }
                }
                MouseArea { anchors.fill: parent; z: -1; hoverEnabled: true; onEntered: taskList.currentIndex = index }
            }
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
        }

        Rectangle {
            visible: root.tab === "note"; Layout.fillWidth: true; Layout.fillHeight: true
            color: backend.surfaceColor; border.color: note.activeFocus ? backend.accentColor : backend.lineColor
            TextArea {
                id: note; anchors.fill: parent; anchors.margins: 5
                placeholderText: "Temporary thoughts, links, meeting notes… stored locally."
                color: backend.textColor; placeholderTextColor: backend.mutedColor
                font.family: "monospace"; font.pixelSize: 10; wrapMode: TextEdit.Wrap
                background: null; onTextChanged: if (root.noteLoaded) { root.noteDirty = true; noteSave.restart() }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Text { Layout.fillWidth: true; text: root.tab === "note" ? (root.noteDirty ? "UNSAVED LOCAL NOTE" : "LOCAL NOTE SAVED") : "ENTER ADDS · ↑↓ SELECT · ENTER TOGGLES · DELETE REQUIRES CONFIRMATION"; color: root.noteDirty ? "#ffb36a" : backend.mutedColor; font.family: "monospace"; font.pixelSize: 8 }
            NocturneButton { visible: root.tab === "note"; text: "SAVE NOTE"; selected: root.noteDirty; enabled: root.noteDirty; onClicked: root.saveNote() }
            NocturneButton { visible: root.tab === "done"; text: root.clearArmed ? "CONFIRM CLEAR" : "CLEAR DONE"; danger: true; enabled: root.tasks.length > 0; onClicked: root.clearDone() }
        }
    }

    Timer { id: deleteReset; interval: 6000; onTriggered: root.pendingDelete = 0 }
    Timer { id: clearReset; interval: 6000; onTriggered: root.clearArmed = false }
    Timer { id: noteSave; interval: 900; onTriggered: if (root.noteDirty) root.saveNote() }
    Component.onCompleted: { refresh(); entry.forceActiveFocus() }
}
