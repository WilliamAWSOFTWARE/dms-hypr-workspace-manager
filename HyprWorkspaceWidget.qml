import QtQuick
import QtQuick.Controls
import Quickshell.Io
import Quickshell.Hyprland
import qs.Common
import qs.Widgets
import qs.Modules.Plugins
import "LayoutPreviewData.js" as LayoutPreviewData

PluginComponent {
    id: root

    readonly property string scriptPath: {
        const urlStr = Qt.resolvedUrl("./hypr_layout.py").toString();
        return urlStr.replace(/^file:\/\//, "");
    }

    readonly property real pillHorizontalPadding: Theme.spacingXS
    property string currentLayoutRaw: "dwindle"
    property string previousLayoutRaw: ""
    property string lastError: ""
    property string queryBuffer: ""
    property string setBuffer: ""
    property string pendingLayoutId: ""
    property bool hyprAvailable: true
    readonly property string rightClickFallbackId: "monocle"
    readonly property string middleClickFallbackId: "center_tile"
    property real lastScrollCycleTime: 0

    property var currentState: null
    readonly property string currentLayoutCode: currentState && currentState.layoutCode ? currentState.layoutCode : (currentLayoutOption ? currentLayoutOption.code : "DW")
    readonly property string currentLayoutIcon: currentState && currentState.layoutIcon ? currentState.layoutIcon : (currentLayoutOption ? currentLayoutOption.icon : "account_tree")
    readonly property string currentLayoutLabel: currentState && currentState.layoutLabel ? currentState.layoutLabel : (currentLayoutOption ? currentLayoutOption.label : "Dwindle")
    readonly property var currentLayoutOption: LayoutPreviewData.findOption(currentLayoutRaw)
    readonly property bool busy: queryProcess.running || setProcess.running

    property var layoutOptions: root.visibleLayoutOptions()
    readonly property bool isUltrawide: root.parentScreen ? (root.parentScreen.width >= 2400) : false
    readonly property int gridColumns: isUltrawide ? 4 : 3
    readonly property string monitorName: root.parentScreen && root.parentScreen.name ? String(root.parentScreen.name) : (currentState && currentState.monitor ? String(currentState.monitor) : "")
    readonly property string workspaceName: currentState && currentState.workspaceName ? String(currentState.workspaceName) : "1"

    popoutWidth: isUltrawide ? (Theme.spacingM * 38) : (Theme.spacingM * 34)
    popoutHeight: Math.min(Theme.spacingM * 32, root.parentScreen ? Math.round(root.parentScreen.height * 0.65) : (Theme.spacingM * 32))

    onMonitorNameChanged: {
        root.refreshCurrentLayout();
    }

    pillRightClickAction: function () {
        root.toggleRightClickLayout();
    }

    Component.onCompleted: {
        refreshCurrentLayout();
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (!event || !event.name) return;
            const evName = event.name;
            if (evName === "workspace" || evName === "workspacev2" || 
                evName === "changefloatingmode" || evName === "fullscreen" || 
                evName === "configreloaded") {
                eventDebounceTimer.restart();
            }
        }
    }

    Timer {
        id: eventDebounceTimer
        interval: 150
        repeat: false
        onTriggered: {
            if (!root.busy) {
                root.refreshCurrentLayout();
            }
        }
    }

    function loadPluginValue(key, defaultValue) {
        if (root.pluginService && root.pluginService.loadPluginData) {
            return root.pluginService.loadPluginData(root.pluginId, key, defaultValue);
        }
        return defaultValue;
    }

    function refreshCurrentLayout() {
        if (queryProcess.running) return;
        queryBuffer = "";
        queryProcess.command = ["python3", root.scriptPath, "get", root.monitorName];
        queryProcess.running = true;
    }

    function setLayout(layoutId) {
        if (!layoutId) return;
        if (setProcess.running) {
            pendingLayoutId = layoutId;
            return;
        }
        pendingLayoutId = layoutId;
        lastError = "";
        recordLayoutTransition(layoutId);

        setBuffer = "";
        setProcess.command = ["python3", root.scriptPath, "set", layoutId, root.monitorName];
        setProcess.running = true;
    }

    function runQuickAction(actionName) {
        if (actionProcess.running) return;
        actionProcess.command = ["python3", root.scriptPath, "action", actionName, root.monitorName];
        actionProcess.running = true;
    }

    function recordLayoutTransition(newLayoutId) {
        if (newLayoutId && newLayoutId !== currentLayoutRaw && currentLayoutRaw) {
            previousLayoutRaw = currentLayoutRaw;
        }
        currentLayoutRaw = newLayoutId;
    }

    function isCurrentLayout(layoutId) {
        if (!layoutId) return false;
        if (currentLayoutRaw.toLowerCase() === layoutId.toLowerCase()) return true;
        const opt = LayoutPreviewData.findOption(currentLayoutRaw);
        return opt && opt.id.toLowerCase() === layoutId.toLowerCase();
    }

    function toggleConfiguredLayout(settingKey, fallbackId) {
        const targetId = String(loadPluginValue(settingKey, fallbackId)).trim();
        if (!targetId || targetId === "none") return;

        if (isCurrentLayout(targetId)) {
            const returnId = previousLayoutRaw ? previousLayoutRaw : (targetId !== fallbackId ? fallbackId : "dwindle");
            if (returnId) setLayout(returnId);
            return;
        }

        setLayout(targetId);
    }

    function toggleRightClickLayout() {
        root.toggleConfiguredLayout("rightClickTarget", root.rightClickFallbackId);
    }

    function toggleMiddleClickLayout() {
        root.toggleConfiguredLayout("middleClickTarget", root.middleClickFallbackId);
    }

    function visibleLayoutOptions() {
        const stored = loadPluginValue("scrollCycleLayouts", null);
        if (Array.isArray(stored) && stored.length > 0) {
            var knownIds = {};
            for (var k = 0; k < stored.length; k++) {
                if (stored[k] && stored[k].id) knownIds[stored[k].id] = true;
            }
            var list = stored
                .filter(function(entry) { return entry && entry.id && entry.enabled !== false; })
                .map(function(entry) { return LayoutPreviewData.findOption(entry.id); })
                .filter(function(option) { return option !== null && option !== undefined; });
            var allOpts = LayoutPreviewData.options();
            for (var i = 0; i < allOpts.length; i++) {
                if (!knownIds[allOpts[i].id]) {
                    list.push(allOpts[i]);
                }
            }
            return list.length > 0 ? list : LayoutPreviewData.options();
        }
        return LayoutPreviewData.options();
    }

    function cycleLayout(direction) {
        const ids = root.visibleLayoutOptions().map(opt => opt.id);
        if (ids.length === 0) return;

        const currentOpt = LayoutPreviewData.findOption(root.currentLayoutRaw);
        const currentId = currentOpt ? currentOpt.id : ids[0];
        let index = ids.indexOf(currentId);
        if (index === -1) index = 0;

        let nextIndex = index + direction;
        if (nextIndex >= ids.length) nextIndex = 0;
        if (nextIndex < 0) nextIndex = ids.length - 1;

        setLayout(ids[nextIndex]);
    }

    function handleScroll(direction) {
        const cooldown = Math.max(100, Number(loadPluginValue("scrollSpeed", loadPluginValue("scrollCooldownMs", 250))));
        const now = Date.now();
        if (now - root.lastScrollCycleTime < cooldown) return;
        root.lastScrollCycleTime = now;
        root.cycleLayout(direction);
    }

    // Backend process to get state
    Process {
        id: queryProcess
        stdout: SplitParser {
            onRead: data => {
                root.queryBuffer += data;
            }
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0 && root.queryBuffer.trim().length > 0) {
                try {
                    const parsed = JSON.parse(root.queryBuffer.trim());
                    root.currentState = parsed;
                    if (parsed.currentLayout && !setProcess.running && !root.pendingLayoutId) {
                        root.recordLayoutTransition(parsed.currentLayout);
                    }
                    root.hyprAvailable = true;
                    root.lastError = "";
                } catch (e) {
                    root.lastError = "Failed to parse Hyprland state JSON";
                }
            } else if (exitCode !== 0) {
                root.hyprAvailable = false;
                root.lastError = "Failed to query Hyprland state (hyprctl error)";
            }
            root.queryBuffer = "";
        }
    }

    // Backend process to set layout
    Process {
        id: setProcess
        stdout: SplitParser {
            onRead: data => {
                root.setBuffer += data;
            }
        }
        onExited: (exitCode, exitStatus) => {
            const nextToApply = root.pendingLayoutId;
            root.pendingLayoutId = "";

            if (exitCode === 0 && root.setBuffer.trim().length > 0) {
                try {
                    const parsed = JSON.parse(root.setBuffer.trim());
                    root.currentState = parsed;
                    if (parsed.currentLayout) {
                        root.recordLayoutTransition(parsed.currentLayout);
                    }
                    root.hyprAvailable = true;
                    root.lastError = "";
                } catch (e) {
                    root.refreshCurrentLayout();
                }
            } else if (exitCode !== 0) {
                root.lastError = "Failed to apply layout in Hyprland";
                root.refreshCurrentLayout();
            }
            root.setBuffer = "";

            if (nextToApply && nextToApply !== root.currentLayoutRaw) {
                root.setLayout(nextToApply);
            }
        }
    }

    // Backend process for quick actions
    Process {
        id: actionProcess
        onExited: (exitCode, exitStatus) => {
            root.refreshCurrentLayout();
        }
    }

    // Horizontal Pill on the DankBar
    horizontalBarPill: Component {
        HyprWorkspacePill {
            anchors.fill: parent
            available: root.hyprAvailable
            code: root.currentLayoutCode
            label: root.currentLayoutLabel
            iconName: root.currentLayoutIcon
            widgetThickness: root.widgetThickness
            horizontalPadding: root.pillHorizontalPadding
            onScrollRequested: direction => root.handleScroll(direction)
            onMiddleClickRequested: root.toggleMiddleClickLayout()
        }
    }

    // Vertical Pill on the DankBar
    verticalBarPill: Component {
        HyprWorkspacePill {
            anchors.fill: parent
            vertical: true
            available: root.hyprAvailable
            code: root.currentLayoutCode
            label: root.currentLayoutLabel
            iconName: root.currentLayoutIcon
            widgetThickness: root.widgetThickness
            onScrollRequested: direction => root.handleScroll(direction)
            onMiddleClickRequested: root.toggleMiddleClickLayout()
        }
    }

    // Popout Content using PopoutComponent
    popoutContent: Component {
        PopoutComponent {
            id: chooser
            headerText: ""
            detailsText: ""
            showCloseButton: true

            Connections {
                target: chooser.parentPopout
                function onOpened() {
                    root.refreshCurrentLayout();
                    root.layoutOptions = root.visibleLayoutOptions();
                }
            }

            Column {
                width: parent.width
                spacing: Theme.spacingM

                // Header
                Item {
                    id: headerItem
                    width: parent.width
                    implicitHeight: titleRow.implicitHeight

                    Row {
                        id: titleRow
                        anchors.centerIn: parent
                        spacing: Theme.spacingS

                        DankIcon {
                            name: root.currentLayoutIcon
                            size: Theme.iconSize - 2
                            color: Theme.primary
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 1

                            StyledText {
                                text: "Hyprland Layout Manager"
                                color: Theme.surfaceText
                                font.pixelSize: Theme.fontSizeLarge
                                font.weight: Font.DemiBold
                            }

                            StyledText {
                                text: `Global Layout: ${root.currentLayoutLabel}${root.monitorName ? " · " + root.monitorName : ""}`
                                color: Theme.surfaceVariantText
                                font.pixelSize: Theme.fontSizeSmall - 2
                            }
                        }
                    }
                }

                // Error alert box (if any)
                Rectangle {
                    visible: root.lastError !== ""
                    width: parent.width
                    implicitHeight: visible ? errText.implicitHeight + Theme.spacingM * 2 : 0
                    radius: Theme.cornerRadius
                    color: Theme.surfaceContainerHigh
                    border.color: Theme.error
                    border.width: 1

                    StyledText {
                        id: errText
                        anchors.fill: parent
                        anchors.margins: Theme.spacingM
                        text: root.lastError
                        color: Theme.error
                        font.pixelSize: Theme.fontSizeSmall
                        wrapMode: Text.WordWrap
                    }
                }

                // Layout Grid (dynamic 3 or 4 columns based on screen width, bounded flickable)
                DankFlickable {
                    id: gridFlickable
                    width: parent.width
                    height: Math.min(buttonGrid.implicitHeight + Theme.spacingS * 2, Math.max(260, root.popoutHeight - headerItem.implicitHeight - actionRowBox.implicitHeight - Theme.spacingM * 3))
                    clip: true
                    contentWidth: width
                    contentHeight: buttonGrid.implicitHeight + Theme.spacingS * 2

                    ScrollBar.vertical: ScrollBar {
                        id: vScrollBar
                        policy: gridFlickable.contentHeight > gridFlickable.height ? ScrollBar.AlwaysOn : ScrollBar.AsNeeded
                        visible: gridFlickable.contentHeight > gridFlickable.height
                        width: 6
                        minimumSize: 0.1
                        opacity: (hovered || pressed || active) ? 1.0 : 0.6
                        Behavior on opacity {
                            NumberAnimation {
                                duration: Theme.shortDuration
                            }
                        }
                        contentItem: Rectangle {
                            radius: width / 2
                            color: Theme.primary
                            opacity: vScrollBar.pressed ? 0.9 : (vScrollBar.hovered ? 0.75 : 0.5)
                        }
                        background: Rectangle {
                            radius: width / 2
                            color: Theme.surfaceContainerHighest
                            opacity: 0.3
                        }
                    }

                    WheelHandler {
                        target: gridFlickable
                        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                        onWheel: event => {
                            const step = 60;
                            const delta = event.angleDelta.y !== 0 ? event.angleDelta.y : event.angleDelta.x;
                            if (delta === 0) return;
                            const newY = gridFlickable.contentY - (delta > 0 ? step : -step);
                            gridFlickable.contentY = Math.max(0, Math.min(newY, Math.max(0, gridFlickable.contentHeight - gridFlickable.height)));
                            event.accepted = true;
                        }
                    }

                    Grid {
                        id: buttonGrid
                        x: Theme.spacingM
                        y: Theme.spacingS
                        width: parent.width - Theme.spacingM * 2 - (vScrollBar.visible ? Theme.spacingM : Theme.spacingS)
                        columns: root.gridColumns
                        spacing: Theme.spacingS

                        Repeater {
                            model: root.layoutOptions

                            delegate: HyprLayoutTile {
                                required property var modelData
                                width: Math.floor((buttonGrid.width - buttonGrid.spacing * (buttonGrid.columns - 1)) / buttonGrid.columns)
                                layout: modelData
                                selected: root.isCurrentLayout(modelData.id)
                                busy: root.busy
                                onLayoutSelected: layoutId => root.setLayout(layoutId)
                            }
                        }
                    }
                }

                // Quick Action Bar
                Rectangle {
                    id: actionRowBox
                    width: parent.width
                    implicitHeight: actionRow.implicitHeight + Theme.spacingS * 2
                    radius: Theme.cornerRadius
                    color: Theme.surfaceContainerHigh
                    border.color: Qt.alpha(Theme.outline, 0.5)
                    border.width: 1

                    Row {
                        id: actionRow
                        width: parent.width - Theme.spacingM * 2
                        anchors.centerIn: parent
                        spacing: Theme.spacingS

                        readonly property real buttonWidth: Math.floor((width - spacing * 3) / 4)

                        DankButton {
                            width: actionRow.buttonWidth
                            buttonHeight: Theme.buttonHeightS
                            radius: Theme.cornerRadius
                            iconName: "web_asset"
                            iconSize: Theme.iconSizeSmall
                            text: "Float"
                            backgroundColor: root.currentState && root.currentState.isFloating ? Theme.primaryContainer : Theme.surfaceContainerHigh
                            textColor: root.currentState && root.currentState.isFloating ? Theme.primary : Theme.surfaceText
                            onClicked: root.runQuickAction("toggle_floating")
                        }

                        DankButton {
                            width: actionRow.buttonWidth
                            buttonHeight: Theme.buttonHeightS
                            radius: Theme.cornerRadius
                            iconName: "fullscreen"
                            iconSize: Theme.iconSizeSmall
                            text: "Fullscreen"
                            backgroundColor: root.currentState && root.currentState.isFullscreen ? Theme.primaryContainer : Theme.surfaceContainerHigh
                            textColor: root.currentState && root.currentState.isFullscreen ? Theme.primary : Theme.surfaceText
                            onClicked: root.runQuickAction("toggle_fullscreen")
                        }

                        DankButton {
                            width: actionRow.buttonWidth
                            buttonHeight: Theme.buttonHeightS
                            radius: Theme.cornerRadius
                            iconName: "layers"
                            iconSize: Theme.iconSizeSmall
                            text: "Group"
                            backgroundColor: root.currentState && root.currentState.isGrouped ? Theme.primaryContainer : Theme.surfaceContainerHigh
                            textColor: root.currentState && root.currentState.isGrouped ? Theme.primary : Theme.surfaceText
                            onClicked: root.runQuickAction("toggle_group")
                        }

                        DankButton {
                            width: actionRow.buttonWidth
                            buttonHeight: Theme.buttonHeightS
                            radius: Theme.cornerRadius
                            iconName: "alt_route"
                            iconSize: Theme.iconSizeSmall
                            text: "Split"
                            backgroundColor: Theme.surfaceContainerHigh
                            textColor: Theme.surfaceText
                            onClicked: root.runQuickAction("toggle_split")
                        }
                    }
                }
            }
        }
    }
}
