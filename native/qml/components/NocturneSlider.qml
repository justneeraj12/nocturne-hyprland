import QtQuick
import QtQuick.Controls

Slider {
    id: control
    property string accessibleName: "Value"
    from: 0
    to: 100
    implicitHeight: 24
    Accessible.name: accessibleName
    background: Rectangle {
        x: control.leftPadding
        y: control.topPadding + control.availableHeight / 2 - height / 2
        width: control.availableWidth
        height: 5
        color: backend.lineColor
        Rectangle {
            width: control.visualPosition * parent.width
            height: parent.height
            color: backend.accentColor
        }
    }
    handle: Rectangle {
        x: control.leftPadding + control.visualPosition * (control.availableWidth - width)
        y: control.topPadding + control.availableHeight / 2 - height / 2
        implicitWidth: 13
        implicitHeight: 13
        color: backend.textColor
        border.color: backend.accent2Color
    }
}
