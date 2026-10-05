import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Button {
    id: control
    property string iconName: "preferences-system"
    property string glyph: ""
    property string label: ""
    property bool selected: false
    property bool expanded: true

    implicitHeight: 38
    leftPadding: 10
    rightPadding: 10
    hoverEnabled: true

    contentItem: RowLayout {
        spacing: 11
        Text {
            visible: control.glyph !== ""
            Layout.preferredWidth: 18
            text: control.glyph
            color: control.selected ? backend.accentColor : backend.mutedColor
            font.family: "MesloLGS Nerd Font Mono"
            font.pixelSize: 14
            font.bold: control.selected
            horizontalAlignment: Text.AlignHCenter
        }
        Image {
            visible: control.glyph === ""
            Layout.preferredWidth: 18
            Layout.preferredHeight: 18
            source: control.glyph === "" && control.iconName !== "" ? "image://theme/" + control.iconName : ""
            sourceSize: Qt.size(36, 36)
            fillMode: Image.PreserveAspectFit
        }
        Text {
            visible: control.expanded
            Layout.fillWidth: true
            text: control.label
            color: control.selected ? backend.textColor : backend.mutedColor
            font.family: "Inter"
            font.pixelSize: 10
            font.bold: control.selected
            elide: Text.ElideRight
        }
        Rectangle {
            visible: control.expanded && control.selected
            implicitWidth: 4
            implicitHeight: 4
            color: backend.accentColor
        }
    }
    background: Rectangle {
        color: control.selected ? backend.overlayColor : (control.hovered ? backend.surfaceColor : "transparent")
        border.width: control.selected ? 1 : 0
        border.color: control.selected ? backend.lineColor : "transparent"
        Rectangle {
            visible: control.selected
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 2
            color: backend.accentColor
        }
    }
    ToolTip.visible: !expanded && hovered
    ToolTip.text: label
    ToolTip.delay: 550
}
