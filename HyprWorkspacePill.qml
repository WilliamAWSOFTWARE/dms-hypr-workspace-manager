import QtQuick
import qs.Common
import qs.Widgets

Item {
    id: root

    property bool vertical: false
    property bool available: true
    property string code: "DW"
    property string label: "Dwindle"
    property string iconName: "account_tree"
    property real widgetThickness: 0
    property real horizontalPadding: Theme.spacingXS

    signal scrollRequested(int direction)
    signal middleClickRequested()

    implicitWidth: root.vertical ? root.widgetThickness : pillRow.implicitWidth + root.horizontalPadding * 2
    implicitHeight: root.vertical ? pillColumn.implicitHeight + Theme.spacingL * 2 : root.widgetThickness
    width: implicitWidth
    height: implicitHeight

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.MiddleButton
        onPressed: root.middleClickRequested()
        onWheel: function (wheelEvent) {
            const delta = wheelEvent.angleDelta.y !== 0 ? wheelEvent.angleDelta.y : wheelEvent.angleDelta.x;
            if (delta === 0) return;
            wheelEvent.accepted = true;
            root.scrollRequested(delta > 0 ? 1 : -1);
        }
    }

    Row {
        id: pillRow
        visible: !root.vertical
        anchors.centerIn: parent
        spacing: Theme.spacingXS

        DankIcon {
            name: root.iconName
            size: Theme.iconSize - 6
            color: root.available ? Theme.primary : Theme.surfaceVariantText
            anchors.verticalCenter: parent.verticalCenter
        }

        StyledText {
            text: root.code
            color: Theme.surfaceText
            font.pixelSize: Theme.fontSizeSmall
            font.weight: Font.DemiBold
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    Column {
        id: pillColumn
        visible: root.vertical
        anchors.centerIn: parent
        spacing: Theme.spacingXS

        DankIcon {
            name: root.iconName
            size: Theme.iconSize - 6
            color: root.available ? Theme.primary : Theme.surfaceVariantText
            anchors.horizontalCenter: parent.horizontalCenter
        }

        StyledText {
            text: root.code
            color: Theme.surfaceText
            font.pixelSize: Theme.fontSizeSmall
            font.weight: Font.DemiBold
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }
}
