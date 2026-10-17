import QtQuick
import qs.Common

Rectangle {
    id: root

    property bool selected: false
    property bool hovered: false
    property var previewModel: []

    implicitHeight: 52
    radius: Theme.cornerRadius - 4
    color: root.selected ? Qt.alpha(Theme.surface, 0.94) : Qt.alpha(Theme.surface, 0.76)
    border.color: root.selected ? Qt.alpha(Theme.primary, 0.6) : Qt.alpha(Theme.outline, 0.6)
    border.width: 1
    clip: true

    Rectangle {
        anchors.fill: parent
        anchors.margins: 3
        radius: Math.max(3, root.radius - 2)
        color: root.selected ? Qt.alpha(Theme.surfaceContainer, 0.9) : Qt.alpha(Theme.surfaceContainerHigh, 0.86)
        border.color: Qt.alpha(Theme.outline, 0.3)
        border.width: 1
        clip: true

        Item {
            id: viewport
            anchors.fill: parent
            anchors.margins: 6

            Repeater {
                model: root.previewModel

                delegate: Rectangle {
                    required property var modelData

                    x: viewport.width * modelData.x
                    y: viewport.height * modelData.y
                    width: Math.max(2, viewport.width * modelData.w)
                    height: Math.max(2, viewport.height * modelData.h)
                    radius: 4
                    z: modelData.z || 0
                    opacity: modelData.opacity === undefined ? 1 : modelData.opacity
                    color: modelData.accent
                        ? Qt.alpha(Theme.primary, root.selected ? 0.78 : 0.34)
                        : Qt.alpha(Theme.surfaceText, root.hovered ? 0.18 : 0.12)
                    border.color: modelData.accent
                        ? Qt.alpha(Theme.primary, root.selected ? 0.95 : 0.55)
                        : Qt.alpha(Theme.outline, 0.5)
                    border.width: 1
                }
            }
        }
    }
}
