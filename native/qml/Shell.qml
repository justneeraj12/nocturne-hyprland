import QtQuick
import QtQuick.Controls
import org.kde.layershell 1.0 as LayerShellQt
import "pages"

ApplicationWindow {
    id: root
    visible: true
    color: "transparent"
    flags: Qt.FramelessWindowHint | Qt.Tool | (backend.surface === "osd" ? Qt.WindowTransparentForInput : 0)
    width: 1
    height: 1
    screen: backend.targetScreen

    readonly property bool centerSurface: backend.surface === "launcher" || backend.surface === "clipboard" || backend.surface === "minimized" || backend.surface === "osd" || backend.surface === "overview" || backend.surface === "scenes" || backend.surface === "privacy" || backend.surface === "gaming"
    readonly property int cardWidth: backend.surface === "overview" ? Math.min(1080, width - 48) : (backend.surface === "scenes" ? 610 : (backend.surface === "gaming" ? 510 : (backend.surface === "privacy" ? 460 : (backend.surface === "osd" ? 330 : (backend.surface === "launcher" ? 560
        : (backend.surface === "display" ? 460
            : ((backend.surface === "clipboard" || backend.surface === "minimized" || backend.surface === "notifications") ? (backend.surface === "clipboard" ? 520 : (backend.surface === "notifications" ? 480 : 500)) : 410)))))))
    readonly property int cardHeight: contentLoader.item ? contentLoader.item.implicitHeight : 200

    function dismiss() { backend.close() }
    function callPage(method, argument) {
        var page = contentLoader.item
        if (page && typeof page[method] === "function") page[method](argument)
    }

    LayerShellQt.Window.scope: "nocturne-native"
    LayerShellQt.Window.layer: LayerShellQt.Window.LayerOverlay
    LayerShellQt.Window.exclusionZone: -1
    LayerShellQt.Window.keyboardInteractivity: backend.surface === "osd"
        ? LayerShellQt.Window.KeyboardInteractivityNone
        : root.centerSurface
        ? LayerShellQt.Window.KeyboardInteractivityExclusive
        : LayerShellQt.Window.KeyboardInteractivityOnDemand
    LayerShellQt.Window.activateOnShow: backend.surface !== "osd"
    LayerShellQt.Window.screen: backend.targetScreen
    LayerShellQt.Window.anchors: LayerShellQt.Window.AnchorTop | LayerShellQt.Window.AnchorRight | LayerShellQt.Window.AnchorBottom | LayerShellQt.Window.AnchorLeft

    MouseArea {
        anchors.fill: parent
        enabled: backend.surface !== "osd"
        onClicked: root.dismiss()
    }

    Item {
        id: card
        width: root.cardWidth
        height: root.cardHeight
        x: root.centerSurface ? Math.round((root.width - width) / 2) : root.width - width - backend.rightMargin(width)
        y: backend.surface === "osd" ? root.height - height - 72
            : (root.centerSurface ? Math.round((root.height - height) * 0.36) : 33)

        MouseArea { anchors.fill: parent }
        Loader {
            id: contentLoader
            anchors.fill: parent
            sourceComponent: {
                if (backend.surface === "launcher") return launcherPage
                if (backend.surface === "overview") return overviewPage
                if (backend.surface === "scenes") return scenesPage
                if (backend.surface === "privacy") return privacyPage
                if (backend.surface === "gaming") return gamingPage
                if (backend.surface === "osd") return osdPage
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
                if (backend.surface === "maintenance") return maintenancePage
                if (backend.surface === "display") return displayPage
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
    Component { id: launcherPage; LauncherPage {} }
    Component { id: overviewPage; OverviewPage {} }
    Component { id: scenesPage; ScenesPage {} }
    Component { id: privacyPage; PrivacyPage {} }
    Component { id: gamingPage; GamingPage {} }
    Component { id: osdPage; OsdPage {} }
    Component { id: backgroundPage; BackgroundPage {} }
    Component { id: notificationsPage; NotificationsPage {} }
    Component { id: clipboardPage; ClipboardPage {} }
    Component { id: minimizedPage; MinimizedPage {} }
    Component { id: mediaPage; MediaPage {} }
    Component { id: kdeConnectPage; KdeConnectPage {} }
    Component { id: maintenancePage; MaintenancePage {} }
    Component { id: displayPage; DisplayPage {} }

    Shortcut { sequence: "Escape"; onActivated: root.dismiss() }
    Shortcut { sequence: "Down"; onActivated: root.callPage("navigate", 1) }
    Shortcut { sequence: "Up"; onActivated: root.callPage("navigate", -1) }
    Shortcut { sequence: "Return"; onActivated: root.callPage("activateCurrent") }
    Shortcut { sequence: "Enter"; onActivated: root.callPage("activateCurrent") }
    Shortcut { sequence: "Delete"; onActivated: root.callPage("deleteCurrent") }
    Shortcut { sequence: "Menu"; onActivated: root.callPage("contextCurrent") }
    Shortcut { sequence: "Ctrl+W"; onActivated: root.dismiss() }
    onClosing: backend.close()
}
