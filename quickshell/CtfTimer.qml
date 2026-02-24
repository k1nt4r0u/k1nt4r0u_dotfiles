import QtQuick
import QtQuick.Layouts
import Quickshell.Io

Rectangle {
    id: ctfTimer

    implicitHeight: timerLayout.implicitHeight + 28
    radius: 14
    color: Qt.rgba(17/255, 17/255, 27/255, 0.75)
    border.color: Qt.rgba(176/255, 196/255, 239/255, 0.15)
    border.width: 1

    Behavior on implicitHeight { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

    property int totalSeconds: 0
    property int remainingSeconds: 0
    property bool timerRunning: false
    property bool timerFinished: false

    // Preset durations in seconds
    property var presets: [
        { label: "30m", secs: 1800 },
        { label: "1h", secs: 3600 },
        { label: "2h", secs: 7200 },
        { label: "4h", secs: 14400 },
        { label: "8h", secs: 28800 },
        { label: "24h", secs: 86400 },
        { label: "48h", secs: 172800 }
    ]

    property string timeDisplay: {
        var s = remainingSeconds
        var h = Math.floor(s / 3600)
        var m = Math.floor((s % 3600) / 60)
        var sec = s % 60
        return (h < 10 ? "0" : "") + h + ":" + (m < 10 ? "0" : "") + m + ":" + (sec < 10 ? "0" : "") + sec
    }

    property real progress: totalSeconds > 0 ? remainingSeconds / totalSeconds : 0

    Timer {
        id: countdown
        interval: 1000
        running: ctfTimer.timerRunning && ctfTimer.remainingSeconds > 0
        repeat: true
        onTriggered: {
            ctfTimer.remainingSeconds--
            if (ctfTimer.remainingSeconds <= 0) {
                ctfTimer.timerRunning = false
                ctfTimer.timerFinished = true
                notifyProc.running = true
            }
        }
    }

    Process {
        id: notifyProc
        command: ["notify-send", "-u", "critical", "⏱️ CTF Timer", "Time's up! Competition timer has ended."]
    }

    ColumnLayout {
        id: timerLayout
        anchors {
            left: parent.left; right: parent.right
            top: parent.top
            margins: 14
        }
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            Text {
                text: "⏱  CTF Timer"
                color: "#cdd6f4"
                font { family: "Victor Mono SemiBold"; pixelSize: 15; bold: true }
            }
            Item { Layout.fillWidth: true }
            Text {
                text: ctfTimer.timerRunning ? "LIVE" : ctfTimer.timerFinished ? "DONE" : "IDLE"
                color: ctfTimer.timerRunning ? "#a6e3a1" : ctfTimer.timerFinished ? "#f38ba8" : "#6c7086"
                font { family: "Victor Mono SemiBold"; pixelSize: 14; bold: true }
            }
        }

        // Timer display
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: ctfTimer.timeDisplay
            color: ctfTimer.timerFinished ? "#f38ba8" :
                   ctfTimer.remainingSeconds < 300 && ctfTimer.timerRunning ? "#f9e2af" : "#cdd6f4"
            font {
                family: "Victor Mono SemiBold"
                pixelSize: 34
                bold: true
            }

            Behavior on color { ColorAnimation { duration: 300 } }
        }

        // Progress bar
        Rectangle {
            Layout.fillWidth: true
            height: 4
            radius: 2
            color: Qt.rgba(1,1,1,0.08)

            Rectangle {
                width: parent.width * ctfTimer.progress
                height: parent.height
                radius: 2
                color: ctfTimer.remainingSeconds < 300 && ctfTimer.timerRunning ? "#f9e2af" :
                       ctfTimer.timerFinished ? "#f38ba8" : "#C0E2F3"
                Behavior on width { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation { duration: 300 } }
            }
        }

        // Preset buttons
        RowLayout {
            Layout.fillWidth: true
            spacing: 4
            visible: !ctfTimer.timerRunning

            Repeater {
                model: ctfTimer.presets.length
                delegate: Rectangle {
                    Layout.fillWidth: true
                    height: 28
                    radius: 6
                    color: presetMa.containsMouse ? Qt.rgba(192/255, 226/255, 243/255, 0.15) : Qt.rgba(1,1,1,0.05)
                    border.color: presetMa.containsMouse ? Qt.rgba(192/255, 226/255, 243/255, 0.3) : "transparent"
                    Behavior on color { ColorAnimation { duration: 150 } }

                    property var preset: ctfTimer.presets[index]

                    MouseArea {
                        id: presetMa
                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            ctfTimer.totalSeconds = parent.preset.secs
                            ctfTimer.remainingSeconds = parent.preset.secs
                            ctfTimer.timerFinished = false
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: parent.preset.label
                        color: "#a6adc8"
                        font { family: "Victor Mono SemiBold"; pixelSize: 14 }
                    }
                }
            }
        }

        // Controls
        RowLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            spacing: 8

            // Start/Pause
            Rectangle {
                Layout.fillWidth: true
                height: 32
                radius: 8
                color: startMa.containsMouse ?
                    (ctfTimer.timerRunning ? Qt.rgba(249/255, 226/255, 175/255, 0.2) : Qt.rgba(166/255, 227/255, 161/255, 0.2)) :
                    Qt.rgba(1,1,1,0.06)
                Behavior on color { ColorAnimation { duration: 150 } }

                MouseArea {
                    id: startMa
                    anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (ctfTimer.timerRunning) {
                            ctfTimer.timerRunning = false
                        } else if (ctfTimer.remainingSeconds > 0) {
                            ctfTimer.timerRunning = true
                            ctfTimer.timerFinished = false
                        }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: ctfTimer.timerRunning ? "⏸  Pause" : "▶  Start"
                    color: ctfTimer.timerRunning ? "#f9e2af" : "#a6e3a1"
                    font { family: "Victor Mono SemiBold"; pixelSize: 15 }
                }
            }

            // Reset
            Rectangle {
                Layout.fillWidth: true
                height: 32
                radius: 8
                color: resetMa.containsMouse ? Qt.rgba(243/255, 139/255, 168/255, 0.2) : Qt.rgba(1,1,1,0.06)
                Behavior on color { ColorAnimation { duration: 150 } }

                MouseArea {
                    id: resetMa
                    anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        ctfTimer.timerRunning = false
                        ctfTimer.remainingSeconds = ctfTimer.totalSeconds
                        ctfTimer.timerFinished = false
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: "↺  Reset"
                    color: "#f38ba8"
                    font { family: "Victor Mono SemiBold"; pixelSize: 15 }
                }
            }
        }

        // +5m / +10m quick add while running
        RowLayout {
            Layout.fillWidth: true
            spacing: 4
            visible: ctfTimer.timerRunning

            Repeater {
                model: [{ label: "+5m", secs: 300 }, { label: "+10m", secs: 600 }, { label: "+30m", secs: 1800 }]
                delegate: Rectangle {
                    Layout.fillWidth: true
                    height: 24
                    radius: 6
                    color: addMa.containsMouse ? Qt.rgba(1,1,1,0.1) : Qt.rgba(1,1,1,0.04)
                    Behavior on color { ColorAnimation { duration: 150 } }

                    MouseArea {
                        id: addMa
                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            ctfTimer.totalSeconds += modelData.secs
                            ctfTimer.remainingSeconds += modelData.secs
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: modelData.label
                        color: "#6c7086"
                        font { family: "Victor Mono SemiBold"; pixelSize: 14 }
                    }
                }
            }
        }
    }
}
