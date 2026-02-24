import QtQuick
import QtQuick.Layouts

Rectangle {
    id: monthRoot
    property int year: 2026
    property int month: 0 // 0-11
    property color accentColor: "#b0c4ef"
    property color textColor: "#cdd6f4"
    property color subtextColor: "#a6adc8"
    property color todayColor: "#C0E2F3"
    
    implicitWidth: 250
    implicitHeight: mainCol.implicitHeight
    color: "transparent"

    readonly property var monthNames: ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
    readonly property var dayNames: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    
    readonly property date firstDay: new Date(year, month, 1)
    readonly property int daysInMonth: new Date(year, month + 1, 0).getDate()
    readonly property int startOffset: firstDay.getDay()

    ColumnLayout {
        id: mainCol
        anchors { left: parent.left; right: parent.right; top: parent.top }
        spacing: 8

        Text {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: monthNames[month] + " " + year
            color: accentColor
            font { family: "Victor Mono SemiBold"; pixelSize: 16; bold: true }
        }

        GridLayout {
            columns: 7
            columnSpacing: 6
            rowSpacing: 6
            Layout.alignment: Qt.AlignHCenter

            Repeater {
                model: dayNames
                delegate: Text {
                    text: modelData
                    color: subtextColor
                    font { family: "Victor Mono SemiBold"; pixelSize: 11; bold: true }
                    width: 32
                    horizontalAlignment: Text.AlignHCenter
                }
            }

            // Empty spaces for previous month
            Repeater {
                model: startOffset
                delegate: Item { width: 32; height: 32 }
            }

            // Days of the month
            Repeater {
                model: daysInMonth
                delegate: Rectangle {
                    width: 32; height: 32
                    radius: 6
                    property int day: index + 1
                    property bool isToday: {
                        var d = new Date()
                        return d.getDate() === day && d.getMonth() === month && d.getFullYear() === year
                    }
                    color: isToday ? todayColor : (dayMouse.containsMouse ? Qt.rgba(1,1,1,0.05) : "transparent")
                    
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Text {
                        anchors.centerIn: parent
                        text: day
                        color: isToday ? "#1e1e2e" : textColor
                        font { family: "Victor Mono SemiBold"; pixelSize: 13; bold: isToday }
                    }

                    MouseArea {
                        id: dayMouse
                        anchors.fill: parent
                        hoverEnabled: true
                    }
                }
            }
        }
    }
}
