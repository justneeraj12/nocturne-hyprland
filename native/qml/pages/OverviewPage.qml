import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"

Rectangle {
    id: root
    implicitWidth: 1080
    implicitHeight: 650
    color: backend.baseColor
    border.color: backend.accent2Color
    property var windows: []
    property int activeWorkspace: 1
    property int selectedWorkspace: activeWorkspace

    function refresh() {
        windows = backend.windowItems()
        var workspace = backend.json(["hyprctl", "activeworkspace", "-j"], 1000)
        activeWorkspace = workspace ? (workspace.id || 1) : 1
        selectedWorkspace = activeWorkspace
    }
    function windowsFor(workspace) {
        var result = []
        for (var i = 0; i < windows.length; ++i) if (windows[i].workspace === workspace) result.push(windows[i])
        return result
    }

    ColumnLayout {
        anchors.fill: parent; anchors.margins: 14; spacing: 10
        RowLayout {
            Layout.fillWidth: true
            PanelHeader { Layout.fillWidth: true; title: "Workspace Overview"; subtitle: "Click a window to focus · drag it onto another workspace" }
            NocturneButton { text: "SAVE SCENE"; onClicked: backend.start([backend.home + "/.local/bin/nocturne-native", "scenes"]) }
        }
        GridLayout {
            Layout.fillWidth: true; Layout.fillHeight: true
            columns: 3; rows: 3; columnSpacing: 7; rowSpacing: 7
            Repeater {
                model: 9
                Rectangle {
                    id: workspaceCard
                    required property int index
                    readonly property int workspaceNumber: index + 1
                    Layout.fillWidth: true; Layout.fillHeight: true
                    color: workspaceNumber === root.activeWorkspace ? backend.overlayColor : backend.surfaceColor
                    border.width: workspaceNumber === root.selectedWorkspace ? 2 : 1
                    border.color: workspaceNumber === root.selectedWorkspace ? backend.accentColor : backend.lineColor
                    DropArea {
                        anchors.fill: parent
                        onDropped: function(drop) {
                            backend.windowAction(drop.source.windowAddress, "move", workspaceCard.workspaceNumber)
                            root.refresh(); drop.acceptProposedAction()
                        }
                    }
                    ColumnLayout {
                        anchors.fill: parent; anchors.margins: 7; spacing: 5
                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: "0" + workspaceCard.workspaceNumber; color: backend.accentColor; font.family: "monospace"; font.bold: true; font.pixelSize: 11 }
                            Text { Layout.fillWidth: true; text: root.windowsFor(workspaceCard.workspaceNumber).length + " WINDOWS"; color: backend.mutedColor; horizontalAlignment: Text.AlignRight; font.family: "Inter"; font.pixelSize: 8 }
                        }
                        Repeater {
                            model: root.windowsFor(workspaceCard.workspaceNumber)
                            Rectangle {
                                id: windowTile
                                required property var modelData
                                property string windowAddress: modelData.address
                                Layout.fillWidth: true; implicitHeight: 37
                                color: backend.baseColor; border.color: backend.lineColor
                                Drag.active: dragHandler.active; Drag.hotSpot.x: width / 2; Drag.hotSpot.y: height / 2
                                RowLayout {
                                    anchors.fill: parent; anchors.leftMargin: 7; anchors.rightMargin: 4; spacing: 5
                                    Text { text: "□"; color: backend.accentColor; font.family: "monospace" }
                                    ColumnLayout {
                                        Layout.fillWidth: true; spacing: 0
                                        Text { Layout.fillWidth: true; text: windowTile.modelData.title || windowTile.modelData.class; color: backend.textColor; font.family: "monospace"; font.pixelSize: 9; elide: Text.ElideRight }
                                        Text { Layout.fillWidth: true; text: windowTile.modelData.class; color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 7; elide: Text.ElideRight }
                                    }
                                    NocturneButton { text: "×"; danger: true; onClicked: { backend.windowAction(windowTile.windowAddress, "close"); root.refresh() } }
                                }
                                TapHandler { onTapped: { backend.windowAction(windowTile.windowAddress, "focus"); backend.close() } }
                                DragHandler { id: dragHandler }
                            }
                        }
                        Item { Layout.fillHeight: true }
                    }
                    TapHandler { onTapped: root.selectedWorkspace = workspaceCard.workspaceNumber }
                }
            }
        }
        Text { Layout.fillWidth: true; text: "1–9 FOCUS WORKSPACE   ARROWS SELECT   ENTER OPEN   ESC CLOSE"; color: backend.mutedColor; horizontalAlignment: Text.AlignHCenter; font.family: "monospace"; font.pixelSize: 9 }
    }
    focus: true
    Keys.onPressed: function(event) {
        if (event.key >= Qt.Key_1 && event.key <= Qt.Key_9) selectedWorkspace = event.key - Qt.Key_0
        else if (event.key === Qt.Key_Left) selectedWorkspace = Math.max(1, selectedWorkspace - 1)
        else if (event.key === Qt.Key_Right) selectedWorkspace = Math.min(9, selectedWorkspace + 1)
        else if (event.key === Qt.Key_Up) selectedWorkspace = Math.max(1, selectedWorkspace - 3)
        else if (event.key === Qt.Key_Down) selectedWorkspace = Math.min(9, selectedWorkspace + 3)
        else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) { backend.run(["hyprctl", "dispatch", "hl.dsp.focus({ workspace = " + selectedWorkspace + " })"]); backend.close() }
        else return
        event.accepted = true
    }
    Component.onCompleted: { refresh(); forceActiveFocus() }
}
