import QtQuick
import QtQuick.Layouts
import Quickshell.Io

Rectangle {
    id: tsStatus

    implicitHeight: tsLayout.implicitHeight + 28
    radius: 14
    color: Qt.rgba(17/255, 17/255, 27/255, 0.75)
    border.color: Qt.rgba(176/255, 196/255, 239/255, 0.15)
    border.width: 1

    Behavior on implicitHeight { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

    property var devices: []
    property bool expanded: true
    property string myIp: "..."

    Component.onCompleted: statusProc.running = true

    Timer {
        interval: 30000; running: true; repeat: true
        onTriggered: statusProc.running = true
    }

    Process {
        id: statusProc
        property string buf: ""
        command: ["sh", "-c", "tailscale status 2>/dev/null | grep -v '^#' | grep -v '^$'"]
        stdout: SplitParser {
            onRead: data => { statusProc.buf += data + "\n" }
        }
        onExited: {
            var lines = statusProc.buf.trim().split("\n")
            var result = []
            for (var i = 0; i < lines.length; i++) {
                if (lines[i].length === 0) continue
                var parts = lines[i].trim().split(/\s+/)
                if (parts.length < 4) continue
                var ip = parts[0]
                var name = parts[1]
                var os = parts[3]
                var statusText = parts.slice(4).join(" ")
                var online = statusText.indexOf("offline") === -1
                if (i === 0) tsStatus.myIp = ip
                result.push({ ip: ip, name: name, os: os, online: online, status: statusText })
            }
            tsStatus.devices = result
            statusProc.buf = ""
        }
    }

    Process {
        id: clipProc
        command: ["sh", "-c", "true"]
    }

    ColumnLayout {
        id: tsLayout
        anchors {
            left: parent.left; right: parent.right
            top: parent.top
            margins: 14
        }
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            Text {
                text: "📡  Tailscale"
                color: "#cdd6f4"
                font { family: "Victor Mono SemiBold"; pixelSize: 15; bold: true }
            }
            Item { Layout.fillWidth: true }
            Text {
                property int onlineCount: {
                    var c = 0
                    for (var i = 0; i < tsStatus.devices.length; i++)
                        if (tsStatus.devices[i].online) c++
                    return c
                }
                text: onlineCount + "/" + tsStatus.devices.length + " online"
                color: onlineCount > 0 ? "#a6e3a1" : "#6c7086"
                font { family: "Victor Mono SemiBold"; pixelSize: 15 }
            }
            Rectangle {
                width: 24; height: 24; radius: 6
                color: refreshMa.containsMouse ? Qt.rgba(1,1,1,0.12) : Qt.rgba(1,1,1,0.06)
                Behavior on color { ColorAnimation { duration: 150 } }
                Text {
                    anchors.centerIn: parent; text: "󰑓"; color: "#C0E2F3"
                    font { family: "Victor Mono SemiBold"; pixelSize: 15 }
                }
                MouseArea {
                    id: refreshMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: statusProc.running = true
                }
            }
        }

        Repeater {
            model: tsStatus.devices.length
            delegate: Rectangle {
                Layout.fillWidth: true
                height: 36
                radius: 8
                color: devMa.containsMouse ? Qt.rgba(1,1,1,0.08) : Qt.rgba(1,1,1,0.04)
                Behavior on color { ColorAnimation { duration: 150 } }

                property var dev: tsStatus.devices[index]

                MouseArea {
                    id: devMa
                    anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        clipProc.command = ["sh", "-c", "echo -n '" + parent.dev.ip + "' | wl-copy"]
                        clipProc.running = true
                    }
                }

                RowLayout {
                    anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                    spacing: 8

                    Rectangle {
                        width: 8; height: 8; radius: 4
                        color: parent.parent.dev.online ? "#a6e3a1" : "#585b70"
                    }

                    Text {
                        text: {
                            var os = parent.parent.dev.os.toLowerCase()
                            if (os === "linux") return "🐧"
                            if (os === "windows") return "🪟"
                            if (os === "ios") return "📱"
                            if (os === "android") return "🤖"
                            return "💻"
                        }
                        font.pixelSize: 15
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        Text {
                            text: parent.parent.parent.dev.name
                            color: parent.parent.parent.dev.online ? "#cdd6f4" : "#585b70"
                            font { family: "Victor Mono SemiBold"; pixelSize: 15; bold: parent.parent.parent.dev.online }
                        }
                        Text {
                            text: parent.parent.parent.dev.ip
                            color: "#6c7086"
                            font { family: "Victor Mono SemiBold"; pixelSize: 14 }
                        }
                    }

                    Text {
                        text: "󰆏"
                        color: devMa.containsMouse ? "#C0E2F3" : "#45475a"
                        font { family: "Victor Mono SemiBold"; pixelSize: 15 }
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                }
            }
        }
    }
}
