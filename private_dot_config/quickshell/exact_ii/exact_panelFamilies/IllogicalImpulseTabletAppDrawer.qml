import QtQuick
import qs.modules.ii.overview
import qs.modules.tablet.appDrawer

TabletAppDrawer {
    toolHostComponent: Component { SearchPanelHost {} }
    showTabletSystemApps: false
    allowHomeScreenPlacement: false
    allowDragToLaunch: false
}
