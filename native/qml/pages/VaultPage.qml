import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"

Rectangle {
    id: root
    implicitWidth: 650; implicitHeight: 610
    color: backend.baseColor; border.color: backend.accent2Color; border.width: 1
    property var summary: ({items:0,pinned:0})
    property var items: []
    property int editingId: 0
    property int pendingDelete: 0
    readonly property string tool: backend.home + "/.config/hypr/scripts/vault"

    function refresh() { summary = backend.json([tool,"status"],1500) || summary; items = backend.json([tool,"list",search.text],2200) || []; list.currentIndex = items.length ? Math.max(0,Math.min(list.currentIndex,items.length-1)) : -1 }
    function clearForm() { editingId=0; name.clear(); tags.clear(); content.clear(); name.forceActiveFocus() }
    function saveItem() { var n=name.text.trim(), c=content.text.trim(); if (!n || !c) return; backend.run(editingId ? [tool,"edit",String(editingId),n,c,tags.text] : [tool,"add",n,c,tags.text],3500); clearForm(); refresh() }
    function editItem(item) { editingId=item.id; name.text=item.name; tags.text=(item.tags || []).join(", "); content.text=item.content; name.forceActiveFocus(); name.selectAll() }
    function runAction(args) { backend.run([tool].concat(args),4000); refresh() }
    function navigate(delta) { if (items.length) { list.currentIndex=Math.max(0,Math.min(items.length-1,list.currentIndex+delta)); list.positionViewAtIndex(list.currentIndex,ListView.Contain) } }
    function first() { if(items.length){list.currentIndex=0;list.positionViewAtBeginning()} }
    function last() { if(items.length){list.currentIndex=items.length-1;list.positionViewAtEnd()} }
    function page(delta) { navigate(delta*5) }
    function activateCurrent() { if(list.currentIndex>=0) runAction(["copy",String(items[list.currentIndex].id)]) }
    function requestDelete(item) { if(pendingDelete!==item.id){pendingDelete=item.id;deleteReset.restart();return} runAction(["delete",String(item.id)]);pendingDelete=0 }
    function deleteCurrent() { if(list.currentIndex>=0) requestDelete(items[list.currentIndex]) }

    ColumnLayout {
        anchors.fill: parent; anchors.margins: 12; spacing: 8
        RowLayout { Layout.fillWidth: true
            PanelHeader { Layout.fillWidth: true; title: "NOC Vault"; subtitle: "Private snippets, links and reusable commands" }
            Text { text: (summary.items||0)+" ITEMS · "+(summary.pinned||0)+" PINNED"; color: backend.mutedColor; font.family:"monospace"; font.pixelSize:8 }
            NocturneButton { text:"HABITS"; onClicked: backend.start([backend.home+"/.local/bin/nocturne-native","habits"]) }
            NocturneButton { text:"UNDO"; onClicked: root.runAction(["undo"]) }
            NocturneButton { text:"EXPORT"; onClicked:{var path=backend.run([root.tool,"export"],3500).trim();if(path)backend.start(["notify-send","-a","Nocturne","Vault exported",path])} }
        }
        RowLayout { Layout.fillWidth:true; spacing:5
            TextField { id:name; Layout.fillWidth:true; implicitHeight:34; placeholderText:"Name"; color:backend.textColor; placeholderTextColor:backend.mutedColor; font.family:"Inter"; font.pixelSize:9; leftPadding:9; background:Rectangle{color:backend.surfaceColor;border.color:name.activeFocus?backend.accentColor:backend.lineColor} }
            TextField { id:tags; Layout.preferredWidth:180; implicitHeight:34; placeholderText:"tags, comma, separated"; color:backend.textColor; placeholderTextColor:backend.mutedColor; font.family:"monospace"; font.pixelSize:8; leftPadding:9; background:Rectangle{color:backend.surfaceColor;border.color:tags.activeFocus?backend.accentColor:backend.lineColor} }
            NocturneButton { text:editingId?"SAVE":"ADD"; selected:true; enabled:name.text.trim().length>0&&content.text.trim().length>0; onClicked:root.saveItem() }
            NocturneButton { visible:editingId>0; text:"CANCEL"; onClicked:root.clearForm() }
        }
        Rectangle { Layout.fillWidth:true; implicitHeight:72; color:backend.surfaceColor; border.color:content.activeFocus?backend.accentColor:backend.lineColor
            TextArea { id:content; anchors.fill:parent; anchors.margins:4; placeholderText:"Snippet, link, command or reusable text…"; color:backend.textColor; placeholderTextColor:backend.mutedColor; font.family:"monospace"; font.pixelSize:9; wrapMode:TextEdit.Wrap; background:null }
        }
        RowLayout { Layout.fillWidth:true
            TextField { id:search; Layout.fillWidth:true; implicitHeight:31; placeholderText:"Search names, content and tags"; color:backend.textColor; placeholderTextColor:backend.mutedColor; font.family:"Inter"; font.pixelSize:9; leftPadding:9; background:Rectangle{color:backend.baseColor;border.color:search.activeFocus?backend.accentColor:backend.lineColor} onTextChanged:root.refresh() }
            NocturneButton { text:"CAPTURE CLIPBOARD"; onClicked:{var n=name.text.trim()||"Clipboard "+Qt.formatDateTime(new Date(),"MMM d · h:mm AP");backend.run([root.tool,"capture",n,tags.text],3000);root.clearForm();root.refresh()} }
        }
        ListView { id:list; Layout.fillWidth:true; Layout.fillHeight:true; model:root.items; spacing:5; clip:true; currentIndex:count?0:-1
            Text { anchors.centerIn:parent; visible:!root.items.length; text:"THE VAULT IS EMPTY"; color:backend.mutedColor; font.family:"monospace"; font.pixelSize:10 }
            delegate:Rectangle { required property var modelData; required property int index; width:ListView.view.width; height:72; color:ListView.isCurrentItem?backend.overlayColor:backend.surfaceColor; border.color:modelData.pinned?backend.accentColor:(ListView.isCurrentItem?backend.accent2Color:backend.lineColor)
                RowLayout { anchors.fill:parent; anchors.margins:7; spacing:7
                    ColumnLayout { Layout.fillWidth:true; spacing:2
                        RowLayout { Layout.fillWidth:true; Text{Layout.fillWidth:true;text:modelData.name;color:backend.textColor;font.family:"Inter";font.pixelSize:10;font.bold:modelData.pinned;elide:Text.ElideRight} Text{text:(modelData.tags||[]).map(function(x){return "#"+x}).join("  ");color:backend.accentColor;font.family:"monospace";font.pixelSize:7;elide:Text.ElideRight} }
                        Text { Layout.fillWidth:true; text:modelData.content.replace(/\n/g,"  "); color:backend.mutedColor; font.family:"monospace"; font.pixelSize:8; elide:Text.ElideRight }
                        Text { text:(modelData.uses||0)+" USES"; color:backend.mutedColor; font.family:"monospace"; font.pixelSize:7 }
                    }
                    NocturneButton { text:"COPY"; selected:true; onClicked:root.runAction(["copy",String(modelData.id)]) }
                    NocturneButton { visible:/^https?:\/\/[^ ]+$/.test(modelData.content); text:"OPEN"; onClicked:root.runAction(["open",String(modelData.id)]) }
                    NocturneButton { text:modelData.pinned?"★":"☆"; selected:modelData.pinned; onClicked:root.runAction(["pin",String(modelData.id)]) }
                    NocturneButton { text:"EDIT"; onClicked:root.editItem(modelData) }
                    NocturneButton { text:root.pendingDelete===modelData.id?"CONFIRM ×":"×"; danger:true; onClicked:root.requestDelete(modelData) }
                }
                MouseArea { anchors.fill:parent; z:-1; hoverEnabled:true; onEntered:list.currentIndex=index }
            }
            ScrollBar.vertical:ScrollBar{policy:ScrollBar.AsNeeded}
        }
        Text { Layout.fillWidth:true; text:"ENTER COPIES · CONTENT NEVER ENTERS TRACE OR SUPPORT REPORTS · EXPORT IS OPT-IN"; color:backend.mutedColor; font.family:"monospace"; font.pixelSize:8 }
    }
    Timer{id:deleteReset;interval:6000;onTriggered:root.pendingDelete=0}
    Component.onCompleted:{refresh();name.forceActiveFocus()}
}
