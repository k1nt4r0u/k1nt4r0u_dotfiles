import QtQuick
import QtQuick.Layouts

Rectangle {
    id: clockIsland

    implicitHeight: clockLayout.implicitHeight + 28
    radius: 14
    color: Qt.rgba(17/255, 17/255, 27/255, 0.75)
    border.color: Qt.rgba(176/255, 196/255, 239/255, 0.15)
    border.width: 1

    property string timeString: "00:00:00"
    property string msString: "000"

    Timer {
        id: clockTimer
        interval: 10
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            var now = new Date()
            var h = now.getHours()
            var m = now.getMinutes()
            var s = now.getSeconds()
            var ms = now.getMilliseconds()
            clockIsland.timeString = (h < 10 ? "0" : "") + h + ":"
                                   + (m < 10 ? "0" : "") + m + ":"
                                   + (s < 10 ? "0" : "") + s
            clockIsland.msString = (ms < 100 ? "0" : "") + (ms < 10 ? "0" : "") + ms
        }
    }

    ColumnLayout {
        id: clockLayout
        anchors {
            left: parent.left; right: parent.right
            top: parent.top
            margins: 14
        }
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            Text {
                text: "🕐  Clock"
                color: "#cdd6f4"
                font { family: "Victor Mono SemiBold"; pixelSize: 15; bold: true }
            }
            Item { Layout.fillWidth: true }
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 4

            Text {
                id: clockText
                text: clockIsland.timeString
                color: "#cdd6f4"
                font {
                    family: "Victor Mono SemiBold"
                    pixelSize: 34
                    bold: true
                }
            }

            Text {
                text: "." + clockIsland.msString
                color: "#6c7086"
                font {
                    family: "Victor Mono SemiBold"
                    pixelSize: 20
                    bold: true
                }
                Layout.alignment: Qt.AlignBottom
                Layout.bottomMargin: 3
            }
        }
    }
}
