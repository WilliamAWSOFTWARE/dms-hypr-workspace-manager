import QtQuick
import qs.Common
import qs.Widgets
import qs.Modules.Plugins
import "LayoutPreviewData.js" as LayoutPreviewData

PluginSettings {
    id: root
    pluginId: "hyprWorkspaceManager"

    StyledText {
        width: parent.width
        text: "Hyprland Layout Manager"
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Bold
        color: Theme.surfaceText
    }

    SelectionSetting {
        settingKey: "rightClickTarget"
        label: "Right-click toggle target"
        description: "Right-clicking the bar widget switches to this layout, or back to the previous one if it's already active. Choose None to disable."
        options: [{
                value: "",
                label: "None"
            }].concat(LayoutPreviewData.options().map(option => ({
                value: option.id,
                label: option.label
            })))
        defaultValue: "monocle"
    }

    SelectionSetting {
        settingKey: "middleClickTarget"
        label: "Middle-click toggle target"
        description: "Middle-clicking the bar widget switches to this layout, or back to the previous one if it's already active. Choose None to disable."
        options: [{
                value: "",
                label: "None"
            }].concat(LayoutPreviewData.options().map(option => ({
                value: option.id,
                label: option.label
            })))
        defaultValue: "center_tile"
    }

    ListSetting {
        id: scrollList
        settingKey: "scrollCycleLayouts"
        label: "Scroll cycle"
        description: "Layouts the scroll wheel (or two-finger swipe) cycles through on the bar widget, in this order. Use the eye to include or exclude a layout, and the handle to reorder."
        defaultValue: LayoutPreviewData.options().map(option => ({
                id: option.id,
                label: option.label,
                enabled: true
            }))

        function moveItem(index, delta) {
            const newIndex = Math.max(0, Math.min(scrollList.items.length - 1, index + delta));
            if (newIndex === index) {
                return;
            }
            const reordered = scrollList.items.slice();
            const moved = reordered.splice(index, 1)[0];
            reordered.splice(newIndex, 0, moved);
            scrollList.items = reordered;
        }

        function toggleItemEnabled(index) {
            const updated = scrollList.items.slice();
            updated[index] = Object.assign({}, updated[index], {
                enabled: !updated[index].enabled
            });
            scrollList.items = updated;
        }

        delegate: Component {
            StyledRect {
                id: row
                required property var modelData
                required property int index

                width: parent.width
                height: 40
                radius: Theme.cornerRadius
                color: Theme.withAlpha(Theme.surfaceContainerHigh, Theme.popupTransparency)
                border.width: 0

                property real dragOffsetY: 0
                z: dragArea.pressed ? 2 : 0
                transform: Translate {
                    y: row.dragOffsetY
                }
                Behavior on dragOffsetY {
                    enabled: !dragArea.pressed
                    NumberAnimation {
                        duration: Theme.shortDuration
                        easing.type: Easing.OutCubic
                    }
                }

                Behavior on y {
                    NumberAnimation {
                        duration: Theme.shortDuration
                        easing.type: Easing.OutCubic
                    }
                }

                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: Theme.spacingM
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Theme.spacingS

                    DankIcon {
                        name: row.modelData.enabled ? "visibility" : "visibility_off"
                        size: Theme.iconSize - 6
                        color: row.modelData.enabled ? Theme.primary : Theme.outline
                        anchors.verticalCenter: parent.verticalCenter

                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -6
                            cursorShape: Qt.PointingHandCursor
                            onClicked: scrollList.toggleItemEnabled(row.index)
                        }
                    }

                    StyledText {
                        text: row.modelData.label
                        color: row.modelData.enabled ? Theme.surfaceText : Theme.surfaceVariantText
                        font.pixelSize: Theme.fontSizeSmall
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                Item {
                    id: dragHandle
                    anchors.right: parent.right
                    anchors.rightMargin: Theme.spacingM
                    anchors.verticalCenter: parent.verticalCenter
                    width: 24
                    height: 24

                    readonly property real slotHeight: row.height + Theme.spacingS

                    DankIcon {
                        name: "drag_indicator"
                        size: Theme.iconSize - 4
                        color: dragArea.pressed ? Theme.primary : Theme.outline
                        anchors.centerIn: parent
                    }

                    MouseArea {
                        id: dragArea
                        anchors.fill: parent
                        preventStealing: true
                        cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor

                        property real pressY: 0
                        property int pressIndex: 0
                        property int pendingSteps: 0

                        onPressed: mouse => {
                            pressY = mapToItem(scrollList, mouse.x, mouse.y).y;
                            pressIndex = row.index;
                            pendingSteps = 0;
                        }
                        onPositionChanged: mouse => {
                            if (!pressed) return;
                            const totalDelta = mapToItem(scrollList, mouse.x, mouse.y).y - pressY;
                            pendingSteps = Math.trunc(totalDelta / dragHandle.slotHeight);
                            row.dragOffsetY = totalDelta;
                        }
                        onReleased: {
                            if (pendingSteps !== 0) {
                                scrollList.moveItem(pressIndex, pendingSteps);
                            }
                            pendingSteps = 0;
                            row.dragOffsetY = 0;
                        }
                    }
                }
            }
        }
    }

    SliderSetting {
        settingKey: "scrollSpeed"
        label: "Scroll speed"
        description: "Minimum time between layout changes while scrolling or swiping the bar widget. Raise this if a trackpad swipe jumps through several layouts at once; lower it for a snappier response with a mouse wheel."
        defaultValue: 250
        minimum: 100
        maximum: 1000
        unit: "ms"
        leftIcon: "speed"
    }
}
