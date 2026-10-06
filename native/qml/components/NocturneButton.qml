import QtQuick
import QtQuick.Controls

Button {
    id: control
    property bool selected: false
    property bool danger: false
    implicitHeight: 31
    leftPadding: 10
    rightPadding: 10
    font.family: "Inter"
    font.pixelSize: 11
    font.bold: selected
    hoverEnabled: true
    Accessible.name: text
    Accessible.description: danger ? "Destructive action" : ""
    contentItem: Text {
        text: control.text
        color: control.danger ? "#ff8c96" : (control.selected ? backend.baseColor : backend.textColor)
        font: control.font
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }
    background: Rectangle {
        color: control.selected ? backend.accentColor : (control.hovered ? backend.overlayColor : backend.surfaceColor)
        border.width: 1
        border.color: control.danger ? "#613038" : (control.hovered || control.selected ? backend.accentColor : backend.lineColor)
    }
}
