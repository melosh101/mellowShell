import Quickshell
import QtQuick
import Quickshell.Hyprland 

  Row {
    spacing: 4

    Repeater {
      model: Hyprland.workspaces

      Rectangle {
        required property var modelData
        width: 20
        height: 20
        radius: 4

        color: modelData.active ? "#ae00ef" : "#0e0e0e"
        Text {
          anchors.centerIn: parent
          text: modelData.name
          color: modelData.active ? "#1a1b26" : "#fefefe"
          font.pixelSize: 11
        }
      }
    }
  }

