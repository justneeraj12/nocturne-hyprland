import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"

Rectangle {
    id: root
    implicitWidth: 540
    implicitHeight: 420
    color: backend.baseColor
    border.color: backend.accent2Color
    border.width: 1
    property var results: backend.applications("")

    function refresh() {
        results = backend.applications(search.text)
        apps.currentIndex = results.length > 0 ? 0 : -1
    }
    function launchCurrent() {
        if (apps.currentIndex >= 0 && apps.currentIndex < results.length)
            backend.launchApplication(results[apps.currentIndex].path)
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            SectionLabel { Layout.fillWidth: true; text: "NOCTURNE // APPLICATION INDEX" }
            Text {
                text: root.results.length + " MATCHES"
                color: backend.mutedColor
                font.family: "monospace"
                font.pixelSize: 9
            }
        }

        TextField {
            id: search
            Layout.fillWidth: true
            implicitHeight: 42
            placeholderText: "Search applications…"
            color: backend.textColor
            placeholderTextColor: backend.mutedColor
            font.family: "monospace"
            font.pixelSize: 14
            leftPadding: 13
            rightPadding: 13
            selectByMouse: true
            background: Rectangle {
                color: backend.surfaceColor
                border.color: search.activeFocus ? backend.accentColor : backend.lineColor
                border.width: 1
            }
            onTextChanged: root.refresh()
            Keys.onPressed: function(event) {
                if (event.key === Qt.Key_Down) {
                    apps.currentIndex = Math.min(apps.count - 1, apps.currentIndex + 1)
                    apps.positionViewAtIndex(apps.currentIndex, ListView.Contain)
                    event.accepted = true
                } else if (event.key === Qt.Key_Up) {
                    apps.currentIndex = Math.max(0, apps.currentIndex - 1)
                    apps.positionViewAtIndex(apps.currentIndex, ListView.Contain)
                    event.accepted = true
                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    root.launchCurrent()
                    event.accepted = true
                } else if (event.key === Qt.Key_Escape) {
                    backend.close()
                    event.accepted = true
                }
            }
            Component.onCompleted: forceActiveFocus()
        }

        ListView {
            id: apps
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: root.results
            clip: true
            spacing: 3
            currentIndex: count > 0 ? 0 : -1
            highlightMoveDuration: 70
            delegate: Rectangle {
                required property var modelData
                required property int index
                width: ListView.view.width
                height: 40
                color: ListView.isCurrentItem ? backend.overlayColor : "transparent"
                border.color: ListView.isCurrentItem ? backend.accent2Color : "transparent"
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 10
                    Rectangle {
                        Layout.preferredWidth: 24
                        Layout.preferredHeight: 24
                        color: backend.surfaceColor
                        border.color: backend.lineColor
                        Text {
                            anchors.centerIn: parent
                            text: modelData.name.substring(0, 1).toUpperCase()
                            color: backend.accentColor
                            font.family: "monospace"
                            font.bold: true
                        }
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        Text {
                            Layout.fillWidth: true
                            text: modelData.name
                            color: backend.textColor
                            elide: Text.ElideRight
                            font.family: "monospace"
                            font.pixelSize: 12
                            font.bold: index === apps.currentIndex
                        }
                        Text {
                            Layout.fillWidth: true
                            visible: modelData.generic !== ""
                            text: modelData.generic
                            color: backend.mutedColor
                            elide: Text.ElideRight
                            font.family: "Inter"
                            font.pixelSize: 9
                        }
                    }
                    Text {
                        text: index === apps.currentIndex ? "↵" : ((index < 9 ? "0" : "") + String(index + 1))
                        color: index === apps.currentIndex ? backend.accentColor : backend.mutedColor
                        font.family: "monospace"
                        font.pixelSize: 10
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: apps.currentIndex = index
                    onClicked: backend.launchApplication(modelData.path)
                }
            }
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
        }

        Text {
            Layout.fillWidth: true
            text: "↑↓ NAVIGATE   ↵ LAUNCH   ESC CLOSE"
            color: backend.mutedColor
            horizontalAlignment: Text.AlignHCenter
            font.family: "monospace"
            font.pixelSize: 9
        }
    }
}
