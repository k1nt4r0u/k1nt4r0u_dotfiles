import QtQuick
import QtQuick.Layouts
import Quickshell.Io

Rectangle {
    id: syncIsland

    implicitHeight: syncLayout.implicitHeight + 28
    radius: 14
    color: Qt.rgba(17/255, 17/255, 27/255, 0.75)
    border.color: Qt.rgba(176/255, 196/255, 239/255, 0.15)
    border.width: 1

    Behavior on implicitHeight { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

    property string status: "offline"
    property var folders: []
    property var devices: []
    property var deviceNames: ({})
    property var recentSyncs: []
    property bool expanded: false

    Component.onCompleted: fetchProc.running = true

    Timer {
        interval: 10000; running: true; repeat: true
        onTriggered: fetchProc.running = true
    }

    Process {
        id: fetchProc
        property string buf: ""
        command: ["/home/kintarou/.config/quickshell/scripts/syncthing-status.sh"]
        stdout: SplitParser {
            onRead: data => { fetchProc.buf += data + "\n" }
        }
        onExited: {
            var lines = fetchProc.buf.trim().split("\n")
            var newFolders = []
            var newDevices = []
            var newNames = {}
            var newSyncs = []

            for (var i = 0; i < lines.length; i++) {
                var line = lines[i]
                if (line.startsWith("status:")) {
                    syncIsland.status = line.substring(7)
                } else if (line.startsWith("folder:")) {
                    var fp = line.substring(7).split("|")
                    newFolders.push({ id: fp[0]||"", label: fp[1]||"", path: fp[2]||"" })
                } else if (line.startsWith("device:")) {
                    var dp = line.substring(7).split("|")
                    newDevices.push({ id: dp[0]||"", status: dp[1]||"", version: dp[2]||"" })
                } else if (line.startsWith("devname:")) {
                    var np = line.substring(8).split("|")
                    newNames[np[0]] = np[1] || np[0]
                } else if (line.startsWith("sync:")) {
                    var sp = line.substring(5).split("|")
                    newSyncs.push({
                        folder: sp[0]||"", item: sp[1]||"", action: sp[2]||"",
                        status: sp[3]||"", time: sp[4]||""
                    })
                }
            }

            syncIsland.folders = newFolders
            syncIsland.devices = newDevices
            syncIsland.deviceNames = newNames
            syncIsland.recentSyncs = newSyncs
            fetchProc.buf = ""
        }
    }

    ColumnLayout {
        id: syncLayout
        anchors {
            left: parent.left; right: parent.right
            top: parent.top
            margins: 14
        }
        spacing: 8

        // Header
        RowLayout {
            Layout.fillWidth: true
            Text {
                text: "🔄  Syncthing"
                color: "#cdd6f4"
                font { family: "Victor Mono SemiBold"; pixelSize: 15; bold: true }
            }
            Item { Layout.fillWidth: true }
            Rectangle {
                width: 10; height: 10; radius: 5
                color: syncIsland.status === "online" ? "#a6e3a1" : "#f38ba8"
                Behavior on color { ColorAnimation { duration: 300 } }
            }
            Text {
                text: syncIsland.status === "online" ? "Online" : "Offline"
                color: syncIsland.status === "online" ? "#a6e3a1" : "#f38ba8"
                font { family: "Victor Mono SemiBold"; pixelSize: 15 }
            }
            Rectangle {
                width: 26; height: 26; radius: 6
                color: webMa.containsMouse ? Qt.rgba(1,1,1,0.12) : Qt.rgba(1,1,1,0.06)
                Behavior on color { ColorAnimation { duration: 150 } }
                Text {
                    anchors.centerIn: parent; text: "󰖟"; color: "#C0E2F3"
                    font { family: "Victor Mono SemiBold"; pixelSize: 15 }
                }
                MouseArea {
                    id: webMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: { webProc.running = true }
                }
                Process {
                    id: webProc
                    command: ["sh", "-c", "xdg-open http://localhost:8384 &"]
                }
            }
        }

        // Connected devices
        Repeater {
            model: syncIsland.devices.length
            delegate: Rectangle {
                Layout.fillWidth: true
                height: 30
                radius: 8
                color: Qt.rgba(1,1,1,0.04)

                property var dev: syncIsland.devices[index]
                property string devName: syncIsland.deviceNames[dev.id] || dev.id

                RowLayout {
                    anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                    Rectangle { width: 8; height: 8; radius: 4; color: "#a6e3a1" }
                    Text {
                        text: parent.parent.devName
                        color: "#cdd6f4"
                        font { family: "Victor Mono SemiBold"; pixelSize: 15; bold: true }
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: parent.parent.dev.version
                        color: "#6c7086"
                        font { family: "Victor Mono SemiBold"; pixelSize: 14 }
                    }
                }
            }
        }

        // Folders
        Repeater {
            model: syncIsland.folders.length
            delegate: Rectangle {
                Layout.fillWidth: true
                height: 30
                radius: 8
                color: Qt.rgba(1,1,1,0.04)

                property var folder: syncIsland.folders[index]

                RowLayout {
                    anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                    Text {
                        text: "📁"
                        font.pixelSize: 14
                    }
                    Text {
                        text: parent.parent.folder.label
                        color: "#cdd6f4"
                        font { family: "Victor Mono SemiBold"; pixelSize: 15 }
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: parent.parent.folder.path
                        color: "#6c7086"
                        font { family: "Victor Mono SemiBold"; pixelSize: 14 }
                        elide: Text.ElideMiddle
                        Layout.maximumWidth: 160
                    }
                }
            }
        }

        // Recent syncs toggle
        Rectangle {
            Layout.fillWidth: true
            height: 30
            radius: 8
            color: syncToggleMa.containsMouse ? Qt.rgba(1,1,1,0.08) : Qt.rgba(1,1,1,0.04)
            Behavior on color { ColorAnimation { duration: 150 } }

            MouseArea {
                id: syncToggleMa
                anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: syncIsland.expanded = !syncIsland.expanded
            }

            RowLayout {
                anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                Text {
                    text: "󰓦"; color: "#C0E2F3"
                    font { family: "Victor Mono SemiBold"; pixelSize: 15 }
                }
                Text {
                    text: "Recent Syncs"
                    color: "#a6adc8"
                    font { family: "Victor Mono SemiBold"; pixelSize: 15 }
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: syncIsland.recentSyncs.length + " items"
                    color: "#6c7086"
                    font { family: "Victor Mono SemiBold"; pixelSize: 15 }
                }
                Text {
                    text: syncIsland.expanded ? "󰅀" : "󰅂"
                    color: "#6c7086"
                    font { family: "Victor Mono SemiBold"; pixelSize: 16 }
                }
            }
        }

        // Recent sync list
        ColumnLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 8
            spacing: 3
            visible: syncIsland.expanded

            Repeater {
                model: syncIsland.expanded ? syncIsland.recentSyncs.length : 0
                delegate: Rectangle {
                    Layout.fillWidth: true
                    height: 40
                    radius: 6
                    color: Qt.rgba(1,1,1,0.03)

                    property var syncItem: syncIsland.recentSyncs[index]

                    ColumnLayout {
                        anchors { fill: parent; leftMargin: 8; rightMargin: 8; topMargin: 4; bottomMargin: 4 }
                        spacing: 1

                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                text: {
                                    var a = parent.parent.parent.syncItem.action
                                    if (a === "update") return "📝"
                                    if (a === "delete") return "🗑"
                                    return "📄"
                                }
                                font.pixelSize: 14
                            }
                            Text {
                                text: {
                                    var item = parent.parent.parent.syncItem.item
                                    var parts = item.split("/")
                                    return parts[parts.length - 1] || item
                                }
                                color: "#cdd6f4"
                                font { family: "Victor Mono SemiBold"; pixelSize: 14 }
                                elide: Text.ElideMiddle
                                Layout.fillWidth: true
                            }
                            Text {
                                text: parent.parent.parent.syncItem.status === "ok" ? "✓" : "✗"
                                color: parent.parent.parent.syncItem.status === "ok" ? "#a6e3a1" : "#f38ba8"
                                font { family: "Victor Mono SemiBold"; pixelSize: 14 }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                text: parent.parent.parent.syncItem.folder
                                color: "#585b70"
                                font { family: "Victor Mono SemiBold"; pixelSize: 12 }
                            }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: parent.parent.parent.syncItem.time
                                color: "#585b70"
                                font { family: "Victor Mono SemiBold"; pixelSize: 12 }
                            }
                        }
                    }
                }
            }
        }
    }
}
