import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    property string title: ""
    property string description: ""
    property string icon: ""
    property string glyph: ""
    property bool highlighted: false
    default property alias contentData: content.data

    implicitHeight: cardColumn.implicitHeight + 28
    color: highlighted ? backend.overlayColor : backend.surfaceColor
    border.width: 1
    border.color: highlighted ? backend.accent2Color : backend.lineColor

    ColumnLayout {
        id: cardColumn
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 14
        spacing: 10

        RowLayout {
            visible: root.title !== "" || root.icon !== "" || root.glyph !== ""
            Layout.fillWidth: true
            spacing: 9
            Rectangle {
                visible: root.icon !== "" || root.glyph !== ""
                implicitWidth: 30
                implicitHeight: 30
                color: backend.baseColor
                border.color: backend.lineColor
                Text {
                    visible: root.glyph !== ""
                    anchors.centerIn: parent
                    text: root.glyph
                    color: backend.accentColor
                    font.family: "MesloLGS Nerd Font Mono"
                    font.pixelSize: 15
                    font.bold: true
                }
                Image {
                    visible: root.glyph === ""
                    anchors.centerIn: parent
                    width: 17
                    height: 17
                    source: root.glyph === "" && root.icon !== "" ? "image://theme/" + root.icon : ""
                    sourceSize: Qt.size(34, 34)
                    fillMode: Image.PreserveAspectFit
                }
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Text {
                    Layout.fillWidth: true
                    text: root.title
                    color: backend.textColor
                    font.family: "Inter"
                    font.pixelSize: 11
                    font.bold: true
                    font.letterSpacing: 0.3
                    elide: Text.ElideRight
                }
                Text {
                    visible: root.description !== ""
                    Layout.fillWidth: true
                    text: root.description
                    color: backend.mutedColor
                    font.family: "Inter"
                    font.pixelSize: 9
                    wrapMode: Text.WordWrap
                }
            }
        }
        ColumnLayout {
            id: content
            Layout.fillWidth: true
            spacing: 8
        }
    }
}
