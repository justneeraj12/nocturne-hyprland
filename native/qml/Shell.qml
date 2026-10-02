import QtQuick
import QtQuick.Controls
import org.kde.layershell 1.0 as LayerShellQt
import "pages"

ApplicationWindow {
    id: root
    visible: true
    color: "transparent"
    flags: Qt.FramelessWindowHint | Qt.Tool
    width: 1
    height: 1
    screen: backend.targetScreen

    readonly property bool bottomSurface: backend.surface === "capture"
    readonly property int cardWidth: bottomSurface ? 502 : (backend.surface === "power" ? 390 : 410)
    readonly property int cardHeight: contentLoader.item ? contentLoader.item.implicitHeight : 200

    LayerShellQt.Window.scope: "nocturne-native"
    LayerShellQt.Window.layer: LayerShellQt.Window.LayerOverlay
    LayerShellQt.Window.exclusionZone: -1
    LayerShellQt.Window.keyboardInteractivity: LayerShellQt.Window.KeyboardInteractivityOnDemand
    LayerShellQt.Window.activateOnShow: true
    LayerShellQt.Window.screen: backend.targetScreen
    LayerShellQt.Window.anchors: LayerShellQt.Window.AnchorTop | LayerShellQt.Window.AnchorRight | LayerShellQt.Window.AnchorBottom | LayerShellQt.Window.AnchorLeft

    MouseArea {
        anchors.fill: parent
        onClicked: backend.close()
    }

    Item {
        id: card
        width: root.cardWidth
        height: root.cardHeight
        x: root.bottomSurface ? Math.round((root.width - width) / 2) : root.width - width - backend.rightMargin(width)
        y: root.bottomSurface ? root.height - height - 28 : 33

        MouseArea { anchors.fill: parent }
        Loader {
            id: contentLoader
            anchors.fill: parent
            sourceComponent: {
                if (backend.surface === "capture") return capturePage
                if (backend.surface === "power") return powerPage
                if (backend.surface === "brightness") return brightnessPage
                if (backend.surface === "calendar") return calendarPage
                if (backend.surface === "world") return worldPage
                if (backend.surface === "pomodoro") return pomodoroPage
                if (backend.surface === "connectivity") return connectivityPage
                return audioPage
            }
        }
    }

    Component { id: audioPage; AudioPage {} }
    Component { id: brightnessPage; BrightnessPage {} }
    Component { id: calendarPage; CalendarPage {} }
    Component { id: worldPage; WorldPage {} }
    Component { id: connectivityPage; ConnectivityPage { initialPage: backend.page || "wifi" } }
    Component { id: pomodoroPage; PomodoroPage {} }
    Component { id: powerPage; PowerPage {} }
    Component { id: capturePage; CapturePage {} }

    Shortcut { sequence: "Escape"; onActivated: backend.close() }
    onClosing: backend.close()
}
