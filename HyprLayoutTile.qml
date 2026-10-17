import QtQuick
import qs.Common
import qs.Widgets
import "LayoutPreviewData.js" as LayoutPreviewData

Rectangle {
    id: root

    required property var layout
    property bool selected: false
    property bool busy: false

    signal layoutSelected(string layoutId)

    readonly property bool hovered: buttonArea.containsMouse

    implicitHeight: contentColumn.implicitHeight + Theme.spacingS * 2
    radius: Theme.cornerRadius
    color: root.selected ? Qt.alpha(Theme.primary, 0.14) : (root.hovered ? Theme.surfaceContainer : Theme.surfaceContainerHigh)
    border.color: root.selected ? Theme.primary : Qt.alpha(Theme.outline, 0.6)
    border.width: root.selected ? 2 : 1

    Column {
        id: contentColumn
        anchors.fill: parent
        anchors.margins: Theme.spacingS
        spacing: Theme.spacingXS

        HyprLayoutPreview {
            width: parent.width
            selected: root.selected
            hovered: root.hovered
            previewModel: LayoutPreviewData.windowSpecs(root.layout.id)
            anchors.horizontalCenter: parent.horizontalCenter
        }

        StyledText {
            width: parent.width
            text: root.layout.label
            color: root.selected ? Theme.primary : Theme.surfaceText
            font.pixelSize: Theme.fontSizeSmall - 1
            font.weight: root.selected ? Font.DemiBold : Font.Normal
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            maximumLineCount: 1
        }
    }

    MouseArea {
        id: buttonArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        enabled: !root.busy
        onClicked: root.layoutSelected(root.layout.id)
    }
}
