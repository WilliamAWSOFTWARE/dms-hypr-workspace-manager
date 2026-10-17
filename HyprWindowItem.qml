import QtQuick
import qs.Common
import qs.Widgets

Rectangle {
    id: root

    required property var clientData
    property bool isActiveWindow: false
    property bool busy: false

    signal focusRequested(string address)
    signal moveRequested(string address, string workspaceTarget)
    signal toggleFloatRequested(string address)
    signal toggleFullscreenRequested(string address)
    signal togglePinRequested(string address)
    signal closeRequested(string address)

    readonly property string addr: clientData ? clientData.address : ""
    readonly property string title: clientData ? (clientData.title || clientData.class || "Sin título") : ""
    readonly property string appClass: clientData ? (clientData.class || "") : ""
    readonly property var wsId: clientData ? clientData.workspaceId : 1
    readonly property string wsName: clientData ? (clientData.workspaceName || String(wsId)) : ""
    readonly property bool isFloating: clientData ? clientData.floating : false
    readonly property bool isFullscreen: clientData ? clientData.fullscreen : false
    readonly property bool isPinned: clientData ? clientData.pinned : false
    readonly property bool isScratchpad: String(wsName).toLowerCase().includes("special")

    implicitHeight: mainColumn.implicitHeight + Theme.spacingS * 2
    radius: Theme.cornerRadius
    color: root.isActiveWindow ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12) : Theme.surfaceContainerHigh
    border.color: root.isActiveWindow ? Theme.primary : Theme.outline
    border.width: root.isActiveWindow ? 1.5 : 1

    Column {
        id: mainColumn
        anchors.fill: parent
        anchors.margins: Theme.spacingS
        spacing: 6

        // Row 1: App Info and State Badges
        Row {
            width: parent.width
            spacing: Theme.spacingS

            // Window Icon / Class
            Rectangle {
                width: 24
                height: 24
                radius: 6
                color: root.isActiveWindow ? Theme.primary : Theme.surfaceVariant
                anchors.verticalCenter: parent.verticalCenter

                DankIcon {
                    name: root.isFloating ? "picture_in_picture_alt" : (root.isFullscreen ? "fullscreen" : "web_asset")
                    size: 15
                    color: root.isActiveWindow ? Theme.surface : Theme.surfaceText
                    anchors.centerIn: parent
                }
            }

            Column {
                width: parent.width - 24 - Theme.spacingS - badgesRow.implicitWidth - 10
                anchors.verticalCenter: parent.verticalCenter
                spacing: 1

                StyledText {
                    width: parent.width
                    text: root.title
                    color: Theme.surfaceText
                    font.pixelSize: Theme.fontSizeSmall
                    font.weight: root.isActiveWindow ? Font.Bold : Font.Medium
                    elide: Text.ElideRight
                }

                StyledText {
                    width: parent.width
                    text: root.appClass + (root.isScratchpad ? " • [Scratchpad]" : " • Workspace " + root.wsName)
                    color: Theme.surfaceVariantText
                    font.pixelSize: 10
                    elide: Text.ElideRight
                }
            }

            // State Badges
            Row {
                id: badgesRow
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4

                Rectangle {
                    visible: root.isFloating
                    height: 18
                    width: floatText.implicitWidth + 8
                    radius: 9
                    color: Qt.rgba(Theme.secondary.r, Theme.secondary.g, Theme.secondary.b, 0.25)
                    StyledText {
                        id: floatText
                        anchors.centerIn: parent
                        text: "Flotante"
                        color: Theme.secondary
                        font.pixelSize: 9
                        font.weight: Font.DemiBold
                    }
                }

                Rectangle {
                    visible: root.isFullscreen
                    height: 18
                    width: fsText.implicitWidth + 8
                    radius: 9
                    color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.25)
                    StyledText {
                        id: fsText
                        anchors.centerIn: parent
                        text: "Pantalla completa"
                        color: Theme.primary
                        font.pixelSize: 9
                        font.weight: Font.DemiBold
                    }
                }

                Rectangle {
                    visible: root.isPinned
                    height: 18
                    width: pinText.implicitWidth + 8
                    radius: 9
                    color: Qt.rgba(Theme.warning.r, Theme.warning.g, Theme.warning.b, 0.25)
                    StyledText {
                        id: pinText
                        anchors.centerIn: parent
                        text: "Fijada"
                        color: Theme.warning
                        font.pixelSize: 9
                        font.weight: Font.DemiBold
                    }
                }
            }
        }

        // Row 2: Action Toolbar & Quick Workspace Switcher
        Row {
            width: parent.width
            spacing: Theme.spacingXS

            // Move to Workspace Label
            StyledText {
                text: "Mover a:"
                color: Theme.surfaceVariantText
                font.pixelSize: 10
                font.weight: Font.Medium
                anchors.verticalCenter: parent.verticalCenter
            }

            // Quick Workspace Buttons 1..5
            Repeater {
                model: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]

                delegate: Rectangle {
                    required property int modelData
                    width: 22
                    height: 22
                    radius: 4
                    color: root.wsId === modelData ? Theme.primary : (wsBtnArea.containsMouse ? Theme.surfaceVariant : Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.35))
                    border.color: root.wsId === modelData ? Theme.primary : Theme.outline
                    border.width: 1

                    StyledText {
                        anchors.centerIn: parent
                        text: String(modelData)
                        color: root.wsId === modelData ? Theme.surface : Theme.surfaceText
                        font.pixelSize: 10
                        font.weight: root.wsId === modelData ? Font.Bold : Font.Normal
                    }

                    MouseArea {
                        id: wsBtnArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        enabled: !root.busy && root.wsId !== modelData
                        onClicked: root.moveRequested(root.addr, String(modelData))
                    }
                }
            }

            // Scratchpad button
            Rectangle {
                width: scratchText.implicitWidth + 8
                height: 22
                radius: 4
                color: root.isScratchpad ? Theme.secondary : (scratchArea.containsMouse ? Theme.surfaceVariant : Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.35))
                border.color: Theme.outline
                border.width: 1

                Row {
                    anchors.centerIn: parent
                    spacing: 2
                    DankIcon {
                        name: "star"
                        size: 11
                        color: root.isScratchpad ? Theme.surface : Theme.secondary
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    StyledText {
                        id: scratchText
                        text: "Scratchpad"
                        color: root.isScratchpad ? Theme.surface : Theme.surfaceText
                        font.pixelSize: 9
                        font.weight: Font.Medium
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    id: scratchArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    enabled: !root.busy
                    onClicked: root.moveRequested(root.addr, "special:scratchpad")
                }
            }

            Item {
                // Spacer
                width: parent.width - (22 * 10) - (scratchText.implicitWidth + 8) - (Theme.spacingXS * 12) - 50 - (btnRow.implicitWidth)
                height: 1
            }

            // Window Action Buttons: Focus, Float, Fullscreen, Pin, Close
            Row {
                id: btnRow
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4

                // Focus
                Rectangle {
                    width: 24
                    height: 24
                    radius: 5
                    color: focusArea.containsMouse ? Theme.primary : Theme.surfaceVariant

                    DankIcon {
                        name: "visibility"
                        size: 13
                        color: focusArea.containsMouse ? Theme.surface : Theme.surfaceText
                        anchors.centerIn: parent
                    }

                    MouseArea {
                        id: focusArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        enabled: !root.busy
                        onClicked: root.focusRequested(root.addr)
                    }
                }

                // Toggle Float
                Rectangle {
                    width: 24
                    height: 24
                    radius: 5
                    color: floatArea.containsMouse ? Theme.secondary : (root.isFloating ? Qt.rgba(Theme.secondary.r, Theme.secondary.g, Theme.secondary.b, 0.3) : Theme.surfaceVariant)

                    DankIcon {
                        name: "picture_in_picture_alt"
                        size: 13
                        color: floatArea.containsMouse ? Theme.surface : Theme.surfaceText
                        anchors.centerIn: parent
                    }

                    MouseArea {
                        id: floatArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        enabled: !root.busy
                        onClicked: root.toggleFloatRequested(root.addr)
                    }
                }

                // Fullscreen
                Rectangle {
                    width: 24
                    height: 24
                    radius: 5
                    color: fsArea.containsMouse ? Theme.primary : (root.isFullscreen ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.3) : Theme.surfaceVariant)

                    DankIcon {
                        name: "fullscreen"
                        size: 13
                        color: fsArea.containsMouse ? Theme.surface : Theme.surfaceText
                        anchors.centerIn: parent
                    }

                    MouseArea {
                        id: fsArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        enabled: !root.busy
                        onClicked: root.toggleFullscreenRequested(root.addr)
                    }
                }

                // Pin
                Rectangle {
                    width: 24
                    height: 24
                    radius: 5
                    color: pinArea.containsMouse ? Theme.warning : (root.isPinned ? Qt.rgba(Theme.warning.r, Theme.warning.g, Theme.warning.b, 0.3) : Theme.surfaceVariant)

                    DankIcon {
                        name: "push_pin"
                        size: 13
                        color: pinArea.containsMouse ? Theme.surface : Theme.surfaceText
                        anchors.centerIn: parent
                    }

                    MouseArea {
                        id: pinArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        enabled: !root.busy
                        onClicked: root.togglePinRequested(root.addr)
                    }
                }

                // Close Window
                Rectangle {
                    width: 24
                    height: 24
                    radius: 5
                    color: closeArea.containsMouse ? Theme.error : Theme.surfaceVariant

                    DankIcon {
                        name: "close"
                        size: 13
                        color: closeArea.containsMouse ? Theme.surface : Theme.surfaceText
                        anchors.centerIn: parent
                    }

                    MouseArea {
                        id: closeArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        enabled: !root.busy
                        onClicked: root.closeRequested(root.addr)
                    }
                }
            }
        }
    }
}
