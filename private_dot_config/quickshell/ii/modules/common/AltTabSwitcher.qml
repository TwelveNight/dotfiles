import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.waffle.looks

Scope {
    id: root

    property bool open: false
    property int selectedIndex: -1
    property list<var> toplevels: []
    property var previousToplevel: null

    function refreshToplevels() {
        root.toplevels = ToplevelManager.toplevels.values.filter(t => HyprlandData.clientForToplevel(t) !== null);
    }

    function advance(direction) {
        root.refreshToplevels();
        if (root.toplevels.length === 0) return;

        if (!root.open) {
            const activeIndex = root.toplevels.findIndex(t => t.activated);
            const previousIndex = root.toplevels.indexOf(root.previousToplevel);
            root.selectedIndex = previousIndex >= 0
                ? previousIndex
                : (activeIndex + direction + root.toplevels.length) % root.toplevels.length;
            root.open = true;
            return;
        }

        root.selectedIndex = (root.selectedIndex + direction + root.toplevels.length) % root.toplevels.length;
    }

    function accept() {
        const toplevel = root.toplevels[root.selectedIndex];
        const client = HyprlandData.clientForToplevel(toplevel);
        const activeToplevel = ToplevelManager.activeToplevel;
        if (activeToplevel && activeToplevel !== toplevel)
            root.previousToplevel = activeToplevel;
        // Use ii's Hyprland Lua dispatcher wrapper, as the existing task view
        // does. It focuses the actual Hyprland client, including one on a
        // different workspace.
        if (client?.address) Hyprland.dispatch(`hl.dsp.focus({window = "address:${client.address}"})`);
        root.cancel();
    }

    function acceptToplevel(toplevel) {
        root.refreshToplevels();
        const index = root.toplevels.indexOf(toplevel);
        if (index < 0) return;
        root.selectedIndex = index;
        root.accept();
    }

    function closeToplevel(toplevel) {
        const client = HyprlandData.clientForToplevel(toplevel);
        if (!client?.address) return;

        // Remove the card immediately. Hyprland updates its toplevel model
        // asynchronously, so waiting for refreshToplevels() would leave a
        // black screenshot card behind for a short time.
        root.toplevels = root.toplevels.filter(t => t !== toplevel);
        if (root.toplevels.length === 0) {
            root.cancel();
        } else if (root.selectedIndex >= root.toplevels.length) {
            root.selectedIndex = root.toplevels.length - 1;
        }
        Hyprland.dispatch(`hl.dsp.window.close({window = "address:${client.address}"})`);
        refreshTimer.restart();
    }

    function cancel() {
        root.open = false;
        root.selectedIndex = -1;
    }

    Timer {
        id: refreshTimer
        interval: 250
        repeat: false
        onTriggered: {
            if (root.open)
                root.refreshToplevels();
        }
    }

    Variants {
        model: Quickshell.screens
        delegate: PanelWindow {
            id: panel
            required property var modelData
            screen: modelData
            visible: root.open && modelData.name === Hyprland.focusedMonitor?.name
            color: "transparent"
            exclusiveZone: 0
            WlrLayershell.namespace: "quickshell:altTabSwitcher"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            Rectangle {
                id: switcherFrame
                anchors.centerIn: parent
                property int windowCount: root.toplevels.length
                property int cardSpacing: 12
                property int cardWidth: windowCount <= 1 ? 440
                    : windowCount <= 2 ? 360
                    : windowCount <= 3 ? 300
                    : windowCount <= 5 ? 240
                    : 200
                property int cardHeight: windowCount <= 1 ? 280
                    : windowCount <= 2 ? 240
                    : windowCount <= 3 ? 210
                    : windowCount <= 5 ? 190
                    : 170
                width: Math.min(parent.width - 64, switcherRow.implicitWidth + 32)
                height: switcherRow.implicitHeight + 32
                radius: Looks.radius.large
                color: Looks.colors.bg1Base
                border.width: 1
                border.color: Looks.colors.bg2Border

                RowLayout {
                    id: switcherRow
                    anchors.centerIn: parent
                    spacing: switcherFrame.cardSpacing

                    Repeater {
                        model: ScriptModel { values: root.toplevels }
                        delegate: Rectangle {
                            required property int index
                            required property var modelData
                            readonly property bool selected: index === root.selectedIndex
                            property bool closing: false
                            readonly property bool hovered: hoverHandler.hovered
                            implicitWidth: switcherFrame.cardWidth
                            implicitHeight: switcherFrame.cardHeight
                            radius: Looks.radius.medium
                            color: selected || hovered ? Looks.colors.bg2Active : Looks.colors.bg2
                            border.width: selected || hovered ? 2 : 1
                            border.color: selected || hovered ? Looks.colors.accent : Looks.colors.bg2Border
                            scale: hovered ? 1.035 : 1

                            Behavior on color { ColorAnimation { duration: 140 } }
                            Behavior on border.color { ColorAnimation { duration: 140 } }
                            Behavior on scale {
                                NumberAnimation {
                                    duration: 140
                                    easing.type: Easing.OutCubic
                                }
                            }

                            MouseArea {
                                id: clickArea
                                anchors.fill: parent
                                z: 100
                                acceptedButtons: Qt.LeftButton
                                hoverEnabled: true
                                onClicked: root.acceptToplevel(modelData)
                            }

                            HoverHandler {
                                id: hoverHandler
                            }

                            CloseButton {
                                id: closeButton
                                implicitWidth: 30
                                implicitHeight: 30
                                anchors.top: parent.top
                                anchors.right: parent.right
                                anchors.topMargin: 5
                                anchors.rightMargin: 5
                                z: 200
                                visible: true
                                radius: Looks.radius.large - 5
                                scale: hovered ? 1.12 : 1
                                Behavior on scale {
                                    NumberAnimation {
                                        duration: 120
                                        easing.type: Easing.OutCubic
                                    }
                                }
                                onClicked: {
                                    closing = true;
                                    root.closeToplevel(modelData);
                                }
                            }

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 5

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 6
                                    WAppIcon {
                                        iconName: AppSearch.guessIcon(modelData.appId)
                                        implicitSize: 16
                                    }
                                    WText {
                                        Layout.fillWidth: true
                                        text: modelData.title
                                        elide: Text.ElideRight
                                    }
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    clip: true
                                    radius: Looks.radius.medium
                                    color: Looks.colors.bg2

                                    ScreencopyView {
                                        anchors.fill: parent
                                        captureSource: closing || root.toplevels.indexOf(modelData) < 0 ? null : modelData
                                        live: true
                                        constraintSize: Qt.size(Math.round(parent.width), Math.round(parent.height))
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    GlobalShortcut {
        name: "altTabNext"
        onPressed: root.advance(1)
    }

    GlobalShortcut {
        name: "altTabPrevious"
        onPressed: root.advance(-1)
    }

    IpcHandler {
        target: "altTab"

        function next() { root.advance(1); }
        function previous() { root.advance(-1); }
        function accept() { root.accept(); }
        function cancel() { root.cancel(); }
    }
}
