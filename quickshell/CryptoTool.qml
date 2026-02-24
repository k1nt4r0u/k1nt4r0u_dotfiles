import QtQuick
import QtQuick.Layouts
import Quickshell.Io

Rectangle {
    id: crypto

    implicitHeight: cryptoLayout.implicitHeight + 28
    radius: 14
    color: Qt.rgba(17/255, 17/255, 27/255, 0.75)
    border.color: Qt.rgba(176/255, 196/255, 239/255, 0.15)
    border.width: 1

    Behavior on implicitHeight { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

    property string inputText: ""
    property var results: []
    property bool hasResults: results.length > 0

    Process {
        id: encodeProc
        property string buf: ""
        command: ["sh", "-c", "true"]
        stdout: SplitParser {
            onRead: data => { encodeProc.buf += data + "\n" }
        }
        onExited: {
            var lines = encodeProc.buf.trim().split("\n")
            var res = []
            for (var i = 0; i < lines.length; i++) {
                if (lines[i].length === 0) continue
                var idx = lines[i].indexOf(":")
                if (idx > 0) {
                    res.push({ label: lines[i].substring(0, idx), value: lines[i].substring(idx+1) })
                }
            }
            crypto.results = res
            encodeProc.buf = ""
        }
    }

    Process {
        id: clipCopy
        command: ["sh", "-c", "true"]
    }

    function encode(text) {
        if (text.length === 0) { crypto.results = []; return }
        var escaped = text.replace(/'/g, "'\\''")
        var script = "INPUT='" + escaped + "'\n" +
            "echo \"Base64:$(echo -n \"$INPUT\" | base64)\"\n" +
            "echo \"Base64 Dec:$(echo -n \"$INPUT\" | base64 -d 2>/dev/null || echo '[invalid]')\"\n" +
            "echo \"Hex:$(echo -n \"$INPUT\" | xxd -p | tr -d '\\n')\"\n" +
            "echo \"URL Enc:$(python3 -c \"import urllib.parse; print(urllib.parse.quote('$INPUT'))\" 2>/dev/null)\"\n" +
            "echo \"URL Dec:$(python3 -c \"import urllib.parse; print(urllib.parse.unquote('$INPUT'))\" 2>/dev/null)\"\n" +
            "echo \"ROT13:$(echo -n \"$INPUT\" | tr 'A-Za-z' 'N-ZA-Mn-za-m')\"\n" +
            "echo \"MD5:$(echo -n \"$INPUT\" | md5sum | cut -d' ' -f1)\"\n" +
            "echo \"SHA1:$(echo -n \"$INPUT\" | sha1sum | cut -d' ' -f1)\"\n" +
            "echo \"SHA256:$(echo -n \"$INPUT\" | sha256sum | cut -d' ' -f1)\"\n"
        encodeProc.command = ["sh", "-c", script]
        encodeProc.running = true
    }

    ColumnLayout {
        id: cryptoLayout
        anchors {
            left: parent.left; right: parent.right
            top: parent.top
            margins: 14
        }
        spacing: 8

        Text {
            text: "🔐  Crypto / Encode"
            color: "#cdd6f4"
            font { family: "Victor Mono SemiBold"; pixelSize: 15; bold: true }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 34
            radius: 8
            color: Qt.rgba(1,1,1,0.06)
            border.color: inputField.activeFocus ? "#C0E2F3" : Qt.rgba(1,1,1,0.1)
            border.width: 1
            Behavior on border.color { ColorAnimation { duration: 150 } }

            TextInput {
                id: inputField
                anchors { fill: parent; margins: 8 }
                color: "#cdd6f4"
                font { family: "Victor Mono SemiBold"; pixelSize: 15 }
                clip: true
                selectByMouse: true
                selectionColor: Qt.rgba(192/255, 226/255, 243/255, 0.3)

                Text {
                    anchors { verticalCenter: parent.verticalCenter; left: parent.left }
                    text: "Type or paste text..."
                    color: "#585b70"
                    font: parent.font
                    visible: !parent.text && !parent.activeFocus
                }

                onTextChanged: {
                    crypto.inputText = text
                    encodeTimer.restart()
                }
            }
        }

        Timer {
            id: encodeTimer
            interval: 300
            onTriggered: crypto.encode(crypto.inputText)
        }

        // Paste from clipboard button
        Rectangle {
            Layout.fillWidth: true
            height: 26
            radius: 6
            color: pasteMa.containsMouse ? Qt.rgba(192/255, 226/255, 243/255, 0.15) : Qt.rgba(1,1,1,0.04)
            Behavior on color { ColorAnimation { duration: 150 } }
            visible: !crypto.hasResults

            MouseArea {
                id: pasteMa
                anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: pasteProc.running = true
            }

            Text {
                anchors.centerIn: parent
                text: "󰆏  Paste from clipboard"
                color: "#6c7086"
                font { family: "Victor Mono SemiBold"; pixelSize: 14 }
            }

            Process {
                id: pasteProc
                command: ["wl-paste", "--no-newline"]
                stdout: SplitParser {
                    onRead: data => { inputField.text = data }
                }
            }
        }

        // Results
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 3
            visible: crypto.hasResults

            Repeater {
                model: crypto.results.length
                delegate: Rectangle {
                    Layout.fillWidth: true
                    height: 28
                    radius: 6
                    color: resMa.containsMouse ? Qt.rgba(1,1,1,0.08) : Qt.rgba(1,1,1,0.03)
                    Behavior on color { ColorAnimation { duration: 150 } }

                    property var res: crypto.results[index]

                    MouseArea {
                        id: resMa
                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            clipCopy.command = ["sh", "-c", "echo -n '" + parent.res.value.replace(/'/g, "'\\''") + "' | wl-copy"]
                            clipCopy.running = true
                        }
                    }

                    RowLayout {
                        anchors { fill: parent; leftMargin: 8; rightMargin: 8 }
                        Text {
                            text: parent.parent.res.label
                            color: "#C0E2F3"
                            font { family: "Victor Mono SemiBold"; pixelSize: 14; bold: true }
                            Layout.preferredWidth: 70
                        }
                        Text {
                            text: parent.parent.res.value
                            color: "#a6adc8"
                            font { family: "Victor Mono SemiBold"; pixelSize: 14 }
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                        Text {
                            text: "󰆏"
                            color: resMa.containsMouse ? "#C0E2F3" : "#45475a"
                            font { family: "Victor Mono SemiBold"; pixelSize: 14 }
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                    }
                }
            }
        }
    }
}
