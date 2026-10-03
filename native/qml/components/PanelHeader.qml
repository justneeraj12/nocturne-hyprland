import QtQuick

Item {
    id: root
    property string title: ""
    property string subtitle: ""
    implicitWidth: 240
    implicitHeight: subtitle === "" ? 24 : 36

    Column {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: 2

        Text {
            width: parent.width
            text: root.title.toUpperCase()
            color: backend.textColor
            font.family: "Inter"
            font.pixelSize: 11
            font.bold: true
            font.letterSpacing: 0.8
            elide: Text.ElideRight
        }
        Text {
            visible: root.subtitle !== ""
            width: parent.width
            text: root.subtitle
            color: backend.mutedColor
            font.family: "Inter"
            font.pixelSize: 9
            elide: Text.ElideRight
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
