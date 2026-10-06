import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"

Rectangle {
    id: root
    implicitWidth: 560
    implicitHeight: 450
    color: backend.baseColor
    border.color: backend.accent2Color
    border.width: 1

    property string mode: "apps"
    property var results: []
    readonly property var modes: [
        {key:"all", label:"ALL"}, {key:"apps", label:"APPS"},
        {key:"windows", label:"WINDOWS"}, {key:"actions", label:"ACTIONS"}
    ]

    function refresh() {
        results = backend.launcherResults(search.text, mode)
        entries.currentIndex = results.length > 0 ? 0 : -1
    }
    function navigate(delta) {
        if (results.length === 0) return
        entries.currentIndex = Math.max(0, Math.min(results.length - 1, entries.currentIndex + delta))
        entries.positionViewAtIndex(entries.currentIndex, ListView.Contain)
    }
    function first() { if (results.length) { entries.currentIndex = 0; entries.positionViewAtBeginning() } }
    function last() { if (results.length) { entries.currentIndex = results.length - 1; entries.positionViewAtEnd() } }
    function page(delta) { navigate(delta * 6) }
    function clearQuery() { search.clear(); search.forceActiveFocus() }
    function setMode(nextMode) {
        mode = nextMode
        refresh()
        search.forceActiveFocus()
    }
    function cycleMode() {
        var index = 0
        for (var i = 0; i < modes.length; ++i) if (modes[i].key === mode) index = i
        setMode(modes[(index + 1) % modes.length].key)
    }
    function launchCurrent() {
        if (entries.currentIndex >= 0 && entries.currentIndex < results.length)
            backend.activateLauncherResult(results[entries.currentIndex])
    }
    function kindLabel(kind) {
        if (kind === "window") return "RUNNING"
        if (kind === "action") return "ACTION"
        if (kind === "file") return "FILE"
        if (kind === "calculation") return "COPY RESULT"
        if (kind === "desk-capture") return "ADD TO DESK"
        if (kind === "habit-capture") return "ADD HABIT"
        if (kind === "vault-capture") return "SAVE TO VAULT"
        if (kind === "note-capture") return "APPEND NOTE"
        if (kind === "copy-text") return "COPY TEXT"
        if (kind === "open-url") return "OPEN URL"
        if (kind === "control-action") return "CONTROL"
        return "APP"
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            PanelHeader { Layout.fillWidth: true; title: "Command Center"; subtitle: "Apps, windows, files, calculator and desktop actions" }
            Text {
                text: root.results.length + (root.results.length === 1 ? " RESULT" : " RESULTS")
                color: backend.mutedColor
                font.family: "monospace"
                font.pixelSize: 9
            }
        }

        TextField {
            id: search
            Layout.fillWidth: true
            implicitHeight: 42
            placeholderText: "Search…  + task  ++ habit  :: name | snippet  @ windows  > actions"
            color: backend.textColor
            placeholderTextColor: backend.mutedColor
            font.family: "monospace"
            font.pixelSize: 13
            leftPadding: 13
            rightPadding: text === "" ? 13 : 38
            selectByMouse: true
            background: Rectangle {
                color: backend.surfaceColor
                border.color: search.activeFocus ? backend.accentColor : backend.lineColor
                border.width: 1
            }
            onTextChanged: root.refresh()
            Keys.onPressed: function(event) {
                if (event.key === Qt.Key_Down) {
                    root.navigate(1)
                    event.accepted = true
                } else if (event.key === Qt.Key_Up) {
                    root.navigate(-1)
                    event.accepted = true
                } else if (event.key === Qt.Key_PageDown) {
                    root.page(1); event.accepted = true
                } else if (event.key === Qt.Key_PageUp) {
                    root.page(-1); event.accepted = true
                } else if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_Home) {
                    root.first(); event.accepted = true
                } else if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_End) {
                    root.last(); event.accepted = true
                } else if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_L) {
                    search.selectAll(); event.accepted = true
                } else if (event.key === Qt.Key_Tab) {
                    root.cycleMode()
                    event.accepted = true
                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    root.launchCurrent()
                    event.accepted = true
                } else if ((event.modifiers & Qt.AltModifier) && event.key >= Qt.Key_1 && event.key <= Qt.Key_9) {
                    var quickIndex = event.key - Qt.Key_1
                    if (quickIndex < root.results.length) backend.activateLauncherResult(root.results[quickIndex])
                    event.accepted = true
                } else if (event.key === Qt.Key_Escape) {
                    if (search.text !== "") root.clearQuery(); else backend.close()
                    event.accepted = true
                }
            }
            Text {
                visible: search.text !== ""
                anchors.right: parent.right; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter
                text: "×"; color: clearMouse.containsMouse ? backend.accentColor : backend.mutedColor
                font.family: "Inter"; font.pixelSize: 16
                MouseArea { id: clearMouse; anchors.fill: parent; anchors.margins: -8; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.clearQuery() }
            }
            Component.onCompleted: forceActiveFocus()
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 5
            Repeater {
                model: root.modes
                NocturneButton {
                    required property var modelData
                    Layout.fillWidth: true
                    text: modelData.label
                    selected: root.mode === modelData.key
                    onClicked: root.setMode(modelData.key)
                }
            }
        }

        ListView {
            id: entries
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: root.results
            clip: true
            spacing: 3
            currentIndex: count > 0 ? 0 : -1
            highlightMoveDuration: 70
            Text {
                anchors.centerIn: parent
                visible: root.results.length === 0
                text: search.text === "" ? "NO ITEMS IN THIS FILTER" : "NO MATCHES · TRY A SHORTER QUERY"
                color: backend.mutedColor; font.family: "monospace"; font.pixelSize: 10; font.letterSpacing: 0.7
            }
            delegate: Rectangle {
                required property var modelData
                required property int index
                width: ListView.view.width
                height: 43
                color: ListView.isCurrentItem ? backend.overlayColor : "transparent"
                border.color: ListView.isCurrentItem ? backend.accent2Color : "transparent"
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 9
                    anchors.rightMargin: 9
                    spacing: 10
                    Rectangle {
                        Layout.preferredWidth: 27
                        Layout.preferredHeight: 27
                        color: backend.surfaceColor
                        border.color: backend.lineColor
                        Image {
                            id: resultIcon
                            anchors.centerIn: parent
                            width: 20; height: 20
                            sourceSize.width: 20; sourceSize.height: 20
                            fillMode: Image.PreserveAspectFit
                            source: modelData.icon ? "image://theme/" + encodeURIComponent(modelData.icon) : ""
                            asynchronous: true
                        }
                        Text {
                            anchors.centerIn: parent
                            visible: resultIcon.status !== Image.Ready
                            text: modelData.kind === "window" ? "□" : (modelData.kind === "action" ? ">" : String(modelData.name).substring(0, 1).toUpperCase())
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
                            font.pixelSize: 11
                            font.bold: index === entries.currentIndex
                        }
                        Text {
                            Layout.fillWidth: true
                            text: modelData.generic || "Application"
                            color: backend.mutedColor
                            elide: Text.ElideRight
                            font.family: "Inter"
                            font.pixelSize: 9
                        }
                    }
                    Text {
                        text: root.kindLabel(modelData.kind)
                        color: modelData.kind === "action" ? backend.accentColor : backend.mutedColor
                        font.family: "Inter"
                        font.pixelSize: 8
                        font.bold: true
                    }
                    NocturneButton {
                        id: favoriteButton
                        z: 2
                        visible: modelData.kind === "application"
                        text: modelData.favorite ? "★" : "☆"
                        selected: Boolean(modelData.favorite)
                        onClicked: { backend.toggleFavorite(modelData.path); root.refresh() }
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    anchors.rightMargin: modelData.kind === "application" ? favoriteButton.width + 18 : 0
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: entries.currentIndex = index
                    onClicked: backend.activateLauncherResult(modelData)
                }
            }
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
        }

        Text {
            Layout.fillWidth: true
            text: "TAB FILTER   ↑↓/PG NAVIGATE   ALT+1…9 OPEN   CTRL+L SEARCH   ESC CLEAR/CLOSE"
            color: backend.mutedColor
            horizontalAlignment: Text.AlignHCenter
            font.family: "monospace"
            font.pixelSize: 9
        }
    }

    Component.onCompleted: refresh()
}
