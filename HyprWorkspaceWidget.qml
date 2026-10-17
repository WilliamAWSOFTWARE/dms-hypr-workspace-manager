import QtQuick
import Quickshell.Io
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
    readonly property string monitorName: currentState && currentState.monitor ? String(currentState.monitor) : (root.parentScreen && root.parentScreen.name ? String(root.parentScreen.name) : "")
    readonly property string workspaceName: currentState && currentState.workspaceName ? String(currentState.workspaceName) : "1"

    popoutWidth: 560
    popoutHeight: 460

    pillRightClickAction: function () {
        root.toggleRightClickLayout();
    }

    Component.onCompleted: {
        refreshCurrentLayout();
    }

    Timer {
        id: statePollTimer
        interval: 2000
        repeat: true
        running: true
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
        queryProcess.command = ["python3", root.scriptPath, "get"];
        queryProcess.running = true;
    }

    function setLayout(layoutId) {
        if (!layoutId) return;
        pendingLayoutId = layoutId;
        lastError = "";
        recordLayoutTransition(layoutId);

        setProcess.command = ["python3", root.scriptPath, "set", layoutId];
        setProcess.running = true;
    }

    function runQuickAction(actionName) {
        if (actionProcess.running) return;
        actionProcess.command = ["python3", root.scriptPath, "action", actionName];
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
            return stored
                .filter(entry => entry && entry.id && entry.enabled !== false)
                .map(entry => LayoutPreviewData.findOption(entry.id))
                .filter(option => option);
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
        const cooldown = Number(loadPluginValue("scrollSpeed", 250));
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
                    if (parsed.currentLayout) {
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
                root.queryBuffer += data;
            }
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0 && root.queryBuffer.trim().length > 0) {
                try {
                    const parsed = JSON.parse(root.queryBuffer.trim());
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
            root.queryBuffer = "";
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
                                text: `Active: ${root.currentLayoutLabel} · Workspace ${root.workspaceName}${root.monitorName ? " (" + root.monitorName + ")" : ""}`
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

                // 3-Column Layout Grid
                DankFlickable {
                    width: parent.width
                    height: Math.min(buttonGrid.implicitHeight + Theme.spacingM * 2, root.parentScreen ? root.parentScreen.height * 0.75 : 700)
                    clip: true
                    contentWidth: width
                    contentHeight: buttonGrid.implicitHeight + Theme.spacingM * 2

                    Grid {
                        id: buttonGrid
                        x: Theme.spacingM
                        y: Theme.spacingM
                        width: parent.width - Theme.spacingM * 2 - 12
                        columns: 3
                        spacing: Theme.spacingS

                        Repeater {
                            model: root.layoutOptions

                            delegate: HyprLayoutTile {
                                required property var modelData
                                width: (buttonGrid.width - buttonGrid.spacing * (buttonGrid.columns - 1)) / buttonGrid.columns
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
                    width: parent.width
                    implicitHeight: actionRow.implicitHeight + Theme.spacingS * 2
                    radius: Theme.cornerRadius
                    color: Theme.surfaceContainerHigh
                    border.color: Qt.alpha(Theme.outline, 0.5)
                    border.width: 1

                    Row {
                        id: actionRow
                        anchors.centerIn: parent
                        spacing: Theme.spacingM

                        // Float toggle
                        Rectangle {
                            implicitWidth: 100
                            implicitHeight: 34
                            radius: Theme.cornerRadius - 2
                            color: root.currentState && root.currentState.isFloating ? Qt.alpha(Theme.primary, 0.2) : Theme.surfaceContainer
                            border.color: root.currentState && root.currentState.isFloating ? Theme.primary : Theme.outline
                            border.width: 1

                            Row {
                                anchors.centerIn: parent
                                spacing: 6
                                DankIcon {
                                    name: "web_asset"
                                    size: 16
                                    color: root.currentState && root.currentState.isFloating ? Theme.primary : Theme.surfaceText
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                StyledText {
                                    text: "Float"
                                    color: Theme.surfaceText
                                    font.pixelSize: Theme.fontSizeSmall - 1
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.runQuickAction("toggle_floating")
                            }
                        }

                        // Fullscreen / Monocle toggle
                        Rectangle {
                            implicitWidth: 110
                            implicitHeight: 34
                            radius: Theme.cornerRadius - 2
                            color: root.currentState && root.currentState.isFullscreen ? Qt.alpha(Theme.primary, 0.2) : Theme.surfaceContainer
                            border.color: root.currentState && root.currentState.isFullscreen ? Theme.primary : Theme.outline
                            border.width: 1

                            Row {
                                anchors.centerIn: parent
                                spacing: 6
                                DankIcon {
                                    name: "fullscreen"
                                    size: 16
                                    color: root.currentState && root.currentState.isFullscreen ? Theme.primary : Theme.surfaceText
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                StyledText {
                                    text: "Fullscreen"
                                    color: Theme.surfaceText
                                    font.pixelSize: Theme.fontSizeSmall - 1
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.runQuickAction("toggle_fullscreen")
                            }
                        }

                        // Group / Deck toggle
                        Rectangle {
                            implicitWidth: 100
                            implicitHeight: 34
                            radius: Theme.cornerRadius - 2
                            color: root.currentState && root.currentState.isGrouped ? Qt.alpha(Theme.primary, 0.2) : Theme.surfaceContainer
                            border.color: root.currentState && root.currentState.isGrouped ? Theme.primary : Theme.outline
                            border.width: 1

                            Row {
                                anchors.centerIn: parent
                                spacing: 6
                                DankIcon {
                                    name: "layers"
                                    size: 16
                                    color: root.currentState && root.currentState.isGrouped ? Theme.primary : Theme.surfaceText
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                StyledText {
                                    text: "Group"
                                    color: Theme.surfaceText
                                    font.pixelSize: Theme.fontSizeSmall - 1
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.runQuickAction("toggle_group")
                            }
                        }

                        // Split toggle (Dwindle)
                        Rectangle {
                            implicitWidth: 100
                            implicitHeight: 34
                            radius: Theme.cornerRadius - 2
                            color: Theme.surfaceContainer
                            border.color: Theme.outline
                            border.width: 1

                            Row {
                                anchors.centerIn: parent
                                spacing: 6
                                DankIcon {
                                    name: "alt_route"
                                    size: 16
                                    color: Theme.surfaceText
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                StyledText {
                                    text: "Split"
                                    color: Theme.surfaceText
                                    font.pixelSize: Theme.fontSizeSmall - 1
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.runQuickAction("toggle_split")
                            }
                        }
                    }
                }
            }
        }
    }
}
