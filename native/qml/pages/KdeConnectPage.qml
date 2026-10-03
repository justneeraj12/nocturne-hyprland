import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import "../components"

Rectangle {
    id: root
    implicitWidth: 410
    implicitHeight: panel.implicitHeight + 20
    color: backend.baseColor; border.color: backend.accent2Color; border.width: 1
    property string deviceId: ""
    property string deviceName: "No reachable phone"

    function refresh() {
        deviceId = backend.run(["kdeconnect-cli", "--list-available", "--id-only"], 1600).split("\n")[0]
        var name = backend.run(["kdeconnect-cli", "--list-available", "--name-only"], 1600).split("\n")[0]
        deviceName = deviceId === "" ? "No reachable phone" : (name || "Phone")
    }

    ColumnLayout {
        id: panel; x: 10; y: 10; width: parent.width - 20; spacing: 7
        PanelHeader { Layout.fillWidth: true; title: "Phone"; subtitle: "KDE Connect" }
        Text { Layout.fillWidth: true; text: root.deviceName; color: root.deviceId === "" ? backend.mutedColor : backend.textColor; font.family: "monospace"; font.pixelSize: 14; font.bold: true; horizontalAlignment: Text.AlignHCenter }
        Text { Layout.fillWidth: true; text: root.deviceId === "" ? "Unlock the phone and keep it on the same network." : "CONNECTED + REACHABLE"; color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 9; horizontalAlignment: Text.AlignHCenter }
        RowLayout {
            Layout.fillWidth: true; enabled: root.deviceId !== ""
            NocturneButton { Layout.fillWidth: true; text: "RING"; onClicked: backend.start(["kdeconnect-cli", "-d", root.deviceId, "--ring"]) }
            NocturneButton { Layout.fillWidth: true; text: "PING"; onClicked: backend.start(["kdeconnect-cli", "-d", root.deviceId, "--ping"]) }
        }
        RowLayout {
            Layout.fillWidth: true; enabled: root.deviceId !== ""
            NocturneButton { Layout.fillWidth: true; text: "SEND CLIPBOARD"; onClicked: backend.start(["kdeconnect-cli", "-d", root.deviceId, "--send-clipboard"]) }
            NocturneButton { Layout.fillWidth: true; text: "SEND FILE"; onClicked: filePicker.open() }
        }
        RowLayout {
            Layout.fillWidth: true
            NocturneButton { Layout.fillWidth: true; text: "REFRESH"; onClicked: { backend.run(["kdeconnect-cli", "--refresh"]); root.refresh() } }
            NocturneButton { Layout.fillWidth: true; text: "SETTINGS"; onClicked: backend.start([backend.home + "/.config/hypr/scripts/kdeconnect-settings", root.deviceId]) }
        }
    }

    FileDialog {
        id: filePicker
        title: "Send file to " + root.deviceName
        onAccepted: {
            var path = selectedFile.toString()
            if (path.indexOf("file://") === 0) path = decodeURIComponent(path.substring(7))
            backend.start(["kdeconnect-cli", "-d", root.deviceId, "--share", path])
        }
    }
    Timer { interval: 5000; running: true; repeat: true; onTriggered: root.refresh() }
    Component.onCompleted: refresh()
}
