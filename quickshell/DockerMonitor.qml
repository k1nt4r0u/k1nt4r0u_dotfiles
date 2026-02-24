import QtQuick
import QtQuick.Layouts
import Quickshell.Io

Rectangle {
    id: dockerMon

    implicitHeight: dockerLayout.implicitHeight + 28
    radius: 14
    color: Qt.rgba(17/255, 17/255, 27/255, 0.75)
    border.color: Qt.rgba(176/255, 196/255, 239/255, 0.15)
    border.width: 1

    Behavior on implicitHeight { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

    property var containers: []
    property bool expanded: false

    Component.onCompleted: listProc.running = true

    Timer {
        interval: 10000; running: true; repeat: true
        onTriggered: listProc.running = true
    }

    Process {
        id: listProc
        property string buf: ""
        command: ["sh", "-c", "docker ps -a --format '{{.Names}}|{{.Status}}|{{.Image}}|{{.State}}' 2>/dev/null"]
        stdout: SplitParser {
            onRead: data => { listProc.buf += data + "\n" }
        }
        onExited: {
            var lines = listProc.buf.trim().split("\n")
            var result = []
            for (var i = 0; i < lines.length; i++) {
                if (lines[i].length === 0) continue
                var p = lines[i].split("|")
                result.push({ name: p[0]||"", status: p[1]||"", image: p[2]||"", state: p[3]||"" })
            }
            dockerMon.containers = result
            listProc.buf = ""
        }
    }

    Process {
        id: dockerCmd
        command: ["sh", "-c", "true"]
        onExited: listProc.running = true
    }

    ColumnLayout {
        id: dockerLayout
        anchors {
            left: parent.left; right: parent.right
            top: parent.top
            margins: 14
        }
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            Text {
                text: "🐳  Docker Labs"
                color: "#cdd6f4"
                font { family: "Victor Mono SemiBold"; pixelSize: 15; bold: true }
            }
            Item { Layout.fillWidth: true }
            Text {
                property int runCount: {
                    var c = 0
                    for (var i = 0; i < dockerMon.containers.length; i++)
                        if (dockerMon.containers[i].state === "running") c++
                    return c
                }
                text: runCount + "/" + dockerMon.containers.length + " running"
                color: runCount > 0 ? "#a6e3a1" : "#6c7086"
                font { family: "Victor Mono SemiBold"; pixelSize: 15 }
            }

            Rectangle {
                width: 24; height: 24; radius: 6
                color: lazyMa.containsMouse ? Qt.rgba(1,1,1,0.12) : Qt.rgba(1,1,1,0.06)
                Behavior on color { ColorAnimation { duration: 150 } }
                Text {
                    anchors.centerIn: parent
                    text: "󰊳"
                    color: "#C0E2F3"
                    font { family: "Victor Mono SemiBold"; pixelSize: 15 }
                }
                MouseArea {
                    id: lazyMa
                    anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: { dockerCmd.command = ["sh", "-c", "foot -e lazydocker &"]; dockerCmd.running = true }
                }
            }
        }

        Repeater {
            model: dockerMon.containers.length
            delegate: Rectangle {
                Layout.fillWidth: true
                height: dockerMon.expanded ? 56 : 32
                radius: 8
                color: cMa.containsMouse ? Qt.rgba(1,1,1,0.08) : Qt.rgba(1,1,1,0.04)
                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                clip: true

                property var ctr: dockerMon.containers[index]

                MouseArea {
                    id: cMa
                    anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: dockerMon.expanded = !dockerMon.expanded
                }

                ColumnLayout {
                    anchors { fill: parent; leftMargin: 10; rightMargin: 10; topMargin: 4; bottomMargin: 4 }
                    spacing: 2

                    RowLayout {
                        Layout.fillWidth: true
                        Rectangle {
                            width: 8; height: 8; radius: 4
                            color: parent.parent.parent.ctr.state === "running" ? "#a6e3a1" : "#f38ba8"
                        }
                        Text {
                            text: parent.parent.parent.ctr.name
                            color: "#cdd6f4"
                            font { family: "Victor Mono SemiBold"; pixelSize: 15; bold: true }
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: parent.parent.parent.ctr.state === "running" ? "Up" : "Stopped"
                            color: parent.parent.parent.ctr.state === "running" ? "#a6e3a1" : "#f38ba8"
                            font { family: "Victor Mono SemiBold"; pixelSize: 14 }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        visible: dockerMon.expanded
                        Text {
                            text: parent.parent.parent.ctr.image
                            color: "#6c7086"
                            font { family: "Victor Mono SemiBold"; pixelSize: 14 }
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        Rectangle {
                            width: 22; height: 22; radius: 5
                            color: startMa.containsMouse ? Qt.rgba(166/255, 227/255, 161/255, 0.2) : Qt.rgba(1,1,1,0.06)
                            visible: parent.parent.parent.ctr.state !== "running"
                            Text { anchors.centerIn: parent; text: "▶"; color: "#a6e3a1"; font.pixelSize: 14 }
                            MouseArea {
                                id: startMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: { dockerCmd.command = ["docker", "start", parent.parent.parent.parent.parent.ctr.name]; dockerCmd.running = true }
                            }
                        }
                        Rectangle {
                            width: 22; height: 22; radius: 5
                            color: stopMa.containsMouse ? Qt.rgba(243/255, 139/255, 168/255, 0.2) : Qt.rgba(1,1,1,0.06)
                            visible: parent.parent.parent.ctr.state === "running"
                            Text { anchors.centerIn: parent; text: "■"; color: "#f38ba8"; font.pixelSize: 14 }
                            MouseArea {
                                id: stopMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: { dockerCmd.command = ["docker", "stop", parent.parent.parent.parent.parent.ctr.name]; dockerCmd.running = true }
                            }
                        }
                        Rectangle {
                            width: 22; height: 22; radius: 5
                            color: restartMa.containsMouse ? Qt.rgba(249/255, 226/255, 175/255, 0.2) : Qt.rgba(1,1,1,0.06)
                            visible: parent.parent.parent.ctr.state === "running"
                            Text { anchors.centerIn: parent; text: "↻"; color: "#f9e2af"; font.pixelSize: 14 }
                            MouseArea {
                                id: restartMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: { dockerCmd.command = ["docker", "restart", parent.parent.parent.parent.parent.ctr.name]; dockerCmd.running = true }
                            }
                        }
                    }
                }
            }
        }
    }
}
