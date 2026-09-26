import qs
import qs.modules.ii.topLayer.search as SearchConnect

SearchConnect.SearchDrop {
    id: root
    required property var scopeRoot

    screen: scopeRoot.screen
    monitorIndex: screen ? Quickshell.screens.indexOf(screen) : 0
    panelWindow: scopeRoot
    barVertical: scopeRoot.barVertical
    barBottom: scopeRoot.barBottom
    barOnLeft: scopeRoot.barOnLeft
    barOnRight: scopeRoot.barOnRight
    usingWrappedFrame: scopeRoot.usingWrappedFrame
    frameThickness: Config.options.appearance.wrappedFrameThickness
    barHeight: scopeRoot.hasBarOnThisMonitor ? Appearance.sizes.barHeight : 0
    verticalBarWidth: scopeRoot.hasBarOnThisMonitor ? Appearance.sizes.verticalBarWindowWidth : 0
    barMargin: scopeRoot.barMargin
    hBarHiddenAmount: scopeRoot.hBarHiddenAmount
    vBarHiddenAmount: scopeRoot.vBarHiddenAmount
    animatedLeftSidebarWidth: GlobalStates.animatedLeftSidebarWidth
    animatedRightSidebarWidth: GlobalStates.animatedRightSidebarWidth
    leftSidebarActiveOnMonitor: scopeRoot.leftSidebarActiveOnMonitor
    rightSidebarActiveOnMonitor: scopeRoot.rightSidebarActiveOnMonitor
}
