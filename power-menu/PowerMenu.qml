pragma ComponentBehavior: Bound

import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Wayland
import Quickshell.Io

Scope {
    id: root
    property var theme: DefaultTheme {}

    IpcHandler {
        target: "power-menu"
        function toggle(): void {
            powerPanel.isActive = !powerPanel.isActive;

            if (powerPanel.isActive) {
                powerPanel.selectedOption = 0;
                actionsList.forceActiveFocus();
            } else {
                powerPanel.cancelCountdown();
            }
        }
    }

    Process {
        id: actionProc
        running: false
        stdout: StdioCollector {
            onStreamFinished: console.log(text)
        }
        stderr: StdioCollector {
            onStreamFinished: console.log(text)
        }
    }

    // qmllint disable uncreatable-type
    PanelWindow {
        id: powerPanel
        property bool isActive: false
        property int selectedOption: 0
        property int countdownRemaining: 10
        property bool countdownRunning: false
        property int pendingActionIndex: -1

        function cancelCountdown(): void {
            countdownTimer.stop();
            powerPanel.countdownRunning = false;
            powerPanel.countdownRemaining = 10;
            powerPanel.pendingActionIndex = -1;
        }

        function startCountdown(index): void {
            const action = powerPanel.actions[index];
            if (!action || !action.dangerous)
                return;

            countdownTimer.stop();
            powerPanel.pendingActionIndex = index;
            powerPanel.countdownRemaining = 10;
            powerPanel.countdownRunning = true;
            countdownTimer.restart();
        }

        function runPendingAction(): void {
            if (powerPanel.pendingActionIndex < 0)
                return;

            const action = powerPanel.actions[powerPanel.pendingActionIndex];
            powerPanel.cancelCountdown();
            if (!action)
                return;

            powerPanel.runAction(action);
        }

        function runAction(action): void {
            if (!action)
                return;

            actionProc.running = false;
            actionProc.command = ["sh", "-c", action.command];
            actionProc.running = true;
            powerPanel.cancelCountdown();
            powerPanel.isActive = false;
        }

        property var actions: [
            {
                name: "PowerOff",
                command: "poweroff",
                dangerous: true,
                icon: "icons/poweroff.svg"
            },
            {
                name: "Restart",
                command: "reboot",
                dangerous: true,
                icon: "icons/restart.svg"
            },
            {
                name: "Sleep",
                command: "systemctl suspend",
                dangerous: true,
                icon: "icons/sleep.svg"
            },
            {
                name: "Lock",
                command: "hyprlock",
                dangerous: false,
                icon: "icons/lock.svg"
            },
            {
                name: "Logout",
                command: "command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'",
                dangerous: true,
                icon: "icons/logout.svg"
            },
        ]

        visible: powerPanel.isActive
        focusable: true
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        WlrLayershell.namespace: "mellowshell-powermenu"

        exclusionMode: ExclusionMode.Ignore

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        MouseArea {
            anchors.fill: parent
            onClicked: {
                powerPanel.cancelCountdown();
                powerPanel.isActive = false;
            }
            Rectangle {
                anchors.fill: parent
                color: root.theme.bgOverlay
            }
        }

        Timer {
            id: countdownTimer
            interval: 1000
            repeat: true
            running: false
            onTriggered: {
                if (powerPanel.countdownRemaining > 1) {
                    powerPanel.countdownRemaining -= 1;
                } else {
                    powerPanel.runPendingAction();
                }
            }
        }

        Rectangle {
            id: powerBox
            anchors.centerIn: parent
            width: actionsList.contentWidth + 32
            height: 250
            radius: 16
            color: "transparent"
            border.color: "transparent"
            border.width: 0

            Text {
                id: countDownTimer
                visible: powerPanel.countdownRunning
                text: powerPanel.countdownRunning ? "Running in " + powerPanel.countdownRemaining + "s (Esc to cancel)" : ""
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.topMargin: 8
                color: root.theme.accentRed
                font.pixelSize: 16
                font.bold: true
                z: 1
            }

            ListView {
                id: actionsList
                property var panel: powerPanel
                property var appTheme: root.theme

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: countDownTimer.bottom
                anchors.bottom: parent.bottom
                anchors.margins: 16
                anchors.topMargin: 8
                focus: powerPanel.visible
                orientation: ListView.Horizontal
                model: powerPanel.actions
                clip: false
                spacing: 16
                boundsBehavior: Flickable.StopAtBounds
                currentIndex: powerPanel.selectedOption
                highlightFollowsCurrentItem: false

                onVisibleChanged: if (visible)
                    forceActiveFocus()

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Right || event.key === Qt.Key_L || event.key === Qt.Key_Tab) {
                        event.accepted = true;
                        powerPanel.cancelCountdown();
                        powerPanel.selectedOption = Math.min(powerPanel.selectedOption + 1, actionsList.count - 1);
                        actionsList.positionViewAtIndex(powerPanel.selectedOption, ListView.Contain);
                    } else if (event.key === Qt.Key_Left || event.key === Qt.Key_H || event.key === Qt.Key_Backtab) {
                        event.accepted = true;
                        powerPanel.cancelCountdown();
                        powerPanel.selectedOption = Math.max(powerPanel.selectedOption - 1, 0);
                        actionsList.positionViewAtIndex(powerPanel.selectedOption, ListView.Contain);
                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        event.accepted = true;
                        const index = powerPanel.selectedOption;
                        if (index >= 0 && index < powerPanel.actions.length) {
                            const action = powerPanel.actions[index];
                            if (action.dangerous) {
                                if (powerPanel.countdownRunning && powerPanel.pendingActionIndex === index) {
                                    powerPanel.runPendingAction();
                                } else {
                                    powerPanel.startCountdown(index);
                                }
                            } else {
                                powerPanel.runAction(action);
                            }
                        }
                    } else if (event.key === Qt.Key_Escape) {
                        event.accepted = true;
                        if (powerPanel.countdownRunning) {
                            powerPanel.cancelCountdown();
                        } else {
                            powerPanel.isActive = false;
                        }
                    } else if (event.key >= Qt.Key_1 && event.key <= Qt.Key_9) {
                        const index = event.key - Qt.Key_1;
                        if (index >= 0 && index < powerPanel.actions.length) {
                            const action = powerPanel.actions[index];

                            if (powerPanel.selectedOption !== index) {
                                powerPanel.cancelCountdown();
                                powerPanel.selectedOption = index;
                                actionsList.positionViewAtIndex(powerPanel.selectedOption, ListView.Contain);
                            }

                            if (action.dangerous) {
                                if (powerPanel.countdownRunning && powerPanel.pendingActionIndex === index) {
                                    powerPanel.runPendingAction();
                                } else {
                                    powerPanel.startCountdown(index);
                                }
                            } else {
                                powerPanel.runAction(action);
                            }
                            event.accepted = true;
                        }
                    }
                }

                highlight: null

                delegate: Rectangle {
                    id: actionDelegate
                    required property var modelData
                    required property int index

                    readonly property var panel: ListView.view.panel
                    readonly property var appTheme: ListView.view.appTheme
                    property bool isDangerous: modelData.dangerous === true
                    property bool isSelected: index === panel.selectedOption

                    width: 130
                    height: 130
                    radius: 12
                    color: appTheme.bgBase
                    border.color: actionDelegate.isSelected ? (actionDelegate.isDangerous ? appTheme.accentRed : appTheme.accentPrimary) : "transparent"
                    border.width: actionDelegate.isSelected ? 2 : 0
                    scale: actionDelegate.isSelected ? 1.05 : 1.0
                    z: actionDelegate.isSelected ? 1 : 0
                    transformOrigin: Item.Center

                    Behavior on scale {
                        NumberAnimation {
                            duration: 100
                            easing.type: Easing.OutCubic
                        }
                    }

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 10

                        Image {
                            source: Qt.resolvedUrl(actionDelegate.modelData.icon ?? "")
                            sourceSize.width: 32
                            sourceSize.height: 32
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                            opacity: actionDelegate.isSelected || delegateMouse.containsMouse ? 1.0 : 0.7
                            Layout.alignment: Qt.AlignHCenter
                        }

                        Text {
                            text: actionDelegate.modelData.name ?? ""
                            color: actionDelegate.isDangerous ? appTheme.accentRed : (actionDelegate.isSelected ? appTheme.textPrimary : appTheme.textSecondary)
                            font.pixelSize: 15
                            font.bold: actionDelegate.isSelected
                            horizontalAlignment: Text.AlignHCenter
                            Layout.alignment: Qt.AlignHCenter
                            elide: Text.ElideRight
                        }
                    }

                    MouseArea {
                        id: delegateMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: {
                            if (actionDelegate.panel.selectedOption !== actionDelegate.index)
                                actionDelegate.panel.cancelCountdown();
                            actionDelegate.panel.selectedOption = actionDelegate.index;
                        }
                    }
                }
            }
        }
    }
    // qmllint enable uncreatable-type
}
