import QtQuick
import qs.Common
import qs.Widgets

Rectangle {
    id: root

    required property var workspaceData
    property bool busy: false

    signal workspaceSelected(int workspaceId)
    signal moveActiveRequested(int workspaceId)

    readonly property bool isActive: workspaceData && workspaceData.isActive
    readonly property int wsId: workspaceData ? workspaceData.id : 1
    readonly property int winCount: workspaceData ? workspaceData.windowsCount : 0
    readonly property var clients: workspaceData && workspaceData.clients ? workspaceData.clients : []
    readonly property bool hovered: tileMouseArea.containsMouse

    implicitHeight: 90
    radius: Theme.cornerRadius
    color: root.isActive
        ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.16)
        : (root.hovered ? Theme.surfaceContainer : Theme.surfaceContainerHigh)
    border.color: root.isActive
        ? Theme.primary
        : (root.hovered ? Theme.outline : Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.4))
    border.width: root.isActive ? 2 : 1

    MouseArea {
        id: tileMouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        enabled: !root.busy
        onClicked: root.workspaceSelected(root.wsId)
    }

    Column {
        anchors.fill: parent
        anchors.margins: Theme.spacingS
        spacing: 4

        // Top Row: WS number, Active tag, and Move button
        Row {
            width: parent.width
            height: 22

            Row {
                spacing: Theme.spacingXS
                anchors.verticalCenter: parent.verticalCenter

                Rectangle {
                    width: 22
                    height: 22
                    radius: 11
                    color: root.isActive ? Theme.primary : Theme.surfaceVariant

                    StyledText {
                        anchors.centerIn: parent
                        text: String(root.wsId)
                        color: root.isActive ? Theme.surface : Theme.surfaceText
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: Font.Bold
                    }
                }

                Rectangle {
                    visible: root.isActive
                    height: 18
                    width: activeTagText.implicitWidth + 8
                    radius: 9
                    color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.25)
                    anchors.verticalCenter: parent.verticalCenter

                    StyledText {
                        id: activeTagText
                        anchors.centerIn: parent
                        text: "ACTIVO"
                        color: Theme.primary
                        font.pixelSize: 9
                        font.weight: Font.Bold
                    }
                }
            }

            Item {
                // Spacer
                width: parent.width - 22 - (root.isActive ? activeTagText.implicitWidth + 8 + Theme.spacingXS : 0) - (sendButton.visible ? sendButton.width : 0) - (countBadge.visible ? countBadge.width : 0)
                height: 1
            }

            // Quick Send Active Window button (visible on hover if not active)
            Rectangle {
                id: sendButton
                visible: root.hovered && !root.isActive
                height: 22
                width: 22
                radius: 11
                color: sendMouseArea.containsMouse ? Theme.primary : Theme.surfaceVariant
                anchors.verticalCenter: parent.verticalCenter

                DankIcon {
                    name: "forward"
                    size: 14
                    color: sendMouseArea.containsMouse ? Theme.surface : Theme.surfaceText
                    anchors.centerIn: parent
                }

                MouseArea {
                    id: sendMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.moveActiveRequested(root.wsId);
                    }
                }
            }

            // Window Count Badge (when not hovered or when active)
            Rectangle {
                id: countBadge
                visible: !sendButton.visible && root.winCount > 0
                height: 18
                width: countBadgeText.implicitWidth + 8
                radius: 9
                color: Theme.surfaceVariant
                anchors.verticalCenter: parent.verticalCenter

                StyledText {
                    id: countBadgeText
                    anchors.centerIn: parent
                    text: root.winCount + (root.winCount === 1 ? " vent." : " vents.")
                    color: Theme.surfaceVariantText
                    font.pixelSize: 10
                    font.weight: Font.Medium
                }
            }
        }

        // Bottom Area: Window chips
        Item {
            width: parent.width
            height: parent.height - 26

            // If empty
            StyledText {
                visible: root.clients.length === 0
                anchors.centerIn: parent
                text: "Espacio vacío"
                color: Theme.surfaceVariantText
                font.pixelSize: 11
                font.italic: true
            }

            // If has windows: show up to 2 mini chips
            Column {
                visible: root.clients.length > 0
                anchors.fill: parent
                spacing: 2

                Repeater {
                    model: root.clients.slice(0, 2)

                    delegate: Rectangle {
                        required property var modelData
                        width: parent.width
                        height: 16
                        radius: 4
                        color: Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.4)

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 4
                            anchors.rightMargin: 4
                            spacing: 4

                            DankIcon {
                                name: modelData.floating ? "picture_in_picture_alt" : "web_asset"
                                size: 10
                                color: Theme.surfaceVariantText
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            StyledText {
                                text: modelData.class || modelData.title || "Ventana"
                                color: Theme.surfaceText
                                font.pixelSize: 10
                                font.weight: Font.Medium
                                elide: Text.ElideRight
                                width: parent.width - 18
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }
                }

                StyledText {
                    visible: root.clients.length > 2
                    text: "+" + (root.clients.length - 2) + " más..."
                    color: Theme.primary
                    font.pixelSize: 9
                    font.weight: Font.Bold
                }
            }
        }
    }
}
