import QtQuick
import QtQuick.Controls

Rectangle {
    id: root
    property string text: ""
    property string tooltip: ""
    property bool selected: false
    property color selectedColor: backend.accentColor
    property int fontPixelSize: 10
    signal leftClicked()
    signal middleClicked()
    signal rightClicked()
    signal scrolled(int direction)

    activeFocusOnTab: true
    Accessible.role: Accessible.Button
    Accessible.name: root.tooltip !== "" ? root.tooltip.split(" · ")[0] : root.text
    Accessible.description: root.tooltip
    Accessible.focusable: true

    implicitWidth: Math.max(24, label.implicitWidth + 12)
    implicitHeight: 27
    color: selected ? selectedColor : (mouse.pressed ? backend.overlayColor : (mouse.containsMouse ? backend.surfaceColor : "transparent"))
    border.width: selected || mouse.containsMouse || activeFocus ? 1 : 0
    border.color: activeFocus ? backend.accentColor : (selected ? backend.accent2Color : (mouse.containsMouse ? backend.lineColor : "transparent"))
    Behavior on color { ColorAnimation { duration: 90 } }

    Rectangle {
        visible: mouse.containsMouse && !root.selected
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 1
        color: backend.accentColor
    }

    Text {
        id: label
        anchors.centerIn: parent
        text: root.text
        color: root.selected ? backend.baseColor : (mouse.containsMouse ? backend.accentColor : backend.textColor)
        font.family: "MesloLGS Nerd Font Mono"
        font.pixelSize: Math.round(root.fontPixelSize * ((root.Window.window && root.Window.window.barIconScale) ? root.Window.window.barIconScale : 1))
        font.bold: root.selected
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: function(mouse) {
            if (mouse.button === Qt.RightButton) root.rightClicked()
            else if (mouse.button === Qt.MiddleButton) root.middleClicked()
            else root.leftClicked()
        }
        onWheel: function(wheel) { root.scrolled(wheel.angleDelta.y > 0 ? 1 : -1) }
    }
    Keys.onPressed: function(event) {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
            root.leftClicked()
            event.accepted = true
        }
    }
    // The bar itself is only 29 px tall.  An attached ToolTip is constrained to
    // that window and Qt consequently places it over the button.  A window-backed
    // popup can escape the bar bounds and sit beneath the control instead.
    ToolTip {
        id: tip
        parent: root
        x: Math.round((root.width - implicitWidth) / 2)
        y: root.height + 4
        visible: mouse.containsMouse && !mouse.pressed && root.tooltip !== ""
        delay: 750
        timeout: 4000
        text: root.tooltip
        popupType: Popup.Window
    }
}
