import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Button {
    id: control
    property string iconName: "preferences-system"
    property string glyph: ""
    property string title: ""
    property string description: ""
    property string actionText: "OPEN"
    property bool danger: false

    implicitHeight: 88
    hoverEnabled: true
    leftPadding: 13
    rightPadding: 13
    topPadding: 11
    bottomPadding: 11

    contentItem: RowLayout {
        spacing: 11
        Rectangle {
            implicitWidth: 34
            implicitHeight: 34
            color: control.hovered ? backend.overlayColor : backend.baseColor
            border.color: control.danger ? "#613038" : (control.hovered ? backend.accent2Color : backend.lineColor)
            Text {
                visible: control.glyph !== ""
                anchors.centerIn: parent
                text: control.glyph
                color: control.danger ? "#ff8c96" : backend.accentColor
                font.family: "MesloLGS Nerd Font Mono"
                font.pixelSize: 16
                font.bold: true
            }
            Image {
                visible: control.glyph === ""
                anchors.centerIn: parent
                width: 19
                height: 19
                source: control.glyph === "" && control.iconName !== "" ? "image://theme/" + control.iconName : ""
                sourceSize: Qt.size(38, 38)
                fillMode: Image.PreserveAspectFit
            }
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 3
            Text {
                Layout.fillWidth: true
                text: control.title
                color: control.danger ? "#ff8c96" : backend.textColor
                font.family: "Inter"
                font.pixelSize: 11
                font.bold: true
                elide: Text.ElideRight
            }
            Text {
                Layout.fillWidth: true
                text: control.description
                color: backend.mutedColor
                font.family: "Inter"
                font.pixelSize: 9
                lineHeight: 1.15
                wrapMode: Text.WordWrap
                maximumLineCount: 2
                elide: Text.ElideRight
            }
        }
        ColumnLayout {
            spacing: 3
            Text {
                Layout.alignment: Qt.AlignRight
                text: control.actionText
                color: control.danger ? "#ff8c96" : backend.accentColor
                font.family: "monospace"
                font.pixelSize: 8
                font.bold: true
            }
            Text {
                Layout.alignment: Qt.AlignRight
                text: "›"
                color: control.hovered ? backend.textColor : backend.mutedColor
                font.family: "Inter"
                font.pixelSize: 20
            }
        }
    }

    background: Rectangle {
        color: control.hovered ? backend.overlayColor : backend.surfaceColor
        border.width: 1
        border.color: control.danger ? "#613038" : (control.activeFocus || control.hovered ? backend.accent2Color : backend.lineColor)
    }
}
