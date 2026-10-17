import QtQuick
import qs.Common
import qs.Widgets

Item {
    id: root

    property bool vertical: false
    property bool available: false
    property string workspaceName: "1"
    property string activeTitle: ""
    property string activeClass: ""
    property int windowCount: 0
    property bool isFloating: false
    property bool isFullscreen: false
    property bool isPinned: false
    property string layoutName: "dwindle"
    property real widgetThickness: 0
    property real horizontalPadding: Theme.spacingXS
    property int maxTitleLength: 22

    signal scrollRequested(int direction)
    signal middleClickRequested()
    signal rightClickRequested()

    readonly property string displayTitle: {
        let title = activeTitle ? activeTitle : activeClass;
        if (!title) return "";
        if (title.length > maxTitleLength) {
            return title.substring(0, maxTitleLength - 1) + "…";
        }
        return title;
    }

    implicitWidth: root.vertical
        ? root.widgetThickness
        : pillRow.implicitWidth + root.horizontalPadding * 2 + Theme.spacingS
    implicitHeight: root.vertical
        ? pillColumn.implicitHeight + Theme.spacingL * 2
        : root.widgetThickness
    width: implicitWidth
    height: implicitHeight

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.MiddleButton | Qt.RightButton
        onPressed: function(mouse) {
            if (mouse.button === Qt.MiddleButton) {
                root.middleClickRequested();
            } else if (mouse.button === Qt.RightButton) {
                root.rightClickRequested();
            }
        }
        onWheel: function(wheelEvent) {
            const delta = wheelEvent.angleDelta.y !== 0 ? wheelEvent.angleDelta.y : wheelEvent.angleDelta.x;
            if (delta === 0) return;
            wheelEvent.accepted = true;
            root.scrollRequested(delta > 0 ? 1 : -1);
        }
    }

    // Horizontal Layout for Top/Bottom DankBar
    Row {
        id: pillRow
        visible: !root.vertical
        anchors.centerIn: parent
        spacing: Theme.spacingXS

        // Workspace Badge
        Rectangle {
            id: wsBadge
            anchors.verticalCenter: parent.verticalCenter
            height: Math.max(20, Theme.fontSizeSmall + 8)
            width: wsRow.implicitWidth + Theme.spacingXS * 2
            radius: Theme.radiusSmall
            color: root.available ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.22) : Theme.surfaceVariant

            Row {
                id: wsRow
                anchors.centerIn: parent
                spacing: 3

                DankIcon {
                    name: "desktop_windows"
                    size: 14
                    color: root.available ? Theme.primary : Theme.surfaceVariantText
                    anchors.verticalCenter: parent.verticalCenter
                }

                StyledText {
                    text: root.workspaceName
                    color: root.available ? Theme.primary : Theme.surfaceText
                    font.pixelSize: Theme.fontSizeSmall
                    font.weight: Font.Bold
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }

        // Active Window Title / Class
        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.spacingXS
            visible: root.displayTitle.length > 0

            DankIcon {
                name: root.isFloating ? "picture_in_picture_alt" : (root.isFullscreen ? "fullscreen" : "web_asset")
                size: 14
                color: root.isFloating ? Theme.secondary : Theme.surfaceVariantText
                anchors.verticalCenter: parent.verticalCenter
            }

            StyledText {
                text: root.displayTitle
                color: Theme.surfaceText
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.Medium
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        // Window Count Chip
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            height: Math.max(18, Theme.fontSizeSmall + 4)
            width: Math.max(18, countText.implicitWidth + 8)
            radius: height / 2
            color: root.windowCount > 0 ? Theme.surfaceVariant : Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.4)
            visible: root.windowCount > 0

            StyledText {
                id: countText
                anchors.centerIn: parent
                text: String(root.windowCount)
                color: Theme.surfaceVariantText
                font.pixelSize: Theme.fontSizeSmall - 2
                font.weight: Font.DemiBold
            }
        }
    }

    // Vertical Layout for Side DankBar
    Column {
        id: pillColumn
        visible: root.vertical
        anchors.centerIn: parent
        spacing: Theme.spacingXS

        DankIcon {
            name: "desktop_windows"
            size: Theme.iconSize - 6
            color: root.available ? Theme.primary : Theme.surfaceVariantText
            anchors.horizontalCenter: parent.horizontalCenter
        }

        StyledText {
            text: root.workspaceName
            color: Theme.primary
            font.pixelSize: Theme.fontSizeSmall
            font.weight: Font.Bold
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            height: 16
            width: 16
            radius: 8
            color: Theme.surfaceVariant
            visible: root.windowCount > 0

            StyledText {
                anchors.centerIn: parent
                text: String(root.windowCount)
                color: Theme.surfaceVariantText
                font.pixelSize: 10
                font.weight: Font.Bold
            }
        }
    }
}
