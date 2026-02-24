import QtQuick

Item {
    id: slider

    property real value: 0.5
    property color accentColor: "#b0c4ef"
    readonly property bool pressed: dragArea.pressed
    signal valueSet(real newValue)

    height: 24
    implicitHeight: 24

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 6
        radius: 3
        color: Qt.rgba(255, 255, 255, 0.06)

        Rectangle {
            width: Math.max(0, Math.min(1, slider.value)) * parent.width
            height: parent.height
            radius: 3
            color: slider.accentColor
            opacity: 0.7

            Behavior on width { NumberAnimation { duration: dragArea.pressed ? 0 : 150; easing.type: Easing.OutCubic } }
        }

        Behavior on color { ColorAnimation { duration: 200 } }
    }

    Rectangle {
        id: thumb
        width: dragArea.pressed ? 18 : 14
        height: dragArea.pressed ? 18 : 14
        radius: width / 2
        color: slider.accentColor
        x: Math.max(0, Math.min(1, slider.value)) * (slider.width - width)
        anchors.verticalCenter: parent.verticalCenter

        Behavior on width { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
        Behavior on height { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
        Behavior on x { NumberAnimation { duration: dragArea.pressed ? 0 : 150; easing.type: Easing.OutCubic } }
        Behavior on color { ColorAnimation { duration: 200 } }

        // Glow ring
        Rectangle {
            anchors.centerIn: parent
            width: parent.width + 8
            height: parent.height + 8
            radius: width / 2
            color: "transparent"
            border.color: slider.accentColor
            border.width: 1.5
            opacity: dragArea.pressed ? 0.4 : (dragArea.containsMouse ? 0.2 : 0)

            Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        }
    }

    MouseArea {
        id: dragArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        function updateFromMouse(mouseX: real) {
            let newVal = Math.max(0, Math.min(1, mouseX / slider.width))
            slider.value = newVal
            slider.valueSet(newVal)
        }

        onPressed: mouse => updateFromMouse(mouse.x)
        onPositionChanged: mouse => { if (pressed) updateFromMouse(mouse.x) }
    }
}
