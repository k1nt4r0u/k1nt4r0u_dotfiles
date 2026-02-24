import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

Scope {
    id: root
    property bool panelVisible: false
    property bool windowShown: false

    // Keep window alive during close animation
    onPanelVisibleChanged: {
        if (panelVisible) {
            windowShown = true
        }
    }

    IpcHandler {
        target: "panel"

        function toggle(): void {
            root.panelVisible = !root.panelVisible
        }

        function show(): void {
            root.panelVisible = true
        }

        function hide(): void {
            root.panelVisible = false
        }
    }

    // ── Status Bar (replaces Waybar) ──
    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData

            anchors.top: true
            margins.top: 6
            margins.left: 8
            margins.right: 8

            implicitWidth: modelData.width - 16
            implicitHeight: 42

            visible: true
            focusable: false
            exclusionMode: ExclusionMode.Normal
            exclusiveZone: 43
            aboveWindows: true
            color: "transparent"
            surfaceFormat.opaque: false

            Bar {
                anchors.fill: parent
                panelVisible: root.panelVisible
                onTogglePanel: root.panelVisible = !root.panelVisible
            }
        }
    }

    // ── Settings Panel ──
    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData

            anchors {
                top: true
                right: true
            }

            margins.top: 54
            margins.right: 8

            implicitWidth: 380
            implicitHeight: Math.min(panelContent.implicitHeight + 24, modelData.height - 70)

            visible: root.windowShown
            focusable: true
            exclusionMode: ExclusionMode.Ignore
            aboveWindows: true
            color: "transparent"
            surfaceFormat.opaque: false

            Item {
                id: panelContent
                anchors { fill: parent; margins: 12 }
                implicitHeight: panelColumn.implicitHeight
                opacity: root.panelVisible ? 1.0 : 0.0

                Behavior on opacity {
                    NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
                }

                onOpacityChanged: {
                    if (opacity === 0 && !root.panelVisible) {
                        root.windowShown = false
                    }
                }

                Flickable {
                    id: scrollView
                    anchors.fill: parent
                    contentHeight: panelColumn.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    flickableDirection: Flickable.VerticalFlick

                    ColumnLayout {
                        id: panelColumn
                        width: parent.width
                        spacing: 8

                        ClockIsland {
                            Layout.fillWidth: true
                        }

                        FullCalendar {
                            Layout.fillWidth: true
                        }

                        MediaPlayer {
                            id: mediaPlayer
                            Layout.fillWidth: true
                        }

                        QuickSettings {
                            id: settingsPanel
                            Layout.fillWidth: true
                        }

                        CtfToolkit {
                            Layout.fillWidth: true
                        }

                        NetworkRecon {
                            Layout.fillWidth: true
                        }

                        DockerMonitor {
                            Layout.fillWidth: true
                        }

                        CryptoTool {
                            Layout.fillWidth: true
                        }

                        CtfTimer {
                            Layout.fillWidth: true
                        }

                        TailscaleStatus {
                            Layout.fillWidth: true
                        }

                        SyncthingWatcher {
                            Layout.fillWidth: true
                        }
                    }
                }
            }
        }
    }
}
