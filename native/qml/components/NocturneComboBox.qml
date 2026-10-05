import QtQuick
import QtQuick.Controls

ComboBox {
    id: control
    implicitHeight: 34
    leftPadding: 10
    rightPadding: 28
    font.family: "Inter"
    font.pixelSize: 9

    contentItem: Text {
        leftPadding: control.leftPadding
        rightPadding: control.rightPadding
        text: control.displayText || "Choose"
        color: backend.textColor
        font: control.font
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }
    indicator: Text {
        x: control.width - width - 9
        anchors.verticalCenter: parent.verticalCenter
        text: "⌄"
        color: backend.accentColor
        font.family: "Inter"
        font.pixelSize: 13
    }
    background: Rectangle {
        color: control.hovered ? backend.overlayColor : backend.baseColor
        border.color: control.activeFocus || control.popup.visible ? backend.accentColor : backend.lineColor
    }
    delegate: ItemDelegate {
        required property var modelData
        required property int index
        width: control.width
        implicitHeight: 34
        highlighted: control.highlightedIndex === index
        contentItem: Text {
            text: control.textRole ? String(modelData[control.textRole] || "") : String(modelData)
            color: parent.highlighted ? backend.textColor : backend.mutedColor
            font.family: "Inter"
            font.pixelSize: 9
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }
        background: Rectangle { color: parent.highlighted ? backend.overlayColor : backend.surfaceColor }
    }
    popup: Popup {
        y: control.height + 3
        width: control.width
        implicitHeight: Math.min(contentItem.implicitHeight + 2, 240)
        padding: 1
        contentItem: ListView {
            clip: true
            implicitHeight: contentHeight
            model: control.popup.visible ? control.delegateModel : null
            currentIndex: control.highlightedIndex
            ScrollIndicator.vertical: ScrollIndicator {}
        }
        background: Rectangle { color: backend.surfaceColor; border.color: backend.accent2Color }
    }
}
