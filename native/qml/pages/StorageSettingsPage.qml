import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"

Rectangle {
    id: root; color: backend.baseColor; property bool active: false
    property var storageState: ({filesystem:{total:0,used:0,free:0,percent:0},categories:{},cleanup:[],protected:[]})
    property var duplicates: ({groups:[],reclaimable:0})
    property string confirmTarget: ""
    readonly property string tool: backend.home + "/.config/hypr/scripts/storage-control"
    function size(value) { var n=Number(value||0), units=["B","KiB","MiB","GiB","TiB"],i=0; while(n>=1024&&i<units.length-1){n/=1024;i++} return (i? n.toFixed(n>=10?1:2):Math.round(n))+" "+units[i] }
    function refresh(){var next=backend.json([tool,"status"],10000);if(next&&next.filesystem&&next.categories&&next.cleanup)storageState=next}
    function clean(id){if(confirmTarget!==id){confirmTarget=id;confirmReset.restart();return} backend.run([tool,"clean",id],30000);confirmTarget="";refreshDelay.restart()}
    ScrollView { anchors.fill:parent; contentWidth:availableWidth; ScrollBar.horizontal.policy:ScrollBar.AlwaysOff
        ColumnLayout { x:26;width:parent.width-52;spacing:14;Item{Layout.preferredHeight:10}
            SettingsPageHeader{Layout.fillWidth:true;eyebrow:"SPACE + RETENTION";title:"Storage Center";description:"See where space goes, preview bounded cleanup targets and detect large duplicate downloads without touching personal files.";badge:(storageState.filesystem.percent||0)+"% USED"}
            SettingsCard{Layout.fillWidth:true;title:"SYSTEM DISK";description:size(storageState.filesystem.free)+" free of "+size(storageState.filesystem.total);icon:"drive-harddisk";glyph:"▰"
                Rectangle{Layout.fillWidth:true;implicitHeight:16;color:backend.baseColor;border.color:backend.lineColor
                    Rectangle{height:parent.height-2;width:(parent.width-2)*Math.min(1,(storageState.filesystem.percent||0)/100);x:1;y:1;color:(storageState.filesystem.percent||0)>90?"#e17780":backend.accentColor}
                }
                GridLayout{Layout.fillWidth:true;columns:4;columnSpacing:8
                    Repeater{model:[{l:"CACHE",v:storageState.categories.cache},{l:"DOWNLOADS",v:storageState.categories.downloads},{l:"STEAM",v:storageState.categories.steam},{l:"LOCAL AI",v:storageState.categories.models}]
                        Rectangle{required property var modelData;Layout.fillWidth:true;implicitHeight:48;color:backend.baseColor;border.color:backend.lineColor;Column{anchors.centerIn:parent;spacing:2;Text{anchors.horizontalCenter:parent.horizontalCenter;text:root.size(modelData.v);color:backend.textColor;font.family:"monospace";font.pixelSize:10;font.bold:true}Text{anchors.horizontalCenter:parent.horizontalCenter;text:modelData.l;color:backend.mutedColor;font.family:"Inter";font.pixelSize:7;font.bold:true}}}
                    }
                }
            }
            SettingsCard{Layout.fillWidth:true;title:"SAFE CLEANUP";description:"Every target is explicit. Steam, documents, rollback points and Codex runtimes are protected.";icon:"edit-clear-history";glyph:"⌫"
                Repeater{model:root.storageState.cleanup;Rectangle{required property var modelData;Layout.fillWidth:true;implicitHeight:48;color:backend.baseColor;border.color:backend.lineColor
                    RowLayout{anchors.fill:parent;anchors.margins:8;Text{Layout.fillWidth:true;text:modelData.label;color:backend.textColor;font.family:"Inter";font.pixelSize:9;font.bold:true}Text{text:root.size(modelData.bytes);color:backend.mutedColor;font.family:"monospace";font.pixelSize:8}NocturneButton{text:root.confirmTarget===modelData.id?"CONFIRM":"CLEAN";danger:root.confirmTarget===modelData.id;enabled:(modelData.bytes||0)>0;onClicked:root.clean(modelData.id)}}
                }}
                RowLayout{Layout.fillWidth:true;NocturneButton{Layout.fillWidth:true;text:"REMOVE UNUSED FLATPAKS";onClicked:{backend.run([root.tool,"clean","flatpak-unused"],60000);root.refreshDelay.restart()}}NocturneButton{Layout.fillWidth:true;text:"ADMIN CACHE + JOURNAL";onClicked:backend.start([root.tool,"clean","admin"])}}
            }
            SettingsCard{Layout.fillWidth:true;title:"LARGE DUPLICATES";description:"Hashes files over 50 MiB in Downloads only when requested; nothing is deleted automatically.";icon:"edit-copy";glyph:"≡"
                RowLayout{Layout.fillWidth:true;NocturneButton{text:"SCAN DOWNLOADS";selected:true;onClicked:duplicates=backend.json([root.tool,"duplicates",backend.home+"/Downloads"],120000)||duplicates}Text{Layout.fillWidth:true;text:(duplicates.groups||[]).length+" GROUPS · "+root.size(duplicates.reclaimable)+" POTENTIALLY RECLAIMABLE";color:backend.mutedColor;font.family:"monospace";font.pixelSize:8}}
                Repeater{model:(root.duplicates.groups||[]).slice(0,5);Text{required property var modelData;Layout.fillWidth:true;text:modelData.map(function(x){return x.path}).join("  =  ");color:backend.textColor;font.family:"monospace";font.pixelSize:8;elide:Text.ElideMiddle}}
            }
            Item{Layout.preferredHeight:16}
        }
    }
    Timer{id:confirmReset;interval:6000;onTriggered:root.confirmTarget=""}
    Timer{id:refreshDelay;interval:700;onTriggered:root.refresh()}
    onActiveChanged:if(active)Qt.callLater(refresh);Component.onCompleted:if(active)Qt.callLater(refresh)
}
