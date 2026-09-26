import QtQuick
import Quickshell

import qs.modules.common

// URL-backed counterpart to PanelLoader. Keeping the component out of the
// family file is important: an inline component makes QML compile its whole
// import closure while the family itself is loading, before scheduling helps.
LazyLoader {
    id: root

    required property url panelUrl
    property bool extraCondition: true
    readonly property bool wanted: Config.ready && root.extraCondition
    property int ticket: 0
    readonly property bool released: root.wanted
        && root.ticket > 0
        && PanelSchedule.released >= root.ticket

    source: root.released ? root.panelUrl : ""
    active: root.released && source !== ""

    function takeTicket(): void {
        if (!root.wanted || root.ticket !== 0)
            return;
        root.ticket = PanelSchedule.take();
    }

    onWantedChanged: {
        if (root.wanted)
            root.takeTicket();
        else
            root.ticket = 0;
    }
    Component.onCompleted: root.takeTicket()
}
