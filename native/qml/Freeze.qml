import QtQuick
import QtQuick.Window
import org.kde.layershell 1.0 as LayerShellQt

Item {
    id: root
    visible: false
    readonly property var state: {
        try {
            return JSON.parse(backend.readText(backend.runtime + "/nocturne-capture-freeze.json"))
        } catch (error) {
            return ({bounds:{x:0,y:0,width:1,height:1}})
        }
    }

    Instantiator {
        model: backend.screens
        delegate: Window {
            id: freezeWindow
            required property var modelData
            readonly property var bounds: root.state.bounds || ({x:0,y:0,width:1,height:1})
            visible: true
            screen: modelData
            width: 1
            height: 1
            color: "black"
            flags: Qt.FramelessWindowHint | Qt.Tool | Qt.WindowTransparentForInput

            LayerShellQt.Window.scope: "nocturne-freeze"
            LayerShellQt.Window.layer: LayerShellQt.Window.LayerOverlay
            LayerShellQt.Window.exclusionZone: -1
            LayerShellQt.Window.keyboardInteractivity: LayerShellQt.Window.KeyboardInteractivityNone
            LayerShellQt.Window.screen: modelData
            LayerShellQt.Window.anchors: LayerShellQt.Window.AnchorTop | LayerShellQt.Window.AnchorRight
                | LayerShellQt.Window.AnchorBottom | LayerShellQt.Window.AnchorLeft

            Image {
                x: Number(freezeWindow.bounds.x || 0) - Number(freezeWindow.modelData.geometry.x || 0)
                y: Number(freezeWindow.bounds.y || 0) - Number(freezeWindow.modelData.geometry.y || 0)
                width: Number(freezeWindow.bounds.width || 1)
                height: Number(freezeWindow.bounds.height || 1)
                source: "file://" + backend.runtime + "/nocturne-capture-freeze.png"
                sourceSize: Qt.size(width, height)
                fillMode: Image.Stretch
                cache: false
                smooth: false
            }
        }
    }
}
