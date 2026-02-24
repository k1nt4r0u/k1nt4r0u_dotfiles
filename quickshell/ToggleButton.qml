import QtQuick

Rectangle {
    id: btn

    property string icon: ""
    property bool active: false
    signal clicked()

    width: 42
    height: 42
    radius: 12
    color: active ? Qt.rgba(176/255, 196/255, 239/255, 0.2) : (btnMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.1) : Qt.rgba(255, 255, 255, 0.04))
    border.color: active ? Qt.rgba(176/255, 196/255, 239/255, 0.35) : (btnMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.15) : Qt.rgba(255, 255, 255, 0.08))
    border.width: 1
    scale: btnMouse.pressed ? 0.92 : 1.0

    Behavior on color { ColorAnimation { duration: 200; easing.type: Easing.OutCubic } }
    Behavior on border.color { ColorAnimation { duration: 200; easing.type: Easing.OutCubic } }
    Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

    Text {
        anchors.centerIn: parent
        text: btn.icon
        color: btn.active ? "#b0c4ef" : (btnMouse.containsMouse ? "#cdd6f4" : "#a6adc8")
        font.pixelSize: 22
        font.family: "Victor Mono SemiBold"

        Behavior on color { ColorAnimation { duration: 200; easing.type: Easing.OutCubic } }
    }

    MouseArea {
        id: btnMouse
        anchors.fill: parent
        hoverEnabled: true
        onClicked: btn.clicked()
        cursorShape: Qt.PointingHandCursor
    }
}
