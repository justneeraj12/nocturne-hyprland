import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"

Rectangle {
    id: root
    implicitWidth: 410
    implicitHeight: panel.implicitHeight + 20
    color: backend.baseColor
    border.color: backend.accent2Color
    border.width: 1
    property date shown: new Date()
    property date selected: new Date()
    property date now: new Date()
    readonly property int year: shown.getFullYear()
    readonly property int month: shown.getMonth()
    readonly property int firstOffset: (new Date(year, month, 1).getDay() + 6) % 7
    readonly property int days: new Date(year, month + 1, 0).getDate()

    function sameDay(a, b) { return a.toDateString() === b.toDateString() }
    function shiftMonth(offset) { shown = new Date(year, month + offset, 1); selected = shown }

    ColumnLayout {
        id: panel
        x: 10
        y: 10
        width: parent.width - 20
        spacing: 7
        PanelHeader { Layout.fillWidth: true; title: "Calendar"; subtitle: "Local date and time" }
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: Qt.formatTime(root.now, "h:mm AP")
            color: backend.textColor; font.family: "monospace"; font.pixelSize: 25; font.bold: true
        }
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: Qt.formatDate(root.now, "dddd · dd MMMM yyyy")
            color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 10
        }
        RowLayout {
            Layout.fillWidth: true
            NocturneButton { text: "‹"; onClicked: root.shiftMonth(-1) }
            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: Qt.formatDate(root.shown, "MMMM yyyy").toUpperCase()
                color: backend.textColor; font.family: "Inter"; font.pixelSize: 16; font.bold: true
            }
            NocturneButton { text: "›"; onClicked: root.shiftMonth(1) }
        }
        GridLayout {
            Layout.fillWidth: true
            columns: 7
            rowSpacing: 3; columnSpacing: 3
            Repeater {
                model: ["MO","TU","WE","TH","FR","SA","SU"]
                SectionLabel {
                    required property string modelData
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: modelData
                }
            }
            Repeater {
                model: 42
                NocturneButton {
                    required property int index
                    readonly property int day: index - root.firstOffset + 1
                    readonly property date itemDate: new Date(root.year, root.month, Math.max(1, day))
                    Layout.fillWidth: true
                    visible: day > 0 && day <= root.days
                    text: visible ? String(day) : ""
                    selected: visible && (root.sameDay(itemDate, root.selected) || root.sameDay(itemDate, root.now))
                    onClicked: root.selected = itemDate
                }
            }
        }
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: Qt.formatDate(root.selected, "dddd · dd MMMM")
            color: backend.textColor; font.family: "monospace"; font.bold: true
        }
        NocturneButton {
            Layout.fillWidth: true; text: "TODAY"; selected: true
            onClicked: { root.shown = new Date(); root.selected = new Date() }
        }
    }
    Timer { interval: 1000; running: true; repeat: true; onTriggered: root.now = new Date() }
}
