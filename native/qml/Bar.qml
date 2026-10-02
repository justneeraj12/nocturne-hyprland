import QtQuick

Item {
    id: root
    visible: false

    property date now: new Date()
    property var monitors: []
    property var minimized: ({})
    property var recording: ({})
    property var pomodoro: ({})
    property var world: ({})
    property var caffeine: ({})
    property var connectivity: ({})
    property var systemState: ({})
    property var kdeconnect: ({})
    property var battery: ({})
    property var media: ({title: "", artist: "", status: ""})
    property int volume: 0
    property bool volumeMuted: false
    property bool micMuted: false
    property int brightness: 0
    property int notificationCount: 0
    property bool dnd: false

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
        minimized = scriptJson("minimize", ["status"])
        recording = scriptJson("capture-status")
        pomodoro = scriptJson("pomodoro", ["status"])
    }
    function refreshMedium() {
        var sink = parseVolume("@DEFAULT_AUDIO_SINK@")
        volume = sink.value; volumeMuted = sink.muted
        micMuted = parseVolume("@DEFAULT_AUDIO_SOURCE@").muted
        brightness = parseInt(backend.run([backend.home + "/.config/hypr/scripts/brightness", "value"], 1000)) || 0
        systemState = scriptJson("system-status")
        caffeine = scriptJson("caffeine", ["status"])
        var raw = backend.run(["playerctl", "metadata", "--format", "{{status}}\\t{{title}}\\t{{artist}}"], 1000)
        var fields = raw.split("\\t")
        media = {status: fields[0] || "", title: fields[1] || "", artist: fields[2] || ""}
    }
    function refreshSlow() {
        connectivity = scriptJson("connectivity-status", ["combined"])
        world = scriptJson("world-status")
        kdeconnect = scriptJson("kdeconnect-status")
        battery = scriptJson("power-battery-status")
        notificationCount = backend.notifications("list").length
        dnd = backend.run(["makoctl", "mode"], 1000).split("\n").indexOf("do-not-disturb") >= 0
    }

    Timer { interval: 1000; running: true; repeat: true; onTriggered: root.now = new Date() }
    Timer { interval: 1500; running: true; repeat: true; onTriggered: root.refreshWorkspace() }
    Timer { interval: 3000; running: true; repeat: true; onTriggered: root.refreshActivity() }
    Timer { interval: 4000; running: true; repeat: true; onTriggered: root.refreshMedium() }
    Timer { interval: 12000; running: true; repeat: true; onTriggered: root.refreshSlow() }

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
        refreshMedium()
        refreshSlow()
    }
}
