import QtQuick
import QtQuick.Layouts

Item {
    id: root
    property string eyebrow: "SYSTEM SETTINGS"
    property string title: ""
    property string description: ""
    property string badge: ""

    implicitHeight: heading.implicitHeight + 17

    ColumnLayout {
        id: heading
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: 5

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            Text {
                Layout.fillWidth: true
                text: root.eyebrow
                color: backend.accentColor
                font.family: "Inter"
                font.pixelSize: 9
                font.bold: true
                font.letterSpacing: 1.5
            }
            Rectangle {
                visible: root.badge !== ""
                implicitWidth: badgeText.implicitWidth + 14
                implicitHeight: 21
                color: backend.overlayColor
                border.color: backend.lineColor
                Text {
                    id: badgeText
                    anchors.centerIn: parent
                    text: root.badge
                    color: backend.mutedColor
                    font.family: "monospace"
                    font.pixelSize: 8
                    font.bold: true
                }
            }
        }
        Text {
            Layout.fillWidth: true
            text: root.title
            color: backend.textColor
            font.family: "Inter"
            font.pixelSize: 28
            font.weight: Font.DemiBold
            elide: Text.ElideRight
        }
        Text {
            Layout.fillWidth: true
            text: root.description
            color: backend.mutedColor
            font.family: "Inter"
            font.pixelSize: 11
            lineHeight: 1.25
            wrapMode: Text.WordWrap
        }
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 1
        color: backend.lineColor
    }
}
