import QtQuick
import QtQuick.Layouts
import Quickshell.Io

Rectangle {
    id: toolkit

    implicitHeight: toolLayout.implicitHeight + 28
    radius: 14
    color: Qt.rgba(17/255, 17/255, 27/255, 0.75)
    border.color: Qt.rgba(176/255, 196/255, 239/255, 0.15)
    border.width: 1

    Behavior on implicitHeight { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

    property var categories: [
        {
            name: "Reverse Engineering",
            icon: "🔍",
            tools: [
                { name: "Ghidra", cmd: "_JAVA_AWT_WM_NONREPARENTING=1 ghidra", icon: "󰨊" },
                { name: "IDA Pro", cmd: "/home/kintarou/tools/ida-pro-9.0/ida", icon: "󰈮" },
                { name: "radare2", cmd: "foot -e r2 -", icon: "" },
                { name: "DIE", cmd: "die", icon: "󰈔" },
                { name: "pwndbg", cmd: "foot -e gdb", icon: "󰃤" }
            ]
        },
        {
            name: "Network",
            icon: "🌐",
            tools: [
                { name: "Wireshark", cmd: "wireshark", icon: "󰖟" },
                { name: "nmap scan", cmd: "foot -e sudo nmap -sV -sC -A localhost", icon: "󱂛" },
                { name: "Burp Suite", cmd: "burpsuite", icon: "󰒍" }
            ]
        },
        {
            name: "Pwn / Exploit",
            icon: "💀",
            tools: [
                { name: "Python3", cmd: "foot -e python3", icon: "" },
                { name: "pwntools", cmd: "foot -e python3 -c 'from pwn import *; import IPython; IPython.embed()'", icon: "󰌠" }
            ]
        },
        {
            name: "Forensics",
            icon: "🔬",
            tools: [
                { name: "binwalk", cmd: "foot -e binwalk --help", icon: "󰱼" },
                { name: "Docker", cmd: "foot -e lazydocker", icon: "󰡨" }
            ]
        }
    ]

    property int expandedCategory: -1

    Process {
        id: launchProc
        command: ["sh", "-c", "true"]
        onExited: {}
    }

    ColumnLayout {
        id: toolLayout
        anchors {
            left: parent.left; right: parent.right
            top: parent.top
            margins: 14
        }
        spacing: 8

        // Header
        Text {
            text: "🛠  CTF Toolkit"
            color: "#cdd6f4"
            font { family: "Victor Mono SemiBold"; pixelSize: 15; bold: true }
        }

        Repeater {
            model: toolkit.categories.length
            delegate: ColumnLayout {
                id: catCol
                Layout.fillWidth: true
                spacing: 4

                property var cat: toolkit.categories[index]
                property bool expanded: toolkit.expandedCategory === index

                Rectangle {
                    Layout.fillWidth: true
                    height: 32
                    radius: 8
                    color: catMa.containsMouse ? Qt.rgba(1,1,1,0.08) : Qt.rgba(1,1,1,0.04)
                    Behavior on color { ColorAnimation { duration: 150 } }

                    MouseArea {
                        id: catMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: toolkit.expandedCategory = catCol.expanded ? -1 : index
                    }

                    RowLayout {
                        anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                        Text {
                            text: catCol.cat.icon + "  " + catCol.cat.name
                            color: "#bac2de"
                            font { family: "Victor Mono SemiBold"; pixelSize: 15 }
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: catCol.expanded ? "󰅀" : "󰅂"
                            color: "#6c7086"
                            font { family: "Victor Mono SemiBold"; pixelSize: 16 }
                        }
                    }
                }

                // Tool buttons grid
                GridLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 8
                    columns: 3
                    rowSpacing: 4
                    columnSpacing: 4
                    visible: catCol.expanded
                    opacity: catCol.expanded ? 1.0 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

                    Repeater {
                        model: catCol.expanded ? catCol.cat.tools.length : 0
                        delegate: Rectangle {
                            Layout.fillWidth: true
                            height: 36
                            radius: 8
                            color: toolMa.containsMouse ? Qt.rgba(192/255, 226/255, 243/255, 0.15) : Qt.rgba(1,1,1,0.05)
                            border.color: toolMa.containsMouse ? Qt.rgba(192/255, 226/255, 243/255, 0.3) : "transparent"
                            border.width: 1
                            Behavior on color { ColorAnimation { duration: 150 } }
                            Behavior on border.color { ColorAnimation { duration: 150 } }

                            property var tool: catCol.cat.tools[index]

                            MouseArea {
                                id: toolMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    launchProc.command = ["sh", "-c", parent.tool.cmd + " &"]
                                    launchProc.running = true
                                }
                            }

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 1
                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: parent.parent.tool.icon
                                    color: "#C0E2F3"
                                    font { family: "Victor Mono SemiBold"; pixelSize: 15 }
                                }
                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: parent.parent.tool.name
                                    color: "#a6adc8"
                                    font { family: "Victor Mono SemiBold"; pixelSize: 14 }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
