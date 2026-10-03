import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"

Rectangle {
    id: root
    implicitWidth: 410
    implicitHeight: Math.max(116, panel.implicitHeight + 20)
    color: backend.baseColor
    border.color: backend.accent2Color
    border.width: 1
    property var items: backend.trayItems()

    function refresh() { items = backend.trayItems() }

    ColumnLayout {
        id: panel
        x: 10
        y: 10
        width: parent.width - 20
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            PanelHeader { Layout.fillWidth: true; title: "Background apps"; subtitle: "Click to open · right-click for menu" }
            Text {
                text: root.items.length
                color: backend.accentColor
                font.family: "monospace"
                font.pixelSize: 12
                font.bold: true
            }
        }

        Text {
            Layout.fillWidth: true
            visible: root.items.length === 0
            text: "No background apps are exposing tray controls."
            color: backend.mutedColor
            font.family: "Inter"
            font.pixelSize: 10
        }

        Grid {
            id: trayGrid
            Layout.fillWidth: true
            Layout.preferredHeight: root.items.length === 0 ? 0 : Math.ceil(root.items.length / columns) * 75 - spacing
            columns: 3
            spacing: 5

            Repeater {
                model: root.items
                delegate: Rectangle {
                    id: tile
                    required property var modelData
                    width: (trayGrid.width - trayGrid.spacing * (trayGrid.columns - 1)) / trayGrid.columns
                    height: 70
                    color: tileMouse.containsMouse ? backend.overlayColor : backend.surfaceColor
                    border.width: 1
                    border.color: tileMouse.containsMouse ? backend.accentColor : backend.lineColor

                    Rectangle {
                        width: 4
                        height: 4
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.margins: 6
                        color: String(tile.modelData.status).toLowerCase() === "active" ? backend.accentColor : backend.mutedColor
                    }

                    Image {
                        id: appIcon
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top
                        anchors.topMargin: 8
                        width: 30
                        height: 30
                        sourceSize.width: 30
                        sourceSize.height: 30
                        fillMode: Image.PreserveAspectFit
                        source: tile.modelData.icon ? "image://theme/" + encodeURIComponent(tile.modelData.icon) : ""
                        asynchronous: true
                    }

                    Text {
                        anchors.centerIn: appIcon
                        visible: appIcon.status !== Image.Ready
                        text: String(tile.modelData.title || "?").substring(0, 1).toUpperCase()
                        color: backend.accentColor
                        font.family: "monospace"
                        font.pixelSize: 18
                        font.bold: true
                    }

                    Text {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.leftMargin: 5
                        anchors.rightMargin: 5
                        anchors.bottomMargin: 7
                        text: tile.modelData.title || "Background app"
                        color: backend.textColor
                        horizontalAlignment: Text.AlignHCenter
                        font.family: "Inter"
                        font.pixelSize: 9
                        elide: Text.ElideRight
                    }

                    MouseArea {
                        id: tileMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                        onClicked: function(mouse) {
                            backend.activateTrayItem(tile.modelData.reference,
                                mouse.button === Qt.RightButton ? "context" : (mouse.button === Qt.MiddleButton ? "secondary" : "activate"))
                        }
                    }
                    ToolTip.visible: tileMouse.containsMouse
                    ToolTip.delay: 700
                    ToolTip.text: tile.modelData.title + " · " + String(tile.modelData.status || "passive").toLowerCase()
                }
            }
        }
    }

    Timer { interval: 1500; running: true; repeat: true; onTriggered: root.refresh() }
}
