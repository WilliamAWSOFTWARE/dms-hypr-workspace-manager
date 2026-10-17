import QtQuick
import Quickshell.Io
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PluginComponent {
    id: root

    readonly property string scriptPath: {
        const urlStr = Qt.resolvedUrl("./hypr_state.py").toString();
        return urlStr.replace(/^file:\/\//, "");
    }

    property var hyprState: null
    property bool hyprAvailable: true
    property string queryBuffer: ""
    property real lastScrollTime: 0
    property bool popoutIsOpen: false
    property int activeFilterIndex: 0 // 0: Current WS, 1: All Windows, 2: Scratchpad

    // Derived properties for the bar pill
    readonly property string currentWorkspaceName: hyprState && hyprState.activeWorkspace ? String(hyprState.activeWorkspace.name) : "1"
    readonly property string currentWindowTitle: hyprState && hyprState.activeWindow ? String(hyprState.activeWindow.title) : ""
    readonly property string currentWindowClass: hyprState && hyprState.activeWindow ? String(hyprState.activeWindow.class) : ""
    readonly property int currentWindowCount: hyprState && hyprState.activeWorkspace ? Number(hyprState.activeWorkspace.windowsCount) : 0
    readonly property bool currentIsFloating: hyprState && hyprState.activeWindow ? Boolean(hyprState.activeWindow.floating) : false
    readonly property bool currentIsFullscreen: hyprState && hyprState.activeWindow ? Boolean(hyprState.activeWindow.fullscreen) : false
    readonly property bool currentIsPinned: hyprState && hyprState.activeWindow ? Boolean(hyprState.activeWindow.pinned) : false
    readonly property string currentLayout: hyprState && hyprState.activeWorkspace ? String(hyprState.activeWorkspace.tiledLayout) : "dwindle"

    readonly property var activeWs: hyprState && hyprState.activeWorkspace ? hyprState.activeWorkspace : ({ id: 1, name: "1", tiledLayout: "dwindle" })
    readonly property var workspacesList: hyprState && hyprState.workspaces ? hyprState.workspaces : []
    readonly property var allClients: hyprState && hyprState.clients ? hyprState.clients : []
    readonly property var activeWin: hyprState && hyprState.activeWindow ? hyprState.activeWindow : ({})
    readonly property int scratchpadCount: hyprState ? Number(hyprState.scratchpadCount) : 0

    readonly property var filteredClients: {
        if (!allClients || allClients.length === 0) return [];
        if (root.activeFilterIndex === 0) {
            const curId = activeWs.id;
            return allClients.filter(c => c.workspaceId === curId && !String(c.workspaceName).toLowerCase().includes("special"));
        } else if (root.activeFilterIndex === 1) {
            return allClients.filter(c => !String(c.workspaceName).toLowerCase().includes("special"));
        } else {
            return allClients.filter(c => String(c.workspaceName).toLowerCase().includes("special"));
        }
    }

    readonly property bool busy: queryProcess.running || dispatchProcess.running

    popoutWidth: 680
    popoutHeight: 560

    pillRightClickAction: function() {
        root.executeConfiguredAction("rightClickAction", "scratchpad");
    }

    Component.onCompleted: {
        refreshState();
    }

    function loadPluginValue(key, defaultValue) {
        if (root.pluginService && root.pluginService.loadPluginData) {
            return root.pluginService.loadPluginData(root.pluginId, key, defaultValue);
        }
        return defaultValue;
    }

    function refreshState() {
        if (queryProcess.running) return;
        queryBuffer = "";
        queryProcess.command = ["python3", root.scriptPath];
        queryProcess.running = true;
    }

    function dispatchCommand(dispatcher, args) {
        if (dispatchProcess.running) return;
        const cmd = ["hyprctl", "dispatch", dispatcher];
        if (args !== undefined && args !== null && String(args).length > 0) {
            cmd.push(String(args));
        }
        dispatchProcess.command = cmd;
        dispatchProcess.running = true;
    }

    function switchWorkspace(workspaceId) {
        dispatchCommand("workspace", workspaceId);
    }

    function cycleWorkspace(direction) {
        const cooldown = loadPluginValue("scrollCooldownMs", 300);
        const now = Date.now();
        if (now - root.lastScrollTime < cooldown) return;
        root.lastScrollTime = now;
        dispatchCommand("workspace", direction > 0 ? "e+1" : "e-1");
    }

    function moveActiveToWorkspace(workspaceId) {
        const silent = loadPluginValue("silentMove", true);
        dispatchCommand(silent ? "movetoworkspacesilent" : "movetoworkspace", workspaceId);
    }

    function moveWindowToWorkspace(address, target) {
        const silent = loadPluginValue("silentMove", true);
        const action = silent ? "movetoworkspacesilent" : "movetoworkspace";
        dispatchCommand(action, String(target) + ",address:" + address);
    }

    function focusWindow(address) {
        dispatchCommand("focuswindow", "address:" + address);
        root.closePopout();
    }

    function toggleFloating(address) {
        dispatchCommand("togglefloating", address ? "address:" + address : "");
    }

    function toggleFullscreen(address) {
        dispatchCommand("fullscreen", "1");
    }

    function togglePin(address) {
        dispatchCommand("pin", address ? "address:" + address : "");
    }

    function closeWindow(address) {
        dispatchCommand("closewindow", "address:" + address);
    }

    function toggleSplit() {
        dispatchCommand("layoutmsg", "togglesplit");
    }

    function swapWindow(direction) {
        dispatchCommand("swapwindow", direction);
    }

    function toggleScratchpad() {
        dispatchCommand("togglespecialworkspace", "scratchpad");
    }

    function executeConfiguredAction(settingKey, fallbackAction) {
        const action = loadPluginValue(settingKey, fallbackAction);
        if (action === "scratchpad") {
            root.toggleScratchpad();
        } else if (action === "togglefloating") {
            root.toggleFloating("");
        } else if (action === "togglesplit") {
            root.toggleSplit();
        } else if (action === "fullscreen") {
            root.toggleFullscreen("");
        } else if (action === "next_workspace") {
            root.cycleWorkspace(1);
        }
    }

    // State Polling Timer
    Timer {
        id: pollTimer
        interval: root.popoutIsOpen ? 400 : 1200
        repeat: true
        running: true
        onTriggered: root.refreshState()
    }

    // Process to query Hyprland state
    Process {
        id: queryProcess
        command: ["python3", root.scriptPath]
        running: false

        stdout: SplitParser {
            onRead: data => {
                root.queryBuffer += (root.queryBuffer ? "\n" : "") + data;
            }
        }

        onExited: exitCode => {
            if (exitCode === 0 && root.queryBuffer.length > 0) {
                try {
                    root.hyprState = JSON.parse(root.queryBuffer);
                    root.hyprAvailable = true;
                } catch (e) {
                    // Ignore parse errors
                }
            } else if (exitCode !== 0) {
                root.hyprAvailable = false;
            }
        }
    }

    // Process to dispatch Hyprland actions
    Process {
        id: dispatchProcess
        command: ["hyprctl", "dispatch", ""]
        running: false

        onExited: exitCode => {
            Qt.callLater(root.refreshState);
        }
    }

    // Horizontal Bar Pill (Top/Bottom DankBar)
    horizontalBarPill: Component {
        HyprWorkspacePill {
            available: root.hyprAvailable
            workspaceName: root.currentWorkspaceName
            activeTitle: root.loadPluginValue("showTitleInPill", true) ? root.currentWindowTitle : ""
            activeClass: root.loadPluginValue("showTitleInPill", true) ? root.currentWindowClass : ""
            windowCount: root.currentWindowCount
            isFloating: root.currentIsFloating
            isFullscreen: root.currentIsFullscreen
            isPinned: root.currentIsPinned
            layoutName: root.currentLayout
            widgetThickness: root.widgetThickness
            maxTitleLength: root.loadPluginValue("maxTitleLength", 22)

            onScrollRequested: function(direction) { root.cycleWorkspace(direction); }
            onMiddleClickRequested: function() { root.executeConfiguredAction("middleClickAction", "togglesplit"); }
            onRightClickRequested: function() { root.executeConfiguredAction("rightClickAction", "scratchpad"); }
        }
    }

    // Vertical Bar Pill (Side DankBar)
    verticalBarPill: Component {
        HyprWorkspacePill {
            vertical: true
            available: root.hyprAvailable
            workspaceName: root.currentWorkspaceName
            windowCount: root.currentWindowCount
            widgetThickness: root.widgetThickness

            onScrollRequested: function(direction) { root.cycleWorkspace(direction); }
            onMiddleClickRequested: function() { root.executeConfiguredAction("middleClickAction", "togglesplit"); }
            onRightClickRequested: function() { root.executeConfiguredAction("rightClickAction", "scratchpad"); }
        }
    }

    // Popout Dashboard
    popoutContent: Component {
        PopoutComponent {
            id: popoutView
            headerText: ""
            detailsText: ""
            showCloseButton: true

            Connections {
                target: popoutView.parentPopout
                function onOpened() {
                    root.popoutIsOpen = true;
                    root.refreshState();
                }
                function onClosed() {
                    root.popoutIsOpen = false;
                }
            }

            Column {
                width: parent.width
                spacing: Theme.spacingM

                // Title Header
                Row {
                    width: parent.width
                    spacing: Theme.spacingS

                    Rectangle {
                        width: 32
                        height: 32
                        radius: 8
                        color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.2)
                        anchors.verticalCenter: parent.verticalCenter

                        DankIcon {
                            name: "dashboard_customize"
                            size: 20
                            color: Theme.primary
                            anchors.centerIn: parent
                        }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2

                        StyledText {
                            text: "Hyprland Spaces & Windows"
                            color: Theme.surfaceText
                            font.pixelSize: Theme.fontSizeLarge
                            font.weight: Font.Bold
                        }

                        StyledText {
                            text: "Monitor: " + (root.activeWs.monitor || "Principal") + " • Espacio activo: " + root.activeWs.id + " • Layout: " + (root.activeWs.tiledLayout || "dwindle")
                            color: Theme.surfaceVariantText
                            font.pixelSize: Theme.fontSizeSmall
                        }
                    }

                    Item {
                        width: parent.width - 32 - Theme.spacingS - 350 - 32
                        height: 1
                    }

                    // Refresh Button
                    Rectangle {
                        width: 30
                        height: 30
                        radius: 15
                        color: refreshArea.containsMouse ? Theme.surfaceVariant : Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.3)
                        anchors.verticalCenter: parent.verticalCenter

                        DankIcon {
                            name: "refresh"
                            size: 16
                            color: Theme.surfaceText
                            anchors.centerIn: parent
                        }

                        MouseArea {
                            id: refreshArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.refreshState()
                        }
                    }
                }

                // Quick Tiling & Layout Controls Bar
                Rectangle {
                    width: parent.width
                    implicitHeight: layoutRow.implicitHeight + Theme.spacingS * 2
                    radius: Theme.cornerRadius
                    color: Theme.surfaceContainerHigh
                    border.color: Theme.outline
                    border.width: 1

                    Row {
                        id: layoutRow
                        anchors.fill: parent
                        anchors.margins: Theme.spacingS
                        spacing: Theme.spacingS

                        StyledText {
                            text: "Control rápido:"
                            color: Theme.surfaceVariantText
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        // Toggle Split (Dwindle)
                        Rectangle {
                            height: 28
                            width: splitText.implicitWidth + 24
                            radius: 6
                            color: splitArea.containsMouse ? Theme.primary : Theme.surfaceVariant
                            anchors.verticalCenter: parent.verticalCenter

                            Row {
                                anchors.centerIn: parent
                                spacing: 4
                                DankIcon {
                                    name: "call_split"
                                    size: 14
                                    color: splitArea.containsMouse ? Theme.surface : Theme.surfaceText
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                StyledText {
                                    id: splitText
                                    text: "Dividir (Split)"
                                    color: splitArea.containsMouse ? Theme.surface : Theme.surfaceText
                                    font.pixelSize: 11
                                    font.weight: Font.Medium
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            MouseArea {
                                id: splitArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                enabled: !root.busy
                                onClicked: root.toggleSplit()
                            }
                        }

                        // Toggle Scratchpad
                        Rectangle {
                            height: 28
                            width: scratchBtnText.implicitWidth + 24
                            radius: 6
                            color: scratchBtnArea.containsMouse ? Theme.secondary : (root.scratchpadCount > 0 ? Qt.rgba(Theme.secondary.r, Theme.secondary.g, Theme.secondary.b, 0.25) : Theme.surfaceVariant)
                            anchors.verticalCenter: parent.verticalCenter

                            Row {
                                anchors.centerIn: parent
                                spacing: 4
                                DankIcon {
                                    name: "star"
                                    size: 14
                                    color: scratchBtnArea.containsMouse ? Theme.surface : Theme.secondary
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                StyledText {
                                    id: scratchBtnText
                                    text: "Scratchpad (" + root.scratchpadCount + ")"
                                    color: scratchBtnArea.containsMouse ? Theme.surface : Theme.surfaceText
                                    font.pixelSize: 11
                                    font.weight: Font.Medium
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            MouseArea {
                                id: scratchBtnArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                enabled: !root.busy
                                onClicked: root.toggleScratchpad()
                            }
                        }

                        // Directional Swaps
                        StyledText {
                            text: "Swap:"
                            color: Theme.surfaceVariantText
                            font.pixelSize: 11
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 3

                            Repeater {
                                model: [
                                    { dir: "l", icon: "arrow_back" },
                                    { dir: "r", icon: "arrow_forward" },
                                    { dir: "u", icon: "arrow_upward" },
                                    { dir: "d", icon: "arrow_downward" }
                                ]

                                delegate: Rectangle {
                                    required property var modelData
                                    width: 26
                                    height: 26
                                    radius: 5
                                    color: swapArea.containsMouse ? Theme.primary : Theme.surfaceVariant

                                    DankIcon {
                                        name: modelData.icon
                                        size: 14
                                        color: swapArea.containsMouse ? Theme.surface : Theme.surfaceText
                                        anchors.centerIn: parent
                                    }

                                    MouseArea {
                                        id: swapArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        enabled: !root.busy
                                        onClicked: root.swapWindow(modelData.dir)
                                    }
                                }
                            }
                        }
                    }
                }

                // Section Title: Workspaces
                StyledText {
                    text: "ESPACIOS DE TRABAJO (Clic para cambiar • Flecha para enviar ventana actual)"
                    color: Theme.surfaceVariantText
                    font.pixelSize: 10
                    font.weight: Font.Bold
                    font.letterSpacing: 0.5
                }

                // 5x2 Workspaces Grid (1 to 10)
                Grid {
                    id: wsGrid
                    width: parent.width
                    columns: 5
                    spacing: Theme.spacingS

                    Repeater {
                        model: root.workspacesList.slice(0, 10)

                        delegate: HyprWorkspaceTile {
                            required property var modelData
                            width: (wsGrid.width - wsGrid.spacing * 4) / 5
                            workspaceData: modelData
                            busy: root.busy
                            onWorkspaceSelected: function(wsId) { root.switchWorkspace(wsId); }
                            onMoveActiveRequested: function(wsId) { root.moveActiveToWorkspace(wsId); }
                        }
                    }
                }

                // Section Title & Filter Tabs for Windows List
                Row {
                    width: parent.width
                    spacing: Theme.spacingS

                    StyledText {
                        text: "VENTANAS"
                        color: Theme.surfaceVariantText
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        font.letterSpacing: 0.5
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Item {
                        width: parent.width - 70 - filterTabsRow.implicitWidth
                        height: 1
                    }

                    // Tabs Row
                    Row {
                        id: filterTabsRow
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 4

                        Repeater {
                            model: [
                                { label: "En este espacio", count: (root.allClients ? root.allClients.filter(c => c.workspaceId === root.activeWs.id && !String(c.workspaceName).toLowerCase().includes("special")).length : 0) },
                                { label: "Todas", count: (root.allClients ? root.allClients.filter(c => !String(c.workspaceName).toLowerCase().includes("special")).length : 0) },
                                { label: "Scratchpad", count: root.scratchpadCount }
                            ]

                            delegate: Rectangle {
                                required property var modelData
                                required property int index
                                height: 24
                                width: tabText.implicitWidth + 14
                                radius: 6
                                color: root.activeFilterIndex === index ? Theme.primary : (tabArea.containsMouse ? Theme.surfaceVariant : Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.4))

                                StyledText {
                                    id: tabText
                                    anchors.centerIn: parent
                                    text: modelData.label + " (" + modelData.count + ")"
                                    color: root.activeFilterIndex === index ? Theme.surface : Theme.surfaceText
                                    font.pixelSize: 11
                                    font.weight: root.activeFilterIndex === index ? Font.Bold : Font.Normal
                                }

                                MouseArea {
                                    id: tabArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.activeFilterIndex = index
                                }
                            }
                        }
                    }
                }

                // Scrollable Windows List
                DankFlickable {
                    width: parent.width
                    height: 190
                    clip: true
                    contentWidth: width
                    contentHeight: winListColumn.implicitHeight + Theme.spacingS

                    Column {
                        id: winListColumn
                        width: parent.width
                        spacing: Theme.spacingS

                        StyledText {
                            visible: root.filteredClients.length === 0
                            width: parent.width
                            text: root.activeFilterIndex === 2 ? "No hay ventanas en el Scratchpad." : "No hay ventanas abiertas en este espacio."
                            color: Theme.surfaceVariantText
                            font.pixelSize: Theme.fontSizeSmall
                            font.italic: true
                            horizontalAlignment: Text.AlignHCenter
                            topPadding: 30
                        }

                        Repeater {
                            model: root.filteredClients

                            delegate: HyprWindowItem {
                                required property var modelData
                                width: winListColumn.width
                                clientData: modelData
                                isActiveWindow: root.activeWin && (root.activeWin.address === modelData.address)
                                busy: root.busy

                                onFocusRequested: function(addr) { root.focusWindow(addr); }
                                onMoveRequested: function(addr, target) { root.moveWindowToWorkspace(addr, target); }
                                onToggleFloatRequested: function(addr) { root.toggleFloating(addr); }
                                onToggleFullscreenRequested: function(addr) { root.toggleFullscreen(addr); }
                                onTogglePinRequested: function(addr) { root.togglePin(addr); }
                                onCloseRequested: function(addr) { root.closeWindow(addr); }
                            }
                        }
                    }
                }
            }
        }
    }
}
