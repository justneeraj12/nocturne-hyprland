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
    readonly property bool centerSurface: backend.surface === "launcher" || backend.surface === "clipboard" || backend.surface === "minimized"
    readonly property int cardWidth: backend.surface === "launcher" ? 540 : ((backend.surface === "clipboard" || backend.surface === "minimized") ? (backend.surface === "clipboard" ? 520 : 500) : (bottomSurface ? 502 : 410))
    readonly property int cardHeight: contentLoader.item ? contentLoader.item.implicitHeight : 200

    function dismiss() {
        if (root.bottomSurface)
            backend.start([backend.home + "/.local/bin/nocturne-capture-engine", "discard"])
        backend.close()
    }

    LayerShellQt.Window.scope: "nocturne-native"
    LayerShellQt.Window.layer: LayerShellQt.Window.LayerOverlay
    LayerShellQt.Window.exclusionZone: -1
    LayerShellQt.Window.keyboardInteractivity: root.centerSurface
        ? LayerShellQt.Window.KeyboardInteractivityExclusive
        : LayerShellQt.Window.KeyboardInteractivityOnDemand
    // Capture prepares a compositor frame before this surface maps. Avoid
    // requesting keyboard focus here so transient application menus remain
    // visible until the user actually interacts with the toolbar.
    LayerShellQt.Window.activateOnShow: !root.bottomSurface
    LayerShellQt.Window.screen: backend.targetScreen
    LayerShellQt.Window.anchors: LayerShellQt.Window.AnchorTop | LayerShellQt.Window.AnchorRight | LayerShellQt.Window.AnchorBottom | LayerShellQt.Window.AnchorLeft

    MouseArea {
        anchors.fill: parent
        onClicked: root.dismiss()
    }

    Item {
        id: card
        width: root.cardWidth
        height: root.cardHeight
        x: root.bottomSurface || root.centerSurface ? Math.round((root.width - width) / 2) : root.width - width - backend.rightMargin(width)
        y: root.bottomSurface ? root.height - height - 28 : (root.centerSurface ? Math.round((root.height - height) * 0.36) : 33)

        MouseArea { anchors.fill: parent }
        Loader {
            id: contentLoader
            anchors.fill: parent
            sourceComponent: {
                if (backend.surface === "capture") return capturePage
                if (backend.surface === "launcher") return launcherPage
                if (backend.surface === "background") return backgroundPage
                if (backend.surface === "notifications") return notificationsPage
                if (backend.surface === "clipboard") return clipboardPage
                if (backend.surface === "minimized") return minimizedPage
                if (backend.surface === "media") return mediaPage
                if (backend.surface === "kdeconnect") return kdeConnectPage
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
    Component { id: launcherPage; LauncherPage {} }
    Component { id: backgroundPage; BackgroundPage {} }
    Component { id: notificationsPage; NotificationsPage {} }
    Component { id: clipboardPage; ClipboardPage {} }
    Component { id: minimizedPage; MinimizedPage {} }
    Component { id: mediaPage; MediaPage {} }
    Component { id: kdeConnectPage; KdeConnectPage {} }

    Shortcut { sequence: "Escape"; onActivated: root.dismiss() }
    onClosing: backend.close()
}
