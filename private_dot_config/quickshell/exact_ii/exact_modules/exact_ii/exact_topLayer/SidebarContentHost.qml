import QtQuick

Item {
    id: root
    property var scopeRoot: null
    property string contentKind: ""
    property bool loadedOnLeft: false
    property bool keepWarm: false

    Loader {
        id: contentLoader
        anchors.fill: parent
        onLoaded: root.syncProperties()
    }

    function loadContent(): void {
        contentLoader.source = "";
        if (root.contentKind === "policies") {
            if (root.scopeRoot)
                contentLoader.setSource(Qt.resolvedUrl("../sidebarPolicies/SidebarPoliciesContent.qml"), {
                    scopeRoot: root.scopeRoot
                });
        } else if (root.contentKind === "dashboard") {
            contentLoader.setSource(Qt.resolvedUrl("../sidebarDashboard/SidebarDashboardContent.qml"), {
                isLoadedOnLeft: root.loadedOnLeft,
                keepWarm: root.keepWarm
            });
        }
    }

    function syncProperties(): void {
        if (!contentLoader.item)
            return;
        if ("scopeRoot" in contentLoader.item)
            contentLoader.item.scopeRoot = root.scopeRoot;
        if ("isLoadedOnLeft" in contentLoader.item)
            contentLoader.item.isLoadedOnLeft = root.loadedOnLeft;
        if ("keepWarm" in contentLoader.item)
            contentLoader.item.keepWarm = root.keepWarm;
    }

    onContentKindChanged: loadContent()
    onScopeRootChanged: {
        if (root.contentKind === "policies" && !contentLoader.item)
            loadContent();
        else
            syncProperties();
    }
    onLoadedOnLeftChanged: syncProperties()
    onKeepWarmChanged: syncProperties()
}
