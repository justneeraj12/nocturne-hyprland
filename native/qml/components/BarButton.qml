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
    // The bar itself is only 29 px tall.  An attached ToolTip is constrained to
    // that window and Qt consequently places it over the button.  A window-backed
    // popup can escape the bar bounds and sit beneath the control instead.
    ToolTip {
        id: tip
        parent: root
        x: Math.round((root.width - implicitWidth) / 2)
        y: root.height + 4
        visible: mouse.containsMouse && root.tooltip !== ""
        delay: 750
        timeout: 4000
        text: root.tooltip
        popupType: Popup.Window
    }
}
