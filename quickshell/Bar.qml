import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

// Full status bar — replaces Waybar
// Layout: [Arch | Workspaces | Player] ... [Clock] ... [HW | Vol | BT | Net | Bat | QS | Exit]
Item {
    id: bar
    implicitHeight: 42

    // Shared state from parent
    required property bool panelVisible
    signal togglePanel()

    // ── Theme ──
    readonly property color bgColor: Qt.rgba(17/255, 17/255, 27/255, 0.75)
    readonly property color borderColor: Qt.rgba(176/255, 196/255, 239/255, 0.15)
    readonly property color accent: "#b0c4ef"
    readonly property color textColor: "#cdd6f4"
    readonly property color subtextColor: "#a6adc8"
    readonly property string fontFamily: "Hurmit Nerd Font"
    readonly property int fontSize: 14

    // ── Data ──
    property var workspaces: []
    property string playerText: "No music playing"
    property string playerStatus: "Stopped"
    property string clockTime: "00:00"
    property string clockFull: ""
    property int volume: 0
    property bool muted: false
    property string btStatus: "off"
    property string netIcon: "  "
    property string netText: ""
    property int netSignal: 0
    property string batIcon: ""
    property int batCapacity: 0
    property string batStatus: "Unknown"

    // ── CRT flicker ──
    SequentialAnimation on opacity {
        loops: Animation.Infinite
        NumberAnimation { to: 1.0; duration: 240 }
        NumberAnimation { to: 0.97; duration: 60 }
        NumberAnimation { to: 1.0; duration: 240 }
        NumberAnimation { to: 1.0; duration: 3360 }
        NumberAnimation { to: 0.96; duration: 60 }
        NumberAnimation { to: 1.0; duration: 80 }
        NumberAnimation { to: 1.0; duration: 2560 }
        NumberAnimation { to: 0.95; duration: 60 }
        NumberAnimation { to: 1.0; duration: 80 }
        NumberAnimation { to: 1.0; duration: 1260 }
    }

    // ── Data Processes ──
    Timer {
        interval: 100; running: true; repeat: true; triggeredOnStart: true
        onTriggered: {
            var now = new Date()
            var h = now.getHours(); var m = now.getMinutes()
            bar.clockTime = (h < 10 ? "0" : "") + h + ":" + (m < 10 ? "0" : "") + m
            var days = ["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"]
            var months = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"]
            bar.clockFull = days[now.getDay()] + ", " + months[now.getMonth()] + " " + now.getDate() + " • " + bar.clockTime
            workspaceProc.running = true
        }
    }

    Process {
        id: workspaceProc
        command: ["niri", "msg", "-j", "workspaces"]
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => {
                try {
                    var ws = JSON.parse(data)
                    ws.sort(function(a, b) { return a.idx - b.idx })
                    bar.workspaces = ws
                } catch(e) {}
            }
        }
    }

    Process {
        id: playerProc
        command: ["/home/kintarou/.config/quickshell/scripts/media-metadata.sh"]
        stdout: StdioCollector {
            onStreamFinished: {
                let lines = this.text.trim().split("\n")
                let title = ""
                let artist = ""
                for (let line of lines) {
                    let idx = line.indexOf(":")
                    if (idx < 0) continue
                    let key = line.substring(0, idx)
                    let val = line.substring(idx + 1).trim()
                    switch (key) {
                        case "title": title = val; break
                        case "artist": artist = val; break
                        case "status": bar.playerStatus = val; break
                    }
                }
                if (title) {
                    bar.playerText = artist ? (title + " - " + artist) : title
                } else {
                    bar.playerText = "No music playing"
                }
            }
        }
    }

    Timer {
        interval: 1000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: { playerProc.running = true }
    }

    // Fast timer for volume to capture keyboard changes
    Timer {
        interval: 300; running: true; repeat: true; triggeredOnStart: true
        onTriggered: { volumeProc.running = true }
    }

    Timer {
        interval: 2000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: {
            netProc.running = true
            batProc.running = true
            btProc.running = true
        }
    }

    Process {
        id: volumeProc
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => {
                var m = data.match(/Volume:\s+([\d.]+)/)
                if (m) bar.volume = Math.round(parseFloat(m[1]) * 100)
                bar.muted = data.indexOf("[MUTED]") !== -1
            }
        }
    }

    Process {
        id: netProc
        command: ["nmcli", "-t", "-f", "TYPE,STATE,DEVICE,CONNECTION", "dev"]
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => {
                var lines = data.trim().split("\n")
                for (var i = 0; i < lines.length; i++) {
                    var parts = lines[i].split(":")
                    if (parts[1] === "connected" && parts[0] === "wifi") {
                        bar.netText = parts[3] || parts[2]
                        bar.netIcon = "  "
                        wifiSignalProc.running = true
                        return
                    }
                    if (parts[1] === "connected" && parts[0] === "ethernet") {
                        bar.netText = parts[2]
                        bar.netSignal = 0
                        bar.netIcon = "󰌘 "
                        return
                    }
                }
                bar.netText = "disconnected"
                bar.netSignal = 0
                bar.netIcon = "  "
            }
        }
    }

    Process {
        id: wifiSignalProc
        command: ["nmcli", "-t", "-f", "active,signal", "dev", "wifi"]
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => {
                var lines = data.trim().split("\n")
                for (var i = 0; i < lines.length; i++) {
                    var parts = lines[i].split(":")
                    if (parts[0] === "yes") {
                        bar.netSignal = parseInt(parts[1]) || 0
                        return
                    }
                }
            }
        }
    }

    Process {
        id: batProc
        command: ["/bin/bash", "-c", "echo \"$(cat /sys/class/power_supply/BAT1/capacity) $(cat /sys/class/power_supply/BAT1/status)\""]
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => {
                var parts = data.trim().split(" ")
                if (parts.length >= 2) {
                    bar.batCapacity = parseInt(parts[0]) || 0
                    bar.batStatus = parts.slice(1).join(" ")
                    if (bar.batStatus === "Charging" || bar.batStatus === "Full")
                        bar.batIcon = ""
                    else if (bar.batCapacity >= 80) bar.batIcon = ""
                    else if (bar.batCapacity >= 60) bar.batIcon = ""
                    else if (bar.batCapacity >= 40) bar.batIcon = ""
                    else if (bar.batCapacity >= 20) bar.batIcon = ""
                    else bar.batIcon = ""
                }
            }
        }
    }

    Process {
        id: btProc
        command: ["/home/kintarou/.config/quickshell/scripts/bluetooth-status.sh"]
        stdout: StdioCollector {
            onStreamFinished: {
                bar.btStatus = this.text.trim()
            }
        }
    }

    // ── Click action processes ──
    Process { id: btManProc; command: ["blueman-manager"] }
    Process { id: nmEditorProc; command: ["nm-connection-editor"] }
    Process { id: pavuProc; command: ["pavucontrol"] }
    Process { id: wlogoutProc; command: ["wlogout"] }
    Process {
        id: playerToggleProc
        command: ["/bin/bash", "-c", "~/.config/waybar/scripts/player.sh"]
    }
    Process {
        id: playerNextProc
        command: ["/bin/bash", "-c", "~/.config/waybar/scripts/player-next.sh"]
    }
    Process {
        id: playerPrevProc
        command: ["/bin/bash", "-c", "~/.config/waybar/scripts/player-prev.sh"]
    }
    Process {
        id: niriSwitchProc
        property string wsIdx: ""
        command: ["niri", "msg", "action", "focus-workspace", wsIdx]
    }

    // ── Visual Layout ──
    // Left and right use anchors; clock is absolutely centered
    Rectangle {
        id: leftIsland
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: Math.min(leftRow.implicitWidth + 8, parent.width / 2 - centerIsland.width / 2 - 12)
        radius: 14
        color: bar.bgColor
        border.width: 1

        property real borderPulse: 0.15
        SequentialAnimation on borderPulse {
            loops: Animation.Infinite
                NumberAnimation { to: 0.30; duration: 2000; easing.type: Easing.InOutSine }
                NumberAnimation { to: 0.10; duration: 2000; easing.type: Easing.InOutSine }
            }
            border.color: Qt.rgba(176/255, 196/255, 239/255, borderPulse)

            RowLayout {
                id: leftRow
                anchors.fill: parent
                anchors.margins: 4
                spacing: 0

                // Arch logo
                Text {
                    Layout.leftMargin: 10
                    Layout.rightMargin: 6
                    Layout.alignment: Qt.AlignVCenter
                    verticalAlignment: Text.AlignVCenter
                    topPadding: -2
                    text: "󰣇"
                    color: bar.accent
                    font { family: bar.fontFamily; pixelSize: 18 }
                }

                // Workspaces
                Rectangle {
                    Layout.fillHeight: true
                    Layout.margins: 4
                    implicitWidth: wsRow.implicitWidth + 4
                    radius: 10
                    color: Qt.rgba(1, 1, 1, 0.04)

                    RowLayout {
                        id: wsRow
                        anchors.centerIn: parent
                        spacing: 2

                        Repeater {
                            model: bar.workspaces.length
                            delegate: Rectangle {
                                property var ws: bar.workspaces[index]
                                property bool active: ws ? ws.is_active : false
                                width: 30; height: 26
                                radius: 8
                                color: active ? bar.accent : (wsMa.containsMouse ? Qt.rgba(176/255, 196/255, 239/255, 0.15) : "transparent")
                                Behavior on color { ColorAnimation { duration: 200 } }

                                MouseArea {
                                    id: wsMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        niriSwitchProc.wsIdx = ws.idx.toString()
                                        niriSwitchProc.running = true
                                    }
                                }
                                Text {
                                    anchors.centerIn: parent
                                    text: ws ? ws.idx.toString() : ""
                                    color: active ? "#1e1e2e" : (wsMa.containsMouse ? "#cdd6f4" : bar.subtextColor)
                                    font { family: bar.fontFamily; pixelSize: bar.fontSize; bold: active }
                                    Behavior on color { ColorAnimation { duration: 200 } }
                                }
                            }
                        }
                    }
                }

                // Separator
                Rectangle { width: 1; Layout.fillHeight: true; Layout.margins: 8; color: Qt.rgba(1,1,1,0.08) }

                // Player
                Item {
                    id: playerContainer
                    Layout.rightMargin: 8
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    Layout.minimumWidth: 0
                    // Set implicitWidth so the island expands to fit the player text
                    implicitWidth: Math.min(350, playerRow.implicitWidth + 12)

                    scale: playerMa.containsMouse ? 1.02 : 1.0
                    Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 4
                        radius: 8
                        color: playerMa.containsMouse ? Qt.rgba(176/255, 196/255, 239/255, 0.12) : "transparent"
                        Behavior on color { ColorAnimation { duration: 200 } }
                    }

                    RowLayout {
                        id: playerRow
                        anchors.fill: parent
                        anchors.margins: 4
                        spacing: 8
                        
                        Text {
                            text: {
                                if (bar.playerStatus === "Playing") return ""
                                if (bar.playerStatus === "Paused") return ""
                                return ""
                            }
                            color: playerMa.containsMouse ? "#cdd6f4" : (bar.playerStatus === "Playing" ? bar.accent : bar.subtextColor)
                            font { family: bar.fontFamily; pixelSize: bar.fontSize }
                            topPadding: -3 // Shift ONLY the icon up
                            Behavior on color { ColorAnimation { duration: 200 } }
                        }

                        Text {
                            Layout.fillWidth: true
                            Layout.minimumWidth: 0
                            text: bar.playerText
                            elide: Text.ElideRight
                            color: playerMa.containsMouse ? "#cdd6f4" : (bar.playerStatus === "Playing" ? bar.accent :
                                bar.playerStatus === "Paused" ? bar.subtextColor :
                                Qt.rgba(176/255, 196/255, 239/255, 0.4))
                            font { family: bar.fontFamily; pixelSize: bar.fontSize }
                            Behavior on color { ColorAnimation { duration: 200 } }
                        }
                    }

                    MouseArea {
                        id: playerMa
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                        onClicked: function(mouse) {
                            if (mouse.button === Qt.LeftButton) playerToggleProc.running = true
                            else if (mouse.button === Qt.RightButton) playerNextProc.running = true
                            else if (mouse.button === Qt.MiddleButton) playerPrevProc.running = true
                            playerProc.running = true // Immediate refresh
                        }
                        onWheel: (wheel) => {
                            if (wheel.angleDelta.y > 0) playerNextProc.running = true
                            else if (wheel.angleDelta.y < 0) playerPrevProc.running = true
                            playerProc.running = true // Immediate refresh
                        }
                    }
                }
            }
        }

    // ═══ CENTER ISLAND (absolutely centered) ═══
    Rectangle {
        id: centerIsland
        anchors.centerIn: parent
        height: parent.height
        implicitWidth: clockLabel.implicitWidth + 24
        radius: 14
        color: bar.bgColor
        border.width: 1

            property real borderPulse: 0.15
            SequentialAnimation on borderPulse {
                loops: Animation.Infinite
                NumberAnimation { to: 0.30; duration: 2000; easing.type: Easing.InOutSine }
                NumberAnimation { to: 0.10; duration: 2000; easing.type: Easing.InOutSine }
            }
            border.color: Qt.rgba(176/255, 196/255, 239/255, borderPulse)

            Rectangle {
                anchors.fill: parent
                anchors.margins: 4
                radius: 10
                color: clockMa.containsMouse ? Qt.rgba(176/255, 196/255, 239/255, 0.12) : "transparent"
                Behavior on color { ColorAnimation { duration: 200 } }
            }

            property bool showFull: false

            MouseArea {
                id: clockMa
                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                onClicked: parent.showFull = !parent.showFull
            }

            Text {
                id: clockLabel
                anchors.centerIn: parent
                text: centerIsland.showFull ? bar.clockFull : bar.clockTime
                color: clockMa.containsMouse ? "#cdd6f4" : bar.accent
                font { family: bar.fontFamily; pixelSize: bar.fontSize; bold: true }
                Behavior on color { ColorAnimation { duration: 200 } }

                Behavior on text {
                    SequentialAnimation {
                        NumberAnimation { target: clockLabel; property: "opacity"; to: 0.5; duration: 80 }
                        NumberAnimation { target: clockLabel; property: "opacity"; to: 1.0; duration: 200; easing.type: Easing.OutCubic }
                    }
                }
            }
    }

    // ═══ RIGHT ISLAND ═══
    Rectangle {
        id: rightIsland
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        implicitWidth: rightRow.implicitWidth + 8
        radius: 14
        color: bar.bgColor
        border.width: 1

            property real borderPulse: 0.15
            SequentialAnimation on borderPulse {
                loops: Animation.Infinite
                NumberAnimation { to: 0.30; duration: 2000; easing.type: Easing.InOutSine }
                NumberAnimation { to: 0.10; duration: 2000; easing.type: Easing.InOutSine }
            }
            border.color: Qt.rgba(176/255, 196/255, 239/255, borderPulse)

            RowLayout {
                id: rightRow
                anchors.fill: parent
                anchors.margins: 4
                spacing: 0

                // PulseAudio
                BarModule {
                    text: {
                        if (bar.muted) return "󰖁 Muted"
                        var icon = bar.volume >= 66 ? "󰕾" : bar.volume >= 33 ? "󰖀" : "󰕿"
                        return icon + " " + bar.volume + "%"
                    }
                    textColor: bar.muted ? bar.subtextColor : bar.accent
                    fontFamily: bar.fontFamily; fontSize: bar.fontSize
                    onClicked: {
                        pavuProc.running = true
                        volumeProc.running = true
                    }
                }

                // Bluetooth
                BarModule {
                    text: " " + bar.btStatus
                    textColor: bar.btStatus === "off" ? bar.subtextColor : bar.accent
                    fontFamily: bar.fontFamily; fontSize: bar.fontSize
                    onClicked: {
                        btManProc.running = true
                        btProc.running = true
                    }
                }

                // Network
                BarModule {
                    text: bar.netIcon + (bar.netSignal > 0 ? bar.netSignal + "%" : bar.netText)
                    textColor: bar.netText === "disconnected" ? bar.subtextColor : bar.accent
                    fontFamily: bar.fontFamily; fontSize: bar.fontSize
                    onClicked: nmEditorProc.running = true
                }

                // Battery
                BarModule {
                    text: bar.batIcon + " " + bar.batCapacity + "%"
                    textColor: {
                        if (bar.batCapacity <= 10 && bar.batStatus !== "Charging") return "#f38ba8"
                        if (bar.batCapacity <= 30 && bar.batStatus !== "Charging") return "#f9e2af"
                        return bar.accent
                    }
                    fontFamily: bar.fontFamily; fontSize: bar.fontSize
                    warningPulse: bar.batCapacity <= 10 && bar.batStatus !== "Charging"
                }

                Rectangle { width: 1; Layout.fillHeight: true; Layout.margins: 8; color: Qt.rgba(1,1,1,0.08) }

                // Quick Settings
                BarModule {
                    text: "󱍐"
                    textColor: bar.panelVisible ? "#1e1e2e" : bar.accent
                    bgOverride: bar.panelVisible ? bar.accent : "transparent"
                    fontFamily: bar.fontFamily; fontSize: 16
                    onClicked: bar.togglePanel()
                }

                // Exit
                BarModule {
                    text: ""
                    textColor: bar.accent
                    fontFamily: bar.fontFamily; fontSize: 16
                    rightPad: true
                    onClicked: wlogoutProc.running = true
                }
            }
        }
}
