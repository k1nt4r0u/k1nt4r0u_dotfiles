import QtQuick
import QtQuick.Layouts
import Quickshell.Io

Rectangle {
    id: media

    implicitHeight: mediaLayout.implicitHeight + 28
    radius: 14
    color: Qt.rgba(17/255, 17/255, 27/255, 0.75)
    border.color: Qt.rgba(176/255, 196/255, 239/255, 0.15)
    border.width: 1

    Behavior on implicitHeight { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

    // ── State ──
    property string title: ""
    property string artist: ""
    property string source: ""     // "mpd" or "mpris:player"
    property string status: "Stopped" // Playing, Paused, Stopped
    property string artPath: ""
    property string artCacheBust: ""
    property real progress: 0      // 0-1
    property int durationSecs: 0
    property string positionText: "0:00"
    property string durationText: "0:00"

    // ── Refresh metadata ──
    function refresh() {
        metadataProc.running = true
    }

    Component.onCompleted: refresh()

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: media.refresh()
    }

    // ── Metadata process — reuses waybar state file logic ──
    Process {
        id: metadataProc
        command: ["/home/kintarou/.config/quickshell/scripts/media-metadata.sh"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                let lines = this.text.trim().split("\n")
                for (let line of lines) {
                    let idx = line.indexOf(":")
                    if (idx < 0) continue
                    let key = line.substring(0, idx)
                    let val = line.substring(idx + 1)
                    switch (key) {
                        case "source":   media.source = val; break
                        case "title":    media.title = val; break
                        case "artist":   media.artist = val; break
                        case "status":   media.status = val; break
                        case "position": media.positionText = val; break
                        case "duration": media.durationText = val; break
                        case "progress": media.progress = parseInt(val) / 100; break
                        case "duration_secs": media.durationSecs = parseInt(val) || 0; break
                        case "art":
                            if (val) {
                                media.artCacheBust = Date.now().toString()
                                media.artPath = "file://" + val
                            } else {
                                media.artPath = ""
                            }
                            break
                    }
                }
            }
        }
    }

    // ── Action processes ──
    Process { id: playPauseProc; command: ["/home/kintarou/.config/waybar/scripts/player.sh"] }
    Process { id: nextProc;      command: ["/home/kintarou/.config/waybar/scripts/player-next.sh"] }
    Process { id: prevProc;      command: ["/home/kintarou/.config/waybar/scripts/player-prev.sh"] }

    property int seekTarget: 0
    Process {
        id: seekProc
        command: media.source === "mpd"
            ? ["mpc", "seek", String(media.seekTarget)]
            : ["playerctl", "-p", media.source.replace("mpris:", ""), "position", String(media.seekTarget)]
    }
    Timer { id: seekDebounce; interval: 100; onTriggered: seekProc.running = true }

    // ── UI ──
    ColumnLayout {
        id: mediaLayout
        anchors {
            fill: parent
            margins: 16
        }
        spacing: 16

        // Row 1: Cover | Info
        RowLayout {
            Layout.fillWidth: true
            spacing: 16

            // Album art
            Rectangle {
                width: 64
                height: 64
                radius: 12
                color: Qt.rgba(255, 255, 255, 0.06)
                clip: true

                Image {
                    id: albumArt
                    anchors.fill: parent
                    source: media.artPath ? media.artPath + "?t=" + media.artCacheBust : ""
                    fillMode: Image.PreserveAspectCrop
                    opacity: status === Image.Ready ? 1.0 : 0.0
                    visible: opacity > 0
                    cache: false

                    Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                }

                // Fallback icon when no art
                Text {
                    anchors.centerIn: parent
                    text: "󰎈"
                    color: "#585b70"
                    font { family: "Victor Mono SemiBold"; pixelSize: 24 }
                    visible: albumArt.status !== Image.Ready
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                
                Text {
                    Layout.fillWidth: true
                    text: media.title || "No music playing"
                    color: media.status === "Stopped" ? "#585b70" : "#cdd6f4"
                    font { family: "Victor Mono SemiBold"; pixelSize: 16; bold: true }
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }

                Text {
                    Layout.fillWidth: true
                    text: media.artist || "Unknown Artist"
                    color: "#a6adc8"
                    font { family: "Victor Mono SemiBold"; pixelSize: 14 }
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    visible: media.status !== "Stopped"
                }
            }
        }

        // Row 2: Controls
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 24

            // Previous
            Text {
                text: "󰒮"
                color: media.status === "Stopped" ? "#585b70" : (prevMouse.containsMouse ? "#cdd6f4" : "#b0c4ef")
                font { family: "Victor Mono SemiBold"; pixelSize: 22 }
                opacity: prevMouse.containsMouse ? 1.0 : 0.8
                scale: prevMouse.containsMouse ? 1.15 : 1.0
                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on opacity { NumberAnimation { duration: 150 } }
                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
                MouseArea {
                    id: prevMouse
                    anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: prevProc.running = true
                }
            }

            // Play/Pause
            Rectangle {
                id: ppBtn
                width: 40
                height: 40
                radius: 20
                color: media.status === "Stopped" ? Qt.rgba(255,255,255,0.04) : (ppMouse.containsMouse ? Qt.rgba(176/255, 196/255, 239/255, 0.25) : Qt.rgba(176/255, 196/255, 239/255, 0.15))
                scale: ppMouse.containsMouse ? 1.1 : 1.0
                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
                
                Text {
                    anchors.centerIn: parent
                    text: media.status === "Playing" ? "󰏤" : "󰐊"
                    color: media.status === "Stopped" ? "#585b70" : (ppMouse.containsMouse ? "#cdd6f4" : "#b0c4ef")
                    font { family: "Victor Mono SemiBold"; pixelSize: 20 }
                    Behavior on color { ColorAnimation { duration: 150 } }
                }
                MouseArea {
                    id: ppMouse
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: playPauseProc.running = true
                }
            }

            // Next
            Text {
                text: "󰒭"
                color: media.status === "Stopped" ? "#585b70" : (nextMouse.containsMouse ? "#cdd6f4" : "#b0c4ef")
                font { family: "Victor Mono SemiBold"; pixelSize: 22 }
                opacity: nextMouse.containsMouse ? 1.0 : 0.8
                scale: nextMouse.containsMouse ? 1.15 : 1.0
                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on opacity { NumberAnimation { duration: 150 } }
                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
                MouseArea {
                    id: nextMouse
                    anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: nextProc.running = true
                }
            }
        }

        // Row 3: Progress Bar
        Item {
            Layout.fillWidth: true
            height: 6
            
            Rectangle {
                anchors.fill: parent
                radius: 3
                color: progressMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.1) : Qt.rgba(255, 255, 255, 0.06)
                Behavior on color { ColorAnimation { duration: 150 } }

                Rectangle {
                    width: Math.max(0, Math.min(1, media.progress)) * parent.width
                    height: parent.height
                    radius: 3
                    color: media.status === "Stopped" ? "#585b70" : (progressMouse.containsMouse ? "#cdd6f4" : "#b0c4ef")
                    Behavior on color { ColorAnimation { duration: 150 } }
                }
            }

            MouseArea {
                id: progressMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: media.status !== "Stopped" ? Qt.PointingHandCursor : Qt.ArrowCursor
                enabled: media.status !== "Stopped" && media.durationSecs > 0

                function seek(mouseX: real) {
                    let pct = Math.max(0, Math.min(1, mouseX / width))
                    media.progress = pct
                    media.seekTarget = Math.round(pct * media.durationSecs)
                    let m = Math.floor(media.seekTarget / 60)
                    let s = media.seekTarget % 60
                    media.positionText = m + ":" + String(s).padStart(2, "0")
                    seekDebounce.restart()
                }

                onPressed: mouse => seek(mouse.x)
                onPositionChanged: mouse => { if (pressed) seek(mouse.x) }
            }
        }

        // Row 4: Time indicators
        RowLayout {
            Layout.fillWidth: true
            
            Text {
                text: media.positionText
                color: "#a6adc8"
                font { family: "Victor Mono SemiBold"; pixelSize: 12 }
            }

            Item { Layout.fillWidth: true }

            Text {
                text: media.durationText
                color: "#a6adc8"
                font { family: "Victor Mono SemiBold"; pixelSize: 12 }
            }
        }
    }
}
