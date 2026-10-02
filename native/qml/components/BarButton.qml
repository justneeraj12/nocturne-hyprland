import QtQuick
import QtQuick.Controls

Rectangle {
    id: root
    property string text: ""
    property string tooltip: ""
    property bool selected: false
    property color selectedColor: backend.accentColor
    signal leftClicked()
    signal middleClicked()
    signal rightClicked()
    signal scrolled(int direction)

    implicitWidth: Math.max(24, label.implicitWidth + 12)
    implicitHeight: 27
    color: selected ? selectedColor : "transparent"
    border.width: selected ? 1 : 0
    border.color: selected ? backend.accent2Color : "transparent"

    Text {
        id: label
        anchors.centerIn: parent
        text: root.text
        color: root.selected ? backend.baseColor : backend.textColor
        font.family: "MesloLGS Nerd Font Mono"
        font.pixelSize: 10
        font.bold: root.selected
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        hoverEnabled: true
        onClicked: function(mouse) {
            if (mouse.button === Qt.RightButton) root.rightClicked()
            else if (mouse.button === Qt.MiddleButton) root.middleClicked()
            else root.leftClicked()
        }
        onWheel: function(wheel) { root.scrolled(wheel.angleDelta.y > 0 ? 1 : -1) }
    }
    ToolTip.visible: mouse.containsMouse && root.tooltip !== ""
    ToolTip.delay: 550
    ToolTip.text: root.tooltip
}
