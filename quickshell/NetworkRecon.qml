import QtQuick
import QtQuick.Layouts
import Quickshell.Io

Rectangle {
    id: netRecon

    implicitHeight: netLayout.implicitHeight + 28
    radius: 14
    color: Qt.rgba(17/255, 17/255, 27/255, 0.75)
    border.color: Qt.rgba(176/255, 196/255, 239/255, 0.15)
    border.width: 1

    Behavior on implicitHeight { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

    property string wlanIp: "..."
    property string tailscaleIp: "..."
    property string publicIp: "..."
    property var listeningPorts: []
    property bool portsExpanded: false

    // Refresh data on load
    Component.onCompleted: {
        ipProc.running = true
        portsProc.running = true
    }

    Timer {
        interval: 15000; running: true; repeat: true
        onTriggered: { ipProc.running = true; portsProc.running = true }
    }

    Process {
        id: ipProc
        command: ["sh", "-c", "echo \"wlan:$(ip -4 addr show wlan0 2>/dev/null | grep -oP 'inet \\K[\\d.]+')\"; echo \"ts:$(ip -4 addr show tailscale0 2>/dev/null | grep -oP 'inet \\K[\\d.]+')\"; echo \"pub:$(curl -s --max-time 3 ifconfig.me 2>/dev/null || echo 'N/A')\""]
        stdout: SplitParser {
            onRead: data => {
                if (data.startsWith("wlan:")) netRecon.wlanIp = data.substring(5) || "N/A"
                else if (data.startsWith("ts:")) netRecon.tailscaleIp = data.substring(3) || "N/A"
                else if (data.startsWith("pub:")) netRecon.publicIp = data.substring(4) || "N/A"
            }
        }
    }

    Process {
        id: portsProc
        property string buf: ""
        command: ["sh", "-c", "ss -tlnp 2>/dev/null | tail -n +2 | awk '{print $4\"|\"$6}' | head -20"]
        stdout: SplitParser {
            onRead: data => { portsProc.buf += data + "\n" }
        }
        onExited: {
            var lines = portsProc.buf.trim().split("\n")
            var result = []
            for (var i = 0; i < lines.length; i++) {
                if (lines[i].length === 0) continue
                var parts = lines[i].split("|")
                var addr = parts[0] || ""
                var proc = parts[1] || ""
                var procName = ""
                var m = proc.match(/\("([^"]+)"/)
                if (m) procName = m[1]
                result.push({ addr: addr, proc: procName })
            }
            netRecon.listeningPorts = result
            portsProc.buf = ""
        }
    }

    Process {
        id: copyProc
        command: ["sh", "-c", "true"]
    }

    ColumnLayout {
        id: netLayout
        anchors {
            left: parent.left; right: parent.right
            top: parent.top
            margins: 14
        }
        spacing: 8

        Text {
            text: "🌐  Network Recon"
            color: "#cdd6f4"
            font { family: "Victor Mono SemiBold"; pixelSize: 15; bold: true }
        }

        // IP addresses
        Repeater {
            model: [
                { label: "WiFi (wlan0)", value: netRecon.wlanIp, icon: "󰖩" },
                { label: "Tailscale", value: netRecon.tailscaleIp, icon: "󰖟" },
                { label: "Public IP", value: netRecon.publicIp, icon: "󰕑" }
            ]
            delegate: Rectangle {
                Layout.fillWidth: true
                height: 30
                radius: 8
                color: ipRowMa.containsMouse ? Qt.rgba(1,1,1,0.08) : Qt.rgba(1,1,1,0.04)
                Behavior on color { ColorAnimation { duration: 150 } }

                property var item: modelData

                MouseArea {
                    id: ipRowMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        copyProc.command = ["sh", "-c", "echo -n '" + parent.item.value + "' | wl-copy"]
                        copyProc.running = true
                    }
                }

                RowLayout {
                    anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                    Text {
                        text: parent.parent.item.icon
                        color: "#C0E2F3"
                        font { family: "Victor Mono SemiBold"; pixelSize: 15 }
                    }
                    Text {
                        text: parent.parent.item.label
                        color: "#a6adc8"
                        font { family: "Victor Mono SemiBold"; pixelSize: 15 }
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: parent.parent.item.value
                        color: "#cdd6f4"
                        font { family: "Victor Mono SemiBold"; pixelSize: 15; bold: true }
                    }
                    Text {
                        text: "󰆏"
                        color: "#6c7086"
                        font { family: "Victor Mono SemiBold"; pixelSize: 15 }
                    }
                }
            }
        }

        // Listening ports
        Rectangle {
            Layout.fillWidth: true
            height: 30
            radius: 8
            color: portsMa.containsMouse ? Qt.rgba(1,1,1,0.08) : Qt.rgba(1,1,1,0.04)
            Behavior on color { ColorAnimation { duration: 150 } }

            MouseArea {
                id: portsMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: netRecon.portsExpanded = !netRecon.portsExpanded
            }

            RowLayout {
                anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                Text { text: "󰒋"; color: "#C0E2F3"; font { family: "Victor Mono SemiBold"; pixelSize: 15 } }
                Text { text: "Listening Ports"; color: "#a6adc8"; font { family: "Victor Mono SemiBold"; pixelSize: 15 } }
                Item { Layout.fillWidth: true }
                Text {
                    text: netRecon.listeningPorts.length + " open"
                    color: netRecon.listeningPorts.length > 10 ? "#f38ba8" : "#a6e3a1"
                    font { family: "Victor Mono SemiBold"; pixelSize: 15; bold: true }
                }
                Text {
                    text: netRecon.portsExpanded ? "󰅀" : "󰅂"
                    color: "#6c7086"
                    font { family: "Victor Mono SemiBold"; pixelSize: 16 }
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 8
            spacing: 2
            visible: netRecon.portsExpanded

            Repeater {
                model: netRecon.portsExpanded ? netRecon.listeningPorts.length : 0
                delegate: Rectangle {
                    Layout.fillWidth: true
                    height: 24
                    radius: 6
                    color: Qt.rgba(1,1,1,0.03)

                    property var portInfo: netRecon.listeningPorts[index]

                    RowLayout {
                        anchors { fill: parent; leftMargin: 8; rightMargin: 8 }
                        Text {
                            text: parent.parent.portInfo.addr
                            color: "#C0E2F3"
                            font { family: "Victor Mono SemiBold"; pixelSize: 14 }
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: parent.parent.portInfo.proc
                            color: "#6c7086"
                            font { family: "Victor Mono SemiBold"; pixelSize: 14 }
                        }
                    }
                }
            }
        }
    }
}
