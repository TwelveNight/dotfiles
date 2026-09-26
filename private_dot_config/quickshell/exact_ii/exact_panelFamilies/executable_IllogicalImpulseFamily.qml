import QtQuick
import Quickshell
import qs
import qs.services

import qs.modules.common
import qs.modules.ii.bar
import qs.modules.ii.topLayer
import qs.modules.ii.verticalBar

// First-paint shell for the ii family. The large utility surface graph lives in
// IllogicalImpulseDeferredFamily.qml so a reload does not have to compile lock,
// overview, editors, pickers, phone controls, and recording UI before the bar.
Scope {
    id: root

    property bool barExtraCondition: true
    readonly property bool usingWrappedFrame: Config.options.appearance.fakeScreenRounding === 3
    readonly property bool barBot: BarPlacement.bottom
    readonly property bool barVert: BarPlacement.vertical
    property bool firstFrameReleased: false

    Component.onCompleted: {
        Qt.callLater(() => root.updateBarExtraCondition());
        firstFrameTimer.restart();
    }
    onUsingWrappedFrameChanged: updateBarExtraCondition()
    onBarBotChanged: updateBarExtraCondition()
    onBarVertChanged: updateBarExtraCondition()

    function updateBarExtraCondition() {
        if (!usingWrappedFrame)
            return;
        barExtraCondition = false;
        Qt.callLater(() => barExtraCondition = true);
    }

    // In Connect mode TopLayer owns the visible bar. In Default mode one of the
    // standalone bars owns it. Whichever is wanted takes the first schedule slot.
    PanelLoader {
        extraCondition: GlobalStates.connectModeActive
        component: TopLayer {}
    }
    PanelLoader {
        extraCondition: !BarPlacement.vertical && root.barExtraCondition && !GlobalStates.connectModeActive
        component: Bar {}
    }
    PanelLoader {
        extraCondition: BarPlacement.vertical && root.barExtraCondition && !GlobalStates.connectModeActive
        component: VerticalBar {}
    }

    // A short compositor window lets the first surface map before compiling the
    // secondary family. LazyLoader is deliberate: several secondary panels
    // register IpcHandlers and are unsafe under Qt asynchronous incubation after
    // a hot reload.
    Timer {
        id: firstFrameTimer
        interval: 1200
        repeat: false
        onTriggered: root.firstFrameReleased = true
    }

    LazyLoader {
        source: root.firstFrameReleased ? Qt.resolvedUrl("IllogicalImpulseDeferredFamily.qml") : ""
        active: root.firstFrameReleased && source !== ""
    }
}
