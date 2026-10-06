import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"

Rectangle {
    id: root
    property string pageTitle: ""
    property string pageDescription: ""
    property string pageEyebrow: "SYSTEM SETTINGS"
    property string pageBadge: ""
    property var actions: []
    color: backend.baseColor

    function activate(item) {
        if (item.surface) {
            var args = [backend.home + "/.local/bin/nocturne-native", item.surface]
            if (item.page) args.push(item.page)
            backend.start(args)
        } else if (item.command === "screenshot") {
            backend.start([backend.home + "/.local/bin/hyprshot", "-m", "region", "-o", backend.home + "/Pictures/Screenshots"])
        } else if (item.command === "recorder") {
            backend.start(["flatpak", "run", "io.github.seadve.Kooha"])
        } else if (item.command === "annotate") {
            backend.start([backend.home + "/.config/hypr/scripts/capture-tools", "annotate"])
        } else if (item.command === "ocr") {
            backend.start([backend.home + "/.config/hypr/scripts/capture-tools", "ocr"])
        } else if (item.command === "keys") {
            backend.start([backend.home + "/.config/hypr/scripts/help"])
        } else if (item.command === "lock") {
            backend.start([backend.home + "/.config/hypr/scripts/lock-screen"])
        } else if (item.command === "doctor") {
            backend.start(["kitty", "--class", "nocturne-doctor", "-e", backend.home + "/.local/bin/nocturne-doctor"])
        } else if (item.command === "support") {
            backend.start([backend.home + "/.local/bin/nocturne-support"])
        } else if (item.command === "source") {
            backend.start(["xdg-open", "https://github.com/justneeraj12/nocturne-hyprland"])
        }
    }

    ScrollView {
        anchors.fill: parent
        contentWidth: availableWidth
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

        ColumnLayout {
            x: 26
            width: parent.width - 52
            spacing: 15

            Item { Layout.preferredHeight: 10 }
            SettingsPageHeader {
                Layout.fillWidth: true
                eyebrow: root.pageEyebrow
                title: root.pageTitle
                description: root.pageDescription
                badge: root.pageBadge
            }
            GridLayout {
                Layout.fillWidth: true
                columns: width >= 650 ? 2 : 1
                columnSpacing: 10
                rowSpacing: 10
                Repeater {
                    model: root.actions
                    SettingsAction {
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.columnSpan: 1
                        iconName: modelData.icon || "preferences-system"
                        glyph: modelData.glyph || ""
                        title: modelData.label
                        description: modelData.detail
                        actionText: modelData.button || "OPEN"
                        danger: modelData.danger || false
                        onClicked: root.activate(modelData)
                    }
                }
            }
            Item { Layout.preferredHeight: 16 }
        }
    }
}
