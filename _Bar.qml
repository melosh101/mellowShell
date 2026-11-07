import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick

Scope {
	id: root
	property string time
	Variants {
		model: Quickshell.screens
    	
    PanelWindow {
      required property var modelData
      screen: modelData
			anchors {
				top: true
				left: true
				right: true
			}
      
      color: "#e400ff"
			implicitHeight: 30
	    exclusionMode: ExclusionMode.Exclusive	
      Row {
        anchors {
          fill: parent
          leftMargin: 15
          rightMargin: 15
        }
        spacing: 10
			Text {
				anchors.verticalCenter: parent.verticalCenter
				text: root.time	
			}
        Workspaces {
          anchors.verticalCenter: parent.verticalCenter
        }
      }
		}
	}
	
	Process {
		command: ["date", "+%T"]
		id: dateProc
		running: true
		stdout: StdioCollector {
				onStreamFinished: root.time = this.text 
		}
	}
	Timer {
			interval: 1000
			running: true
			repeat: true
			onTriggered: dateProc.running = true
	}
}

// PanelWindow {
// 	anchors: {
// 		top: true
// 		left: true
// 		right: true
// 	}
// 	implicitHeight: 30
// 
// 	Text {
// 		id: clock
// 		anchors.centerIn: parent
// 		Process {
// 			command: ["date", "+%T"]
// 			id: dateProc
// 			running: true
// 			stdout: StdioCollector {
// 					onStreamFinished: clock.text = this.text 
// 			}
// 		}
// 		Timer {
// 				interval: 1000
// 				running: true
// 				repeat: true
// 				onTriggered: dateProc.running = true
// 		}
// 
// 	}
// }
