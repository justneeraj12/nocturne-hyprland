import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"

Rectangle{
 id:root;color:backend.baseColor;property bool active:false;property var ruleState:({enabled:false,count:0,active:0,rules:[]});property int pendingDelete:0
 readonly property string tool:backend.home+"/.config/hypr/scripts/automation-rules"
 readonly property var triggers:["docked","mobile","ac","battery","meeting","focus","gaming"]
 readonly property var actions:["dnd-on","dnd-off","caffeine-on","caffeine-off","power","scene"]
 function refresh(){var next=backend.json([tool,"status"],2500);if(next&&next.rules!==undefined)ruleState=next}
 function addRule(){var n=name.text.trim();if(!n)return;backend.run([tool,"add",n,trigger.currentText,action.currentText,value.text.trim()],4000);name.clear();value.clear();refresh()}
 function removeRule(id){if(pendingDelete!==id){pendingDelete=id;deleteReset.restart();return}backend.run([tool,"delete",String(id)],2500);pendingDelete=0;refresh()}
 ScrollView{anchors.fill:parent;contentWidth:availableWidth;ScrollBar.horizontal.policy:ScrollBar.AlwaysOff
  ColumnLayout{x:26;width:parent.width-52;spacing:14;Item{Layout.preferredHeight:10}
   SettingsPageHeader{Layout.fillWidth:true;eyebrow:"WHEN THIS → DO THAT";title:"Automation Builder";description:"Author bounded local rules for dock, power, meeting, focus and gaming states. Rules never execute arbitrary shell text.";badge:ruleState.active+" ACTIVE RULES"}
   SettingsCard{Layout.fillWidth:true;title:"RULE ENGINE";description:"Shares the existing context timer; enabling rules adds no new resident process.";icon:"system-run";glyph:"◎"
    RowLayout{Layout.fillWidth:true;Text{Layout.fillWidth:true;text:ruleState.enabled?"AUTOMATION RULES ENABLED":"AUTOMATION RULES PAUSED";color:ruleState.enabled?backend.accentColor:backend.mutedColor;font.family:"monospace";font.pixelSize:9;font.bold:true}NocturneToggle{checked:ruleState.enabled===true;onToggleRequested:function(v){backend.run([root.tool,v?"enable":"disable"],5000);root.refresh()}}}
   }
   SettingsCard{Layout.fillWidth:true;title:"NEW RULE";description:"Choose a detected state and a safe reversible action.";icon:"list-add";glyph:"+"
    GridLayout{Layout.fillWidth:true;columns:4;columnSpacing:8
     TextField{id:name;Layout.fillWidth:true;placeholderText:"Rule name";color:backend.textColor;placeholderTextColor:backend.mutedColor;font.family:"Inter";font.pixelSize:9;background:Rectangle{color:backend.baseColor;border.color:name.activeFocus?backend.accentColor:backend.lineColor}}
     NocturneComboBox{id:trigger;Layout.fillWidth:true;model:root.triggers}
     NocturneComboBox{id:action;Layout.fillWidth:true;model:root.actions}
     TextField{id:value;Layout.fillWidth:true;enabled:action.currentText==="power"||action.currentText==="scene";placeholderText:action.currentText==="power"?"balanced":(action.currentText==="scene"?"scene-name":"No value needed");color:backend.textColor;placeholderTextColor:backend.mutedColor;font.family:"monospace";font.pixelSize:9;background:Rectangle{color:backend.baseColor;border.color:value.activeFocus?backend.accentColor:backend.lineColor}}
    }
    NocturneButton{Layout.fillWidth:true;text:"ADD RULE";selected:true;enabled:name.text.trim().length>0&&((action.currentText!=="power"&&action.currentText!=="scene")||value.text.trim().length>0);onClicked:root.addRule()}
   }
   SettingsCard{Layout.fillWidth:true;title:"RULES";description:"A rule executes once when its condition becomes true, then waits for the state to change before firing again.";icon:"view-list-details";glyph:"≡"
    Text{visible:!(ruleState.rules||[]).length;text:"NO RULES YET";color:backend.mutedColor;font.family:"monospace";font.pixelSize:9}
    Repeater{model:ruleState.rules||[];Rectangle{required property var modelData;Layout.fillWidth:true;implicitHeight:58;color:backend.baseColor;border.color:modelData.enabled?backend.accent2Color:backend.lineColor
     RowLayout{anchors.fill:parent;anchors.margins:8;ColumnLayout{Layout.fillWidth:true;spacing:2;Text{text:modelData.name;color:backend.textColor;font.family:"Inter";font.pixelSize:9;font.bold:true}Text{text:"WHEN "+String(modelData.trigger).toUpperCase()+"  →  "+String(modelData.action).toUpperCase()+(modelData.value?" · "+modelData.value:"");color:backend.mutedColor;font.family:"monospace";font.pixelSize:8}}NocturneToggle{checked:modelData.enabled;onToggleRequested:function(v){backend.run([root.tool,"toggle",String(modelData.id)],2500);root.refresh()}}NocturneButton{text:root.pendingDelete===modelData.id?"CONFIRM ×":"×";danger:true;onClicked:root.removeRule(modelData.id)}}
    }}
   }
   SettingsCard{Layout.fillWidth:true;title:"ADVANCED SCENES + TRACE";description:"Scene restoration and the private why/when history remain available beside custom rules.";icon:"view-history";glyph:"↶"
    RowLayout{Layout.fillWidth:true;NocturneButton{Layout.fillWidth:true;text:"SCENES";onClicked:backend.start([backend.home+"/.local/bin/nocturne-native","scenes"])}NocturneButton{Layout.fillWidth:true;text:"EXPLAIN CHANGES";onClicked:backend.start([backend.home+"/.local/bin/nocturne-native","automation"])}}
   }
   Item{Layout.preferredHeight:16}
  }
 }
 Timer{id:deleteReset;interval:6000;onTriggered:root.pendingDelete=0}
 onActiveChanged:if(active)Qt.callLater(refresh);Component.onCompleted:if(active)Qt.callLater(refresh)
}
