import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"

Rectangle {
    id: root
    implicitWidth: 500
    implicitHeight: Math.max(120, Math.min(430, panel.implicitHeight + 20))
    color: backend.baseColor; border.color: backend.accent2Color; border.width: 1
    property var items: backend.json([backend.home + "/.config/hypr/scripts/minimize", "list"], 1800) || []
    ColumnLayout {
        id: panel; x: 10; y: 10; width: parent.width - 20; spacing: 5
        RowLayout {
            Layout.fillWidth: true
            SectionLabel { Layout.fillWidth: true; text: "MINIMIZED // WINDOWS" }
            NocturneButton { text: "RESTORE ALL"; onClicked: { backend.run([backend.home + "/.config/hypr/scripts/minimize", "restore-all"]); backend.close() } }
        }
        Text { visible: root.items.length === 0; text: "Nothing is minimized."; color: backend.mutedColor; font.family: "Inter"; font.pixelSize: 10 }
        Repeater {
            model: root.items
            NocturneButton {
                required property var modelData
                Layout.fillWidth: true
                text: modelData.title + "  ·  workspace " + modelData.workspace
                onClicked: { backend.run([backend.home + "/.config/hypr/scripts/minimize", "restore", modelData.address]); backend.close() }
            }
        }
    }
}
