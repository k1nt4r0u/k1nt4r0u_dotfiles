import QtQuick
import QtQuick.Layouts

Rectangle {
    id: fullCalendar
    implicitWidth: 380
    implicitHeight: mainLayout.implicitHeight + 32
    radius: 14
    color: Qt.rgba(17/255, 17/255, 27/255, 0.75)
    border.color: Qt.rgba(176/255, 196/255, 239/255, 0.15)
    border.width: 1

    property int currentYear: new Date().getFullYear()
    property int currentMonth: new Date().getMonth()
    property bool expanded: true

    ColumnLayout {
        id: mainLayout
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 16 }
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            
            Text {
                text: "📅  Calendar"
                color: "#b0c4ef"
                font { family: "Victor Mono SemiBold"; pixelSize: 15; bold: true }
            }
            
            Item { Layout.fillWidth: true }

            // Navigation Buttons
            RowLayout {
                spacing: 12
                visible: fullCalendar.expanded

                Text {
                    text: "󰅁"
                    color: "#a6adc8"
                    font { family: "Victor Mono SemiBold"; pixelSize: 18 }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (fullCalendar.currentMonth === 0) {
                                fullCalendar.currentMonth = 11;
                                fullCalendar.currentYear--;
                            } else {
                                fullCalendar.currentMonth--;
                            }
                        }
                    }
                }

                Text {
                    text: "󰅂"
                    color: "#a6adc8"
                    font { family: "Victor Mono SemiBold"; pixelSize: 18 }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (fullCalendar.currentMonth === 11) {
                                fullCalendar.currentMonth = 0;
                                fullCalendar.currentYear++;
                            } else {
                                fullCalendar.currentMonth++;
                            }
                        }
                    }
                }
            }

            Rectangle { width: 1; height: 16; color: Qt.rgba(1,1,1,0.1); visible: true }
            
            Text {
                text: fullCalendar.expanded ? "󰅃" : "󰅀"
                color: "#a6adc8"
                font { family: "Victor Mono SemiBold"; pixelSize: 14 }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: fullCalendar.expanded = !fullCalendar.expanded
                }
            }
        }

        CalendarModule {
            id: singleMonth
            month: fullCalendar.currentMonth
            year: fullCalendar.currentYear
            Layout.fillWidth: true
            visible: fullCalendar.expanded
            
            // Adjust internal sizing for single month view
            implicitWidth: parent.width
        }
    }
}
