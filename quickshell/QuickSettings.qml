import QtQuick
import QtQuick.Layouts
import Quickshell.Io

Rectangle {
    id: panel

    implicitHeight: mainLayout.implicitHeight + 32
    radius: 14
    clip: true
    color: Qt.rgba(17/255, 17/255, 27/255, 0.75)
    border.color: Qt.rgba(176/255, 196/255, 239/255, 0.15)
    border.width: 1

    // ── State ──
    property int volume: 50
    property bool muted: false
    property int brightness: 50
    property bool wifiOn: true
    property string wifiName: "..."
    property bool btOn: false

    property bool wifiExpanded: false
    property bool btExpanded: false
    property var wifiNetworks: []
    property var btDevices: []
    property string selectedSsid: ""
    property string wifiPassword: ""
    property string connectingStatus: ""
    property string btConnectingMac: ""
    property bool dragging: volumeSlider.pressed || brightnessSlider.pressed

    // Audio device selection
    property var audioSinks: []
    property var audioSources: []
    property string currentSinkName: "..."
    property string currentSourceName: "..."
    property bool sinkExpanded: false
    property bool sourceExpanded: false

    // ── Refresh ──
    function refresh() {
        volumeProc.running = true
        brightnessProc.running = true
        wifiProc.running = true
        btStatusProc.running = true
        audioDevicesProc.running = true
    }

    Component.onCompleted: refresh()

    Timer {
        interval: 3000
        running: !panel.dragging
        repeat: true
        onTriggered: panel.refresh()
    }

    // ════════════════════════════════
    // Processes — status polling
    // ════════════════════════════════

    Process {
        id: volumeProc
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (panel.dragging) return
                let txt = this.text.trim()
                let parts = txt.split(" ")
                if (parts.length >= 2)
                    panel.volume = Math.round(parseFloat(parts[1]) * 100)
                panel.muted = txt.includes("[MUTED]")
            }
        }
    }

    Process {
        id: brightnessProc
        command: ["brightnessctl", "-m"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (panel.dragging) return
                let parts = this.text.trim().split(",")
                if (parts.length >= 4)
                    panel.brightness = parseInt(parts[3].replace("%", ""))
            }
        }
    }

    Process {
        id: audioDevicesProc
        property string buf: ""
        command: ["sh", "-c", "echo '=SINKS='; pw-dump 2>/dev/null | python3 -c \"import json,sys;data=json.load(sys.stdin);[print(str(n['id'])+'|'+n.get('info',{}).get('props',{}).get('node.description',n.get('info',{}).get('props',{}).get('node.name',''))) for n in data if n.get('info',{}).get('props',{}).get('media.class','')=='Audio/Sink']\"; echo '=SOURCES='; pw-dump 2>/dev/null | python3 -c \"import json,sys;data=json.load(sys.stdin);[print(str(n['id'])+'|'+n.get('info',{}).get('props',{}).get('node.description',n.get('info',{}).get('props',{}).get('node.name',''))) for n in data if n.get('info',{}).get('props',{}).get('media.class','')=='Audio/Source']\"; echo '=DEFSINK='; wpctl inspect @DEFAULT_AUDIO_SINK@ 2>/dev/null | grep 'node.description' | head -1 | sed 's/.*= \"//;s/\"//' ; echo '=DEFSOURCE='; wpctl inspect @DEFAULT_AUDIO_SOURCE@ 2>/dev/null | grep 'node.description' | head -1 | sed 's/.*= \"//;s/\"//'"]
        stdout: SplitParser {
            onRead: data => { audioDevicesProc.buf += data + "\n" }
        }
        onExited: {
            var lines = audioDevicesProc.buf.trim().split("\n")
            var sinks = []
            var sources = []
            var mode = ""
            for (var i = 0; i < lines.length; i++) {
                var line = lines[i].trim()
                if (line === "=SINKS=") { mode = "sinks"; continue }
                if (line === "=SOURCES=") { mode = "sources"; continue }
                if (line === "=DEFSINK=") { mode = "defsink"; continue }
                if (line === "=DEFSOURCE=") { mode = "defsource"; continue }
                if (mode === "sinks" && line.indexOf("|") > 0) {
                    var p = line.split("|")
                    sinks.push({ id: p[0], name: p[1] })
                } else if (mode === "sources" && line.indexOf("|") > 0) {
                    var p2 = line.split("|")
                    sources.push({ id: p2[0], name: p2[1] })
                } else if (mode === "defsink" && line.length > 0) {
                    panel.currentSinkName = line
                } else if (mode === "defsource" && line.length > 0) {
                    panel.currentSourceName = line
                }
            }
            panel.audioSinks = sinks
            panel.audioSources = sources
            audioDevicesProc.buf = ""
        }
    }

    Process {
        id: setSinkProc
        command: ["sh", "-c", "true"]
        onExited: { audioDevicesProc.running = true; volumeProc.running = true }
    }

    Process {
        id: setSourceProc
        command: ["sh", "-c", "true"]
        onExited: { audioDevicesProc.running = true }
    }

    Process {
        id: wifiProc
        command: ["nmcli", "-t", "-f", "WIFI", "general"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                panel.wifiOn = (this.text.trim() === "enabled")
                if (panel.wifiOn) wifiNameProc.running = true
            }
        }
    }

    Process {
        id: wifiNameProc
        command: ["nmcli", "-t", "-f", "active,ssid", "dev", "wifi"]
        stdout: StdioCollector {
            onStreamFinished: {
                let lines = this.text.trim().split("\n")
                for (let line of lines) {
                    if (line.startsWith("yes:")) {
                        panel.wifiName = line.substring(4)
                        return
                    }
                }
                panel.wifiName = "Not connected"
            }
        }
    }

    Process {
        id: btStatusProc
        command: ["busctl", "get-property", "org.bluez", "/org/bluez/hci0", "org.bluez.Adapter1", "Powered"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                panel.btOn = this.text.trim() === "b true"
            }
        }
    }

    // ════════════════════════════════
    // Processes — WiFi scan & connect
    // ════════════════════════════════

    Process {
        id: wifiScanProc
        command: ["nmcli", "-t", "-f", "IN-USE,SSID,SIGNAL,SECURITY", "dev", "wifi", "list", "--rescan", "yes"]
        stdout: StdioCollector {
            onStreamFinished: {
                let lines = this.text.trim().split("\n")
                let networks = []
                let seen = {}
                for (let line of lines) {
                    let inUse = line.startsWith("*:")
                    let rest = inUse ? line.substring(2) : line.substring(1)
                    if (rest.startsWith(":")) rest = rest.substring(1)
                    let match = rest.match(/^(.+):(\d+):(.*)$/)
                    if (match && match[1] && !seen[match[1]]) {
                        seen[match[1]] = true
                        networks.push({
                            ssid: match[1],
                            signal: parseInt(match[2]),
                            security: match[3] || "",
                            connected: inUse
                        })
                    }
                }
                networks.sort((a, b) => {
                    if (a.connected !== b.connected) return a.connected ? -1 : 1
                    return b.signal - a.signal
                })
                panel.wifiNetworks = networks.slice(0, 12)
            }
        }
    }

    property var wifiConnectCmd: ["echo"]
    Process {
        id: wifiConnectProc
        command: panel.wifiConnectCmd
        stdout: StdioCollector {
            onStreamFinished: {
                let txt = this.text.trim()
                if (txt.includes("successfully")) {
                    panel.connectingStatus = "Connected!"
                    panel.selectedSsid = ""
                    panel.wifiPassword = ""
                    panel.refresh()
                } else if (txt) {
                    panel.connectingStatus = txt.includes("Secrets") ? "Wrong password" : "Failed"
                }
            }
        }
    }

    Process { id: wifiToggleProc; command: ["nmcli", "radio", "wifi", panel.wifiOn ? "off" : "on"] }

    // ════════════════════════════════
    // Processes — Bluetooth scan & connect
    // ════════════════════════════════

    Process {
        id: btScanProc
        command: ["bash", "-c", "for dev in $(busctl tree org.bluez 2>/dev/null | grep -oP '/org/bluez/hci0/dev_[^ ]+' | grep -vE 'sep|fd'); do name=$(busctl get-property org.bluez \"$dev\" org.bluez.Device1 Name 2>/dev/null | sed 's/^s \"//' | sed 's/\"$//'); conn=$(busctl get-property org.bluez \"$dev\" org.bluez.Device1 Connected 2>/dev/null); mac=$(echo \"$dev\" | grep -oP 'dev_\\K.*' | tr '_' ':'); echo \"$mac|$name|$conn\"; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                let lines = this.text.trim().split("\n")
                let devices = []
                for (let line of lines) {
                    let parts = line.split("|")
                    if (parts.length >= 3 && parts[0]) {
                        devices.push({
                            mac: parts[0],
                            name: parts[1] || parts[0],
                            connected: parts[2].trim() === "b true"
                        })
                    }
                }
                panel.btDevices = devices.slice(0, 10)
            }
        }
    }

    Process {
        id: btListProc
        command: ["bash", "-c", "for dev in $(busctl tree org.bluez 2>/dev/null | grep -oP '/org/bluez/hci0/dev_[^ ]+' | grep -vE 'sep|fd'); do name=$(busctl get-property org.bluez \"$dev\" org.bluez.Device1 Name 2>/dev/null | sed 's/^s \"//' | sed 's/\"$//'); conn=$(busctl get-property org.bluez \"$dev\" org.bluez.Device1 Connected 2>/dev/null); mac=$(echo \"$dev\" | grep -oP 'dev_\\K.*' | tr '_' ':'); echo \"$mac|$name|$conn\"; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                let lines = this.text.trim().split("\n")
                let devices = []
                for (let line of lines) {
                    let parts = line.split("|")
                    if (parts.length >= 3 && parts[0]) {
                        devices.push({
                            mac: parts[0],
                            name: parts[1] || parts[0],
                            connected: parts[2].trim() === "b true"
                        })
                    }
                }
                panel.btDevices = devices.slice(0, 10)
            }
        }
    }

    property string btConnectMac: ""
    Process {
        id: btConnectProc
        command: ["busctl", "call", "org.bluez",
            "/org/bluez/hci0/dev_" + panel.btConnectMac.replace(/:/g, "_"),
            "org.bluez.Device1", "Connect"]
        stdout: StdioCollector {
            onStreamFinished: {
                panel.btConnectingMac = ""
                btListProc.running = true
            }
        }
    }

    Process { id: btToggleProc; command: ["busctl", "set-property", "org.bluez", "/org/bluez/hci0", "org.bluez.Adapter1", "Powered", "b", panel.btOn ? "false" : "true"] }
    Process { id: bluemanProc; command: ["blueman-manager"] }

    // ════════════════════════════════
    // Processes — volume & brightness set
    // ════════════════════════════════

    Process {
        id: volSetProc
        command: ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", (panel.volume / 100).toFixed(2)]
    }
    Process { id: muteProc; command: ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"] }
    Timer { id: volDebounce; interval: 50; onTriggered: volSetProc.running = true }

    Process {
        id: brightSetProc
        command: ["brightnessctl", "set", panel.brightness + "%"]
    }
    Timer { id: brightDebounce; interval: 50; onTriggered: brightSetProc.running = true }

    // ════════════════════════════════
    // UI
    // ════════════════════════════════

    ColumnLayout {
        id: mainLayout
        anchors {
            fill: parent
            margins: 16
        }
        spacing: 14

        Text {
            text: "Quick Settings"
            color: "#b0c4ef"
            font { family: "Victor Mono SemiBold"; pixelSize: 15 }
            font.bold: true
            Layout.fillWidth: true
            opacity: 0.8
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Qt.rgba(176/255, 196/255, 239/255, 0.12)
        }

        // ══════ WiFi Section ══════
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                ToggleButton {
                    icon: panel.wifiOn ? "󰤨" : "󰤭"
                    active: panel.wifiOn
                    onClicked: {
                        wifiToggleProc.running = true
                        panel.wifiOn = !panel.wifiOn
                        panel.wifiExpanded = false
                    }
                }

                ColumnLayout {
                    spacing: 2
                    Layout.fillWidth: true

                    Text {
                        text: "Wi-Fi"
                        color: "#cdd6f4"
                        font { family: "Victor Mono SemiBold"; pixelSize: 15 }
                        font.bold: true
                    }
                    Text {
                        text: panel.wifiOn ? panel.wifiName : "Disabled"
                        color: "#a6adc8"
                        font { family: "Victor Mono SemiBold"; pixelSize: 15 }
                    }
                }

                Text {
                    text: panel.wifiExpanded ? "󰅃" : "󰅀"
                    color: "#a6adc8"
                    font { family: "Victor Mono SemiBold"; pixelSize: 14 }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            panel.wifiExpanded = !panel.wifiExpanded
                            if (panel.wifiExpanded && panel.wifiOn)
                                wifiScanProc.running = true
                        }
                    }
                }
            }

            // WiFi network list
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                clip: true
                Layout.preferredHeight: (panel.wifiExpanded && panel.wifiOn) ? implicitHeight : 0
                Behavior on Layout.preferredHeight { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                opacity: (panel.wifiExpanded && panel.wifiOn) ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 200 } }

                Repeater {
                    model: panel.wifiNetworks

                    ColumnLayout {
                        required property var modelData
                        required property int index
                        Layout.fillWidth: true
                        spacing: 4

                        Rectangle {
                            Layout.fillWidth: true
                            height: 36
                            radius: 8
                            color: modelData.connected
                                ? Qt.rgba(176/255, 196/255, 239/255, 0.15)
                                : (panel.selectedSsid === modelData.ssid
                                    ? Qt.rgba(176/255, 196/255, 239/255, 0.12)
                                    : (wifiItemMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.04) : "transparent"))

                            Behavior on color { ColorAnimation { duration: 150; easing.type: Easing.OutCubic } }

                            MouseArea {
                                id: wifiItemMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (panel.selectedSsid === modelData.ssid) {
                                        panel.selectedSsid = ""
                                    } else {
                                        panel.selectedSsid = modelData.ssid
                                        panel.wifiPassword = ""
                                        panel.connectingStatus = ""
                                        if (!modelData.security) {
                                            panel.connectingStatus = "Connecting..."
                                            panel.wifiConnectCmd = ["bash", "-c",
                                                "nmcli dev wifi connect \"$1\" 2>&1",
                                                "_", modelData.ssid]
                                            wifiConnectProc.running = true
                                        }
                                    }
                                }
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 8

                                Text {
                                    text: modelData.ssid
                                    color: modelData.connected ? "#b0c4ef" : "#cdd6f4"
                                    font { family: "Victor Mono SemiBold"; pixelSize: 14 }
                                    font.bold: modelData.connected
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }

                                Text {
                                    text: "Connected"
                                    color: "#6DA1B9"
                                    font { family: "Victor Mono SemiBold"; pixelSize: 15 }
                                    visible: modelData.connected
                                }

                                Text {
                                    text: modelData.signal + "%"
                                    color: modelData.connected ? "#b0c4ef" : "#a6adc8"
                                    font { family: "Victor Mono SemiBold"; pixelSize: 15 }
                                }

                                Text {
                                    text: modelData.security ? "󰌾" : ""
                                    color: "#a6adc8"
                                    font { family: "Victor Mono SemiBold"; pixelSize: 14 }
                                    visible: text !== ""
                                }
                            }
                        }

                        // Password row for secured networks
                        RowLayout {
                            Layout.fillWidth: true
                            Layout.leftMargin: 12
                            Layout.rightMargin: 12
                            spacing: 8
                            visible: panel.selectedSsid === modelData.ssid && modelData.security !== ""

                            Rectangle {
                                Layout.fillWidth: true
                                height: 32
                                radius: 6
                                color: Qt.rgba(255, 255, 255, 0.06)
                                border.color: Qt.rgba(176/255, 196/255, 239/255, 0.2)
                                border.width: 1

                                TextInput {
                                    id: passInput
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 8
                                    verticalAlignment: TextInput.AlignVCenter
                                    color: "#cdd6f4"
                                    font { family: "Victor Mono SemiBold"; pixelSize: 14 }
                                    echoMode: TextInput.Password
                                    clip: true
                                    onTextChanged: panel.wifiPassword = text

                                    Text {
                                        anchors.fill: parent
                                        anchors.leftMargin: 0
                                        verticalAlignment: Text.AlignVCenter
                                        text: "Password..."
                                        color: "#6c7086"
                                        font { family: "Victor Mono SemiBold"; pixelSize: 14 }
                                        visible: !passInput.text && !passInput.activeFocus
                                    }
                                }
                            }

                            Rectangle {
                                width: 76
                                height: 32
                                radius: 6
                                color: panel.connectingStatus === "Connecting..."
                                    ? "#585b70" : (connectMa.containsMouse ? "#87B9D1" : "#6DA1B9")
                                Behavior on color { ColorAnimation { duration: 150 } }

                                Text {
                                    anchors.centerIn: parent
                                    text: panel.connectingStatus || "Connect"
                                    color: "#FFFFFF"
                                    font { family: "Victor Mono SemiBold"; pixelSize: 15 }
                                    font.bold: true
                                }

                                MouseArea {
                                    id: connectMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (panel.wifiPassword && !panel.connectingStatus) {
                                            panel.connectingStatus = "Connecting..."
                                            panel.wifiConnectCmd = ["bash", "-c",
                                                "nmcli dev wifi connect \"$1\" password \"$2\" 2>&1",
                                                "_", modelData.ssid, panel.wifiPassword]
                                            wifiConnectProc.running = true
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // Rescan button
                Rectangle {
                    Layout.fillWidth: true
                    height: 28
                    radius: 6
                    color: rescanMa.containsMouse ? Qt.rgba(255, 255, 255, 0.08) : Qt.rgba(255, 255, 255, 0.04)
                    visible: !wifiScanProc.running
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Text {
                        anchors.centerIn: parent
                        text: "Rescan"
                        color: rescanMa.containsMouse ? "#cdd6f4" : "#a6adc8"
                        font { family: "Victor Mono SemiBold"; pixelSize: 15 }
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    MouseArea {
                        id: rescanMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: wifiScanProc.running = true
                    }
                }
            }
        }

        // ══════ Bluetooth Section ══════
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                ToggleButton {
                    icon: panel.btOn ? "󰂯" : "󰂲"
                    active: panel.btOn
                    onClicked: {
                        btToggleProc.running = true
                        panel.btOn = !panel.btOn
                        panel.btExpanded = false
                    }
                }

                ColumnLayout {
                    spacing: 2
                    Layout.fillWidth: true

                    Text {
                        text: "Bluetooth"
                        color: "#cdd6f4"
                        font { family: "Victor Mono SemiBold"; pixelSize: 15 }
                        font.bold: true
                    }
                    Text {
                        text: panel.btOn ? "On" : "Off"
                        color: "#a6adc8"
                        font { family: "Victor Mono SemiBold"; pixelSize: 15 }
                    }
                }

                Text {
                    text: panel.btExpanded ? "󰅃" : "󰅀"
                    color: "#a6adc8"
                    font { family: "Victor Mono SemiBold"; pixelSize: 14 }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            panel.btExpanded = !panel.btExpanded
                            if (panel.btExpanded && panel.btOn) {
                                btListProc.running = true
                                btScanProc.running = true
                            }
                        }
                    }
                }
            }

            // Bluetooth device list
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                clip: true
                Layout.preferredHeight: (panel.btExpanded && panel.btOn) ? implicitHeight : 0
                Behavior on Layout.preferredHeight { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                opacity: (panel.btExpanded && panel.btOn) ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 200 } }

                Repeater {
                    model: panel.btDevices

                    Rectangle {
                        required property var modelData
                        Layout.fillWidth: true
                        height: 36
                        radius: 8
                        color: btItemMouse.containsMouse
                            ? Qt.rgba(255, 255, 255, 0.04) : "transparent"

                        Behavior on color { ColorAnimation { duration: 150; easing.type: Easing.OutCubic } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 8

                            Text {
                                text: "󰂯"
                                color: modelData.connected ? "#b0c4ef" : "#585b70"
                                font { family: "Victor Mono SemiBold"; pixelSize: 14 }
                            }

                            Text {
                                text: modelData.name
                                color: modelData.connected ? "#cdd6f4" : "#a6adc8"
                                font { family: "Victor Mono SemiBold"; pixelSize: 14 }
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }

                            Text {
                                text: modelData.connected ? "Connected" :
                                    (panel.btConnectingMac === modelData.mac ? "Connecting..." : "")
                                color: modelData.connected ? "#6DA1B9" : "#a6adc8"
                                font { family: "Victor Mono SemiBold"; pixelSize: 14 }
                                visible: text !== ""
                            }
                        }

                        MouseArea {
                            id: btItemMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                panel.btConnectMac = modelData.mac
                                panel.btConnectingMac = modelData.mac
                                btConnectProc.running = true
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Rectangle {
                        Layout.fillWidth: true
                        height: 28
                        radius: 6
                        color: bluemanMa.containsMouse ? Qt.rgba(255, 255, 255, 0.08) : Qt.rgba(255, 255, 255, 0.04)
                        Behavior on color { ColorAnimation { duration: 150 } }

                        Text {
                            anchors.centerIn: parent
                            text: "Open Blueman"
                            color: bluemanMa.containsMouse ? "#cdd6f4" : "#a6adc8"
                            font { family: "Victor Mono SemiBold"; pixelSize: 15 }
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        MouseArea {
                            id: bluemanMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: bluemanProc.running = true
                        }
                    }

                    Rectangle {
                        width: 28
                        height: 28
                        radius: 6
                        color: btRefreshMa.containsMouse ? Qt.rgba(255, 255, 255, 0.08) : Qt.rgba(255, 255, 255, 0.04)
                        Behavior on color { ColorAnimation { duration: 150 } }

                        Text {
                            anchors.centerIn: parent
                            text: "󰑐"
                            color: btRefreshMa.containsMouse ? "#cdd6f4" : "#a6adc8"
                            font { family: "Victor Mono SemiBold"; pixelSize: 14 }
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        MouseArea {
                            id: btRefreshMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: btListProc.running = true
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Qt.rgba(176/255, 196/255, 239/255, 0.12)
        }

        // ══════ Volume ══════
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6

            RowLayout {
                spacing: 8

                Text {
                    text: panel.muted ? "󰖁" : (panel.volume > 50 ? "󰕾" : "󰖀")
                    color: panel.muted ? "#a6adc8" : "#b0c4ef"
                    font { family: "Victor Mono SemiBold"; pixelSize: 14 }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            muteProc.running = true
                            panel.muted = !panel.muted
                        }
                    }
                }

                Text {
                    text: "Volume"
                    color: "#cdd6f4"
                    font { family: "Victor Mono SemiBold"; pixelSize: 15 }
                    font.bold: true
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: panel.volume + "%"
                    color: "#a6adc8"
                    font { family: "Victor Mono SemiBold"; pixelSize: 14 }
                }
            }

            SliderBar {
                id: volumeSlider
                Layout.fillWidth: true
                value: panel.volume / 100
                accentColor: panel.muted ? "#a6adc8" : "#b0c4ef"
                onValueSet: newValue => {
                    panel.volume = Math.round(newValue * 100)
                    volDebounce.restart()
                }
            }

            // Output device selector
            Rectangle {
                Layout.fillWidth: true
                height: 28
                radius: 6
                color: sinkBtnMa.containsMouse ? Qt.rgba(1,1,1,0.08) : Qt.rgba(1,1,1,0.04)
                Behavior on color { ColorAnimation { duration: 150 } }

                MouseArea {
                    id: sinkBtnMa
                    anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: { panel.sinkExpanded = !panel.sinkExpanded; panel.sourceExpanded = false }
                }

                RowLayout {
                    anchors { fill: parent; leftMargin: 8; rightMargin: 8 }
                    Text { text: "󰓃"; color: "#C0E2F3"; font { family: "Victor Mono SemiBold"; pixelSize: 14 } }
                    Text { text: "Output"; color: "#a6adc8"; font { family: "Victor Mono SemiBold"; pixelSize: 14 } }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: panel.currentSinkName
                        color: "#cdd6f4"
                        font { family: "Victor Mono SemiBold"; pixelSize: 14 }
                        elide: Text.ElideRight
                        Layout.maximumWidth: 180
                    }
                    Text {
                        text: panel.sinkExpanded ? "󰅀" : "󰅂"
                        color: "#6c7086"
                        font { family: "Victor Mono SemiBold"; pixelSize: 15 }
                    }
                }
            }

            // Sink list
            ColumnLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 8
                spacing: 3
                clip: true
                Layout.preferredHeight: panel.sinkExpanded ? implicitHeight : 0
                Behavior on Layout.preferredHeight { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                opacity: panel.sinkExpanded ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 200 } }

                Repeater {
                    model: panel.sinkExpanded ? panel.audioSinks.length : 0
                    delegate: Rectangle {
                        Layout.fillWidth: true
                        height: 30
                        radius: 6
                        property var sink: panel.audioSinks[index]
                        property bool isActive: sink.name === panel.currentSinkName
                        color: isActive ? Qt.rgba(192/255, 226/255, 243/255, 0.12) :
                               sinkItemMa.containsMouse ? Qt.rgba(1,1,1,0.08) : Qt.rgba(1,1,1,0.03)
                        border.color: isActive ? Qt.rgba(192/255, 226/255, 243/255, 0.3) : "transparent"
                        border.width: 1
                        Behavior on color { ColorAnimation { duration: 150 } }

                        MouseArea {
                            id: sinkItemMa
                            anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                setSinkProc.command = ["wpctl", "set-default", parent.sink.id]
                                setSinkProc.running = true
                                panel.sinkExpanded = false
                            }
                        }

                        RowLayout {
                            anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                            Text {
                                text: parent.parent.isActive ? "󰄬" : "󰓃"
                                color: parent.parent.isActive ? "#a6e3a1" : "#585b70"
                                font { family: "Victor Mono SemiBold"; pixelSize: 14 }
                            }
                            Text {
                                text: parent.parent.sink.name
                                color: parent.parent.isActive ? "#cdd6f4" : "#a6adc8"
                                font { family: "Victor Mono SemiBold"; pixelSize: 14; bold: parent.parent.isActive }
                            }
                        }
                    }
                }
            }

            // Input device selector
            Rectangle {
                Layout.fillWidth: true
                height: 28
                radius: 6
                color: srcBtnMa.containsMouse ? Qt.rgba(1,1,1,0.08) : Qt.rgba(1,1,1,0.04)
                Behavior on color { ColorAnimation { duration: 150 } }

                MouseArea {
                    id: srcBtnMa
                    anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: { panel.sourceExpanded = !panel.sourceExpanded; panel.sinkExpanded = false }
                }

                RowLayout {
                    anchors { fill: parent; leftMargin: 8; rightMargin: 8 }
                    Text { text: "󰍬"; color: "#C0E2F3"; font { family: "Victor Mono SemiBold"; pixelSize: 14 } }
                    Text { text: "Input"; color: "#a6adc8"; font { family: "Victor Mono SemiBold"; pixelSize: 14 } }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: panel.currentSourceName
                        color: "#cdd6f4"
                        font { family: "Victor Mono SemiBold"; pixelSize: 14 }
                        elide: Text.ElideRight
                        Layout.maximumWidth: 180
                    }
                    Text {
                        text: panel.sourceExpanded ? "󰅀" : "󰅂"
                        color: "#6c7086"
                        font { family: "Victor Mono SemiBold"; pixelSize: 15 }
                    }
                }
            }

            // Source list
            ColumnLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 8
                spacing: 3
                clip: true
                Layout.preferredHeight: panel.sourceExpanded ? implicitHeight : 0
                Behavior on Layout.preferredHeight { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                opacity: panel.sourceExpanded ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 200 } }

                Repeater {
                    model: panel.sourceExpanded ? panel.audioSources.length : 0
                    delegate: Rectangle {
                        Layout.fillWidth: true
                        height: 30
                        radius: 6
                        property var src: panel.audioSources[index]
                        property bool isActive: src.name === panel.currentSourceName
                        color: isActive ? Qt.rgba(192/255, 226/255, 243/255, 0.12) :
                               srcItemMa.containsMouse ? Qt.rgba(1,1,1,0.08) : Qt.rgba(1,1,1,0.03)
                        border.color: isActive ? Qt.rgba(192/255, 226/255, 243/255, 0.3) : "transparent"
                        border.width: 1
                        Behavior on color { ColorAnimation { duration: 150 } }

                        MouseArea {
                            id: srcItemMa
                            anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                setSourceProc.command = ["wpctl", "set-default", parent.src.id]
                                setSourceProc.running = true
                                panel.sourceExpanded = false
                            }
                        }

                        RowLayout {
                            anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                            Text {
                                text: parent.parent.isActive ? "󰄬" : "󰍬"
                                color: parent.parent.isActive ? "#a6e3a1" : "#585b70"
                                font { family: "Victor Mono SemiBold"; pixelSize: 14 }
                            }
                            Text {
                                text: parent.parent.src.name
                                color: parent.parent.isActive ? "#cdd6f4" : "#a6adc8"
                                font { family: "Victor Mono SemiBold"; pixelSize: 14; bold: parent.parent.isActive }
                            }
                        }
                    }
                }
            }
        }

        // ══════ Brightness ══════
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6

            RowLayout {
                spacing: 8

                Text {
                    text: panel.brightness > 50 ? "󰃠" : "󰃞"
                    color: "#b0c4ef"
                    font { family: "Victor Mono SemiBold"; pixelSize: 14 }
                }

                Text {
                    text: "Brightness"
                    color: "#cdd6f4"
                    font { family: "Victor Mono SemiBold"; pixelSize: 15 }
                    font.bold: true
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: panel.brightness + "%"
                    color: "#a6adc8"
                    font { family: "Victor Mono SemiBold"; pixelSize: 14 }
                }
            }

            SliderBar {
                id: brightnessSlider
                Layout.fillWidth: true
                value: panel.brightness / 100
                accentColor: "#b0c4ef"
                onValueSet: newValue => {
                    panel.brightness = Math.round(newValue * 100)
                    brightDebounce.restart()
                }
            }
        }
    }
}
