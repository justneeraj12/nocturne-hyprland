import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"

Rectangle {
    id: root
    implicitWidth: 430
    implicitHeight: Math.max(128, panel.implicitHeight + 20)
    color: backend.baseColor
    border.color: backend.accent2Color
    border.width: 1
    property var items: backend.trayItems()
    property string actionError: ""
    property string menuReference: ""
    property string menuTitle: ""
    property var menuItems: []

    function refresh() { items = backend.trayItems() }
    function activate(item, action) {
        actionError = ""
        if (backend.activateTrayItem(item.reference, action)) backend.close()
        else {
            actionError = String(item.title || "Application").toUpperCase() + " DID NOT ACCEPT THAT ACTION"
            errorTimeout.restart()
        }
    }
    function showMenu(item) {
        if (menuReference === item.reference) { menuReference = ""; menuItems = []; return }
        menuReference = item.reference
        menuTitle = item.title || "Application"
        menuItems = backend.trayMenu(item.reference)
        if (menuItems.length === 0) activate(item, "context")
    }
    function stateLabel(item) {
        var state = String(item.status || "passive").toUpperCase()
        if (state === "NEEDSATTENTION") return "NEEDS ATTENTION"
        return state
    }
    function navigate(delta) {
        if (items.length === 0) return
        appList.currentIndex = (appList.currentIndex + delta + items.length) % items.length
        appList.positionViewAtIndex(appList.currentIndex, ListView.Contain)
    }
    function activateCurrent() {
        if (appList.currentIndex < 0 || appList.currentIndex >= items.length) return
        var item = items[appList.currentIndex]
        if (item.hasMenu) showMenu(item); else activate(item, "activate")
    }
    function contextCurrent() { if (appList.currentIndex >= 0 && appList.currentIndex < items.length) showMenu(items[appList.currentIndex]) }

    ColumnLayout {
        id: panel
        x: 10
        y: 10
        width: parent.width - 20
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 9
            Rectangle {
                implicitWidth: 31
                implicitHeight: 31
                color: backend.surfaceColor
                border.color: backend.lineColor
                Text {
                    anchors.centerIn: parent
                    text: "⋯"
                    color: backend.accentColor
                    font.family: "MesloLGS Nerd Font Mono"
                    font.pixelSize: 17
                    font.bold: true
                }
            }
            PanelHeader {
                Layout.fillWidth: true
                title: "Background apps"
                subtitle: "Click for controls · middle-click to open the app"
            }
            Rectangle {
                implicitWidth: appCount.implicitWidth + 16
                implicitHeight: 25
                color: backend.surfaceColor
                border.color: backend.lineColor
                Text {
                    id: appCount
                    anchors.centerIn: parent
                    text: root.items.length + (root.items.length === 1 ? " APP" : " APPS")
                    color: backend.accentColor
                    font.family: "monospace"
                    font.pixelSize: 8
                    font.bold: true
                }
            }
        }

        Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: backend.lineColor }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 66
            visible: root.items.length === 0
            color: backend.surfaceColor
            border.color: backend.lineColor
            Column {
                anchors.centerIn: parent
                spacing: 4
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "NO BACKGROUND APPS"; color: backend.textColor; font.family: "monospace"; font.pixelSize: 10; font.bold: true }
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Apps with tray controls will appear here automatically."; color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 9 }
            }
        }

        ListView {
            id: appList
            Layout.fillWidth: true
            Layout.preferredHeight: root.items.length === 0 ? 0 : Math.min(root.items.length * 67 - 5, 464)
            spacing: 5
            clip: true
            model: root.items
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: ScrollBar { policy: appList.contentHeight > appList.height ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff }
            delegate: Rectangle {
                    id: appRow
                    required property var modelData
                    width: ListView.view.width
                    height: 62
                    color: rowMouse.containsMouse || ListView.isCurrentItem ? backend.overlayColor : backend.surfaceColor
                    border.width: 1
                    border.color: rowMouse.containsMouse || ListView.isCurrentItem ? backend.accent2Color : backend.lineColor

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 9
                        spacing: 10
                        Rectangle {
                            implicitWidth: 38
                            implicitHeight: 38
                            color: backend.baseColor
                            border.color: backend.lineColor
                            Image {
                                id: appIcon
                                anchors.centerIn: parent
                                width: 26
                                height: 26
                                sourceSize: Qt.size(52, 52)
                                fillMode: Image.PreserveAspectFit
                                source: appRow.modelData.icon ? "image://theme/" + encodeURIComponent(appRow.modelData.icon) : ""
                                asynchronous: true
                            }
                            Text {
                                anchors.centerIn: parent
                                visible: appIcon.status !== Image.Ready
                                text: String(appRow.modelData.title || "?").substring(0, 1).toUpperCase()
                                color: backend.accentColor
                                font.family: "monospace"
                                font.pixelSize: 15
                                font.bold: true
                            }
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 3
                            Text {
                                Layout.fillWidth: true
                                text: appRow.modelData.title || "Background app"
                                color: backend.textColor
                                font.family: "Inter"
                                font.pixelSize: 10
                                font.bold: true
                                elide: Text.ElideRight
                            }
                            RowLayout {
                                spacing: 6
                                Rectangle {
                                    implicitWidth: 6; implicitHeight: 6
                                    color: String(appRow.modelData.status).toLowerCase() === "active" ? backend.accentColor : backend.mutedColor
                                }
                                Text {
                                    text: root.stateLabel(appRow.modelData)
                                    color: backend.mutedColor
                                    font.family: "monospace"
                                    font.pixelSize: 8
                                }
                                Text {
                                    visible: String(appRow.modelData.process || "") !== ""
                                    text: "·  " + String(appRow.modelData.process).toUpperCase()
                                    color: backend.mutedColor
                                    font.family: "monospace"
                                    font.pixelSize: 8
                                    elide: Text.ElideRight
                                }
                            }
                        }
                        Text {
                                text: appRow.modelData.hasMenu ? (rowMouse.containsMouse ? "MENU  ≡" : "≡") : (rowMouse.containsMouse ? "OPEN  ↗" : "↗")
                            color: rowMouse.containsMouse ? backend.accentColor : backend.mutedColor
                            font.family: "monospace"
                            font.pixelSize: 8
                            font.bold: true
                        }
                    }

                    MouseArea {
                        id: rowMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                        onClicked: function(mouse) {
                            appList.currentIndex = index
                            if (mouse.button === Qt.RightButton) root.showMenu(appRow.modelData)
                            else if (mouse.button === Qt.MiddleButton) root.activate(appRow.modelData, "activate")
                            else if (appRow.modelData.hasMenu) root.showMenu(appRow.modelData)
                            else root.activate(appRow.modelData, "activate")
                        }
                    }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: menuColumn.implicitHeight + 16
            visible: root.menuReference !== "" && root.menuItems.length > 0
            color: backend.surfaceColor
            border.color: backend.accent2Color
            ColumnLayout {
                id: menuColumn
                anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 8
                spacing: 3
                RowLayout { Layout.fillWidth: true
                    Text { Layout.fillWidth: true; text: root.menuTitle.toUpperCase() + " MENU"; color: backend.accentColor; font.family: "monospace"; font.pixelSize: 8; font.bold: true }
                    NocturneButton { text: "×"; onClicked: { root.menuReference = ""; root.menuItems = [] } }
                }
                Repeater { model: root.menuItems
                    Rectangle { required property var modelData; Layout.fillWidth: true; implicitHeight: modelData.separator ? 5 : 28; color: itemMouse.containsMouse && modelData.enabled ? backend.overlayColor : "transparent"
                        Rectangle { visible: modelData.separator; anchors.verticalCenter: parent.verticalCenter; width: parent.width; height: 1; color: backend.lineColor }
                        RowLayout { anchors.fill: parent; anchors.leftMargin: 7 + Math.max(0, modelData.depth) * 11; anchors.rightMargin: 7; visible: !modelData.separator
                            Text { text: modelData.checked ? "●" : (modelData.toggle ? "○" : "›"); color: modelData.enabled ? backend.accentColor : backend.mutedColor; font.family: "monospace"; font.pixelSize: 8 }
                            Text { Layout.fillWidth: true; text: String(modelData.label || "Action").replace(/_/g, ""); color: modelData.enabled ? backend.textColor : backend.mutedColor; font.family: "Inter"; font.pixelSize: 9; elide: Text.ElideRight }
                        }
                        MouseArea { id: itemMouse; anchors.fill: parent; hoverEnabled: true; enabled: !modelData.separator && modelData.enabled; cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor; onClicked: { backend.activateTrayMenuItem(root.menuReference, modelData.id); root.menuReference = ""; root.menuItems = []; root.refresh() } }
                    }
                }
            }
        }

        Text {
            visible: root.actionError !== ""
            Layout.fillWidth: true
            text: root.actionError
            color: "#ff8c96"
            horizontalAlignment: Text.AlignHCenter
            font.family: "monospace"
            font.pixelSize: 8
            font.bold: true
        }
    }

    Timer { interval: 10000; running: true; repeat: true; onTriggered: root.refresh() }
    Timer { id: errorTimeout; interval: 3000; onTriggered: root.actionError = "" }
}
