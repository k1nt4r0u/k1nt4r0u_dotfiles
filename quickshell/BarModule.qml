import QtQuick

// Clickable module pill for Bar.qml
Item {
    id: mod
    implicitWidth: label.implicitWidth + 24
    implicitHeight: parent ? parent.height : 30

    property alias text: label.text
    property color textColor: "#b0c4ef"
    property string fontFamily: "Hurmit Nerd Font"
    property int fontSize: 14
    property color bgOverride: "transparent"
    property bool warningPulse: false
    property bool rightPad: false

    signal clicked()

    Rectangle {
        anchors.fill: parent
        anchors.margins: 3
        radius: 8
        color: {
            if (mod.bgOverride !== Qt.rgba(0,0,0,0) && mod.bgOverride.toString() !== "#00000000")
                return mod.bgOverride
            return ma.containsMouse ? Qt.rgba(176/255, 196/255, 239/255, 0.12) : "transparent"
        }
        Behavior on color { ColorAnimation { duration: 200 } }

        // Critical battery blink
        SequentialAnimation on opacity {
            running: mod.warningPulse
            loops: Animation.Infinite
            NumberAnimation { to: 0.55; duration: 600; easing.type: Easing.InOutSine }
            NumberAnimation { to: 1.0; duration: 600; easing.type: Easing.InOutSine }
        }
    }

    Text {
        id: label
        anchors.centerIn: parent
        anchors.horizontalCenterOffset: mod.rightPad ? -4 : 0
        color: mod.textColor
        font { family: mod.fontFamily; pixelSize: mod.fontSize }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: mod.clicked()
    }
}
