import QtQuick

Item {
    id: root
    visible: false

    property date now: new Date()
    property var monitors: []
    property var minimized: ({})
    property var pomodoro: ({})
    property var caffeine: ({})
    property var connectivity: ({})
    property var systemState: ({})
    property var kdeconnect: ({})
    property var battery: ({})
    property var tray: []
    property var media: ({title: "", artist: "", status: ""})
    property int volume: 0
    property bool volumeMuted: false
    property bool micMuted: false
    property bool micInUse: false
    property bool screenSharing: false
    property int brightness: 0
    property int notificationCount: 0
    property bool dnd: false
    property var barPrefs: ({density:"auto", iconScale:1, separators:true, trayCount:true, modules:{}, monitors:{}})

    function scriptJson(name, args) {
        var command = [backend.home + "/.config/hypr/scripts/" + name]
        if (args) command = command.concat(args)
        var value = backend.json(command, 1600)
        return value || ({})
    }
    function parseVolume(target) {
        var value = backend.run(["wpctl", "get-volume", target], 1000)
        var match = value.match(/Volume:\s*([0-9.]+)/)
        return { value: match ? Math.round(parseFloat(match[1]) * 100) : 0,
                 muted: value.indexOf("[MUTED]") >= 0 }
    }
    function refreshWorkspace() {
        monitors = backend.json(["hyprctl", "monitors", "-j"], 1200) || []
    }
    function refreshActivity() {
        pomodoro = scriptJson("pomodoro", ["status"])
    }
    function refreshMinimized() { minimized = scriptJson("minimize", ["status"]) }
    function refreshAudio() {
        var sink = parseVolume("@DEFAULT_AUDIO_SINK@")
        volume = sink.value; volumeMuted = sink.muted
        micMuted = parseVolume("@DEFAULT_AUDIO_SOURCE@").muted
        micInUse = backend.microphoneInUse()
        var backlightNow = parseInt(backend.readFirst("/sys/class/backlight", "brightness")) || 0
        var backlightMax = parseInt(backend.readFirst("/sys/class/backlight", "max_brightness")) || 1
        brightness = Math.round(backlightNow * 100 / backlightMax)
        var raw = backend.run(["playerctl", "-a", "metadata", "--format", "{{playerName}}\\t{{status}}\\t{{title}}\\t{{artist}}"], 1000)
        var rows = raw.split("\\n").filter(function(row) { return row !== "" })
        var selected = rows.filter(function(row) { return row.split("\\t")[1] === "Playing" })[0] || rows[0] || ""
        var fields = selected.split("\\t")
        media = {player: fields[0] || "", status: fields[1] || "", title: fields[2] || "", artist: fields[3] || ""}
    }
    function refreshConnectivity() {
        connectivity = scriptJson("connectivity-status", ["combined"])
        kdeconnect = scriptJson("kdeconnect-status")
    }
    function refreshNotifications() {
        notificationCount = backend.notificationCount()
        dnd = backend.run(["makoctl", "mode"], 1000).split("\n").indexOf("do-not-disturb") >= 0
    }
    function refreshCapture() { screenSharing = backend.screenSharing() }
    function refreshCaffeine() { caffeine = scriptJson("caffeine", ["status"]) }
    function refreshSystem() { systemState = scriptJson("system-status") }
    function refreshPower() { battery = scriptJson("power-battery-status") }
    function refreshTray() { tray = backend.trayItems() }
    function refreshPreferences() { barPrefs = scriptJson("bar-preferences", ["status"]) }
    function trayTooltip() {
        if (tray.length === 0) return "No background apps"
        var names = []
        for (var i = 0; i < tray.length; ++i) names.push(tray[i].title || "Application")
        return tray.length + (tray.length === 1 ? " background app\n" : " background apps\n") + names.join(" · ")
    }

    Connections {
        target: backend
        function onShellEvent(topic) {
            if (topic === "workspace") root.refreshWorkspace()
            else if (topic === "windows") root.refreshMinimized()
            else if (topic === "audio" || topic === "brightness" || topic === "media") root.refreshAudio()
            else if (topic === "connectivity") root.refreshConnectivity()
            else if (topic === "power") root.refreshPower()
            else if (topic === "tray") root.refreshTray()
        }
    }

    // These are deliberately slow recovery timers. Normal updates arrive from
    // Hyprland, PipeWire, MPRIS, NetworkManager, UPower and file-system events.
    Timer { interval: 15000; running: true; repeat: true; onTriggered: root.now = new Date() }
    Timer { interval: root.pomodoro.running ? 1000 : 60000; running: true; repeat: true; onTriggered: root.refreshActivity() }
    Timer { interval: 300000; running: true; repeat: true; onTriggered: root.refreshWorkspace() }
    Timer { interval: 300000; running: true; repeat: true; onTriggered: root.refreshAudio() }
    Timer { interval: 10000; running: true; repeat: true; onTriggered: root.refreshNotifications() }
    Timer { interval: 6000; running: true; repeat: true; onTriggered: root.refreshCapture() }
    Timer { interval: 120000; running: true; repeat: true; onTriggered: root.refreshMinimized() }
    Timer { interval: 300000; running: true; repeat: true; onTriggered: root.refreshTray() }
    Timer { interval: 60000; running: true; repeat: true; onTriggered: root.refreshCaffeine() }
    Timer { interval: 300000; running: true; repeat: true; onTriggered: root.refreshConnectivity() }
    Timer { interval: 60000; running: true; repeat: true; onTriggered: root.refreshSystem() }
    Timer { interval: 300000; running: true; repeat: true; onTriggered: root.refreshPower() }

    Instantiator {
        model: backend.screens
        delegate: BarWindow {
            required property var modelData
            targetScreen: modelData
            shell: root
        }
    }

    Component.onCompleted: {
        refreshWorkspace()
        refreshActivity()
        refreshMinimized()
        refreshAudio()
        refreshCaffeine()
        refreshConnectivity()
        refreshNotifications()
        refreshCapture()
        refreshSystem()
        refreshPower()
        refreshTray()
        refreshPreferences()
    }
}
