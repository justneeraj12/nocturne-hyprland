import QtQuick

Rectangle {
    id: root
    property bool checked: false
    property bool available: true
    signal toggleRequested(bool enabled)

    activeFocusOnTab: available
    Accessible.role: Accessible.CheckBox
    Accessible.name: checked ? "Enabled" : "Disabled"
    Accessible.checked: checked
    Accessible.focusable: available

    implicitWidth: 58
    implicitHeight: 25
    color: checked ? backend.accentColor : backend.surfaceColor
    border.width: activeFocus ? 2 : 1
    border.color: !available ? backend.lineColor : (activeFocus ? backend.textColor : (checked ? backend.accentColor : backend.mutedColor))
    opacity: available ? 1 : 0.45

    Rectangle {
        width: 20
        height: 17
        y: 4
        x: root.checked ? parent.width - width - 4 : 4
        color: root.checked ? backend.baseColor : backend.mutedColor
        Behavior on x { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
    }

    Text {
        x: root.checked ? 7 : 30
        anchors.verticalCenter: parent.verticalCenter
        text: root.checked ? "ON" : "OFF"
        color: root.checked ? backend.baseColor : backend.textColor
        font.family: "Inter"
        font.pixelSize: 8
        font.bold: true
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.available
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggleRequested(!root.checked)
    }
    Keys.onPressed: function(event) {
        if (root.available && (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter)) {
            root.toggleRequested(!root.checked)
            event.accepted = true
        }
    }
}
