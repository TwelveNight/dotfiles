import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.ii.dynamicIsland.core

// Secondary panels stay behind URLs so their import graphs are compiled only
// when PanelSchedule releases their individual creation slot.
Scope {
    UrlPanelLoader { panelUrl: Qt.resolvedUrl("../modules/ii/cheatsheet/Cheatsheet.qml") }
    UrlPanelLoader {
        panelUrl: Qt.resolvedUrl("../modules/ii/notes/NotesApp.qml")
        extraCondition: Config.options.notes.enable
    }
    UrlPanelLoader {
        panelUrl: Qt.resolvedUrl("../modules/ii/usage/Usage.qml")
        extraCondition: Config.options.appStats.overlayEnabled
    }
    UrlPanelLoader {
        panelUrl: Qt.resolvedUrl("../modules/ii/modes/ModesOverlay.qml")
        extraCondition: Config.options.modes.overlayEnabled
    }
    UrlPanelLoader {
        panelUrl: Qt.resolvedUrl("../modules/ii/modeFlashPopup/ModeFlashPopup.qml")
        extraCondition: (Config.options?.modes?.enable ?? true) && !IslandPolicy.ownsModeFlash
    }
    UrlPanelLoader {
        panelUrl: Qt.resolvedUrl("../modules/ii/dock/Dock.qml")
        extraCondition: Config.options.dock.enable
    }
    UrlPanelLoader { panelUrl: Qt.resolvedUrl("../modules/ii/lock/Lock.qml") }
    UrlPanelLoader { panelUrl: Qt.resolvedUrl("../modules/ii/mediaControls/MediaControls.qml") }
    UrlPanelLoader {
        panelUrl: Qt.resolvedUrl("../modules/ii/bluetoothConnectionPopup/BluetoothConnectionPopup.qml")
        extraCondition: !IslandPolicy.ownsBluetoothPopup
    }
    UrlPanelLoader {
        panelUrl: Qt.resolvedUrl("../modules/ii/keyboardLayoutTransitionPopup/KeyboardLayoutTransitionPopup.qml")
        extraCondition: !IslandPolicy.ownsKeyboardPopup
    }
    UrlPanelLoader {
        panelUrl: Qt.resolvedUrl("../modules/ii/localSendPopup/LocalSendPopup.qml")
        extraCondition: !IslandPolicy.ownsLocalSendPopup && GlobalStates.localSendPopupOpen
    }
    UrlPanelLoader {
        panelUrl: Qt.resolvedUrl("../modules/ii/notificationPopup/NotificationPopup.qml")
        extraCondition: !IslandPolicy.ownsNotifications
    }
    UrlPanelLoader {
        panelUrl: Qt.resolvedUrl("../modules/ii/onScreenDisplay/OnScreenDisplay.qml")
        extraCondition: !(Config.ready && (Config.options.osd.style === "minimalist" || Config.options.osd.style === "material"))
    }
    UrlPanelLoader {
        panelUrl: Qt.resolvedUrl("../modules/ii/onScreenDisplay/minimalist/MinimalistOsd.qml")
        extraCondition: Config.ready && (Config.options.osd.style === "minimalist" || Config.options.osd.style === "material")
    }
    UrlPanelLoader {
        panelUrl: Qt.resolvedUrl("../modules/ii/keypressDisplay/KeypressDisplay.qml")
        extraCondition: Config.ready
    }
    UrlPanelLoader { panelUrl: Qt.resolvedUrl("../modules/common/onScreenKeyboard/OnScreenKeyboard.qml") }
    UrlPanelLoader { panelUrl: Qt.resolvedUrl("../modules/ii/oledSaver/OledSaver.qml") }
    UrlPanelLoader { panelUrl: Qt.resolvedUrl("../modules/ii/overlay/Overlay.qml") }
    UrlPanelLoader { panelUrl: Qt.resolvedUrl("../modules/ii/overview/Overview.qml") }
    UrlPanelLoader {
        panelUrl: Qt.resolvedUrl("IllogicalImpulseTabletAppDrawer.qml")
        extraCondition: Config.options.overview.useAppDrawer
    }
    UrlPanelLoader {
        panelUrl: Qt.resolvedUrl("../modules/ii/overview/OverviewWindowTransition.qml")
        extraCondition: !GlobalStates.overviewUsesAppDrawer
            && (Config.options?.background?.zoomOutEnabled ?? false)
            && (Config.options?.background?.windowZoomOnOverview ?? false)
    }
    UrlPanelLoader { panelUrl: Qt.resolvedUrl("../modules/ii/polkit/Polkit.qml") }
    UrlPanelLoader { panelUrl: Qt.resolvedUrl("../modules/ii/bluetoothPairing/BluetoothPairing.qml") }
    UrlPanelLoader { panelUrl: Qt.resolvedUrl("../modules/ii/regionSelector/RegionSelector.qml") }
    UrlPanelLoader { panelUrl: Qt.resolvedUrl("../modules/ii/recordingToolbar/RecordingToolbar.qml") }
    UrlPanelLoader {
        panelUrl: Qt.resolvedUrl("../modules/ii/screenCorners/ScreenCorners.qml")
        extraCondition: Config.options.appearance.fakeScreenRounding !== 0
            || Config.options.sidebar.cornerOpen.enable
    }
    UrlPanelLoader { panelUrl: Qt.resolvedUrl("../modules/ii/screenTranslator/ScreenTranslator.qml") }
    UrlPanelLoader { panelUrl: Qt.resolvedUrl("../modules/ii/colorPickerPopup/ColorPickerPopup.qml") }
    UrlPanelLoader { panelUrl: Qt.resolvedUrl("../modules/ii/sessionScreen/SessionScreen.qml") }
    UrlPanelLoader { panelUrl: Qt.resolvedUrl("../modules/common/panels/shellSwitcher/ShellSwitcher.qml") }
    UrlPanelLoader {
        panelUrl: Qt.resolvedUrl("../modules/ii/sidebarPolicies/SidebarPolicies.qml")
        extraCondition: !GlobalStates.connectModeActive || GlobalStates.connectSidebarsSeparate
    }
    UrlPanelLoader {
        panelUrl: Qt.resolvedUrl("../modules/ii/sidebarDashboard/SidebarDashboard.qml")
        extraCondition: !GlobalStates.connectModeActive || GlobalStates.connectSidebarsSeparate
    }
    UrlPanelLoader { panelUrl: Qt.resolvedUrl("../modules/ii/wallpaperSelector/WallpaperSelector.qml") }
    UrlPanelLoader { panelUrl: Qt.resolvedUrl("../modules/ii/wrappedFrame/WrappedFrame.qml") }
    // Background widgets are one of the largest dependency trees in II. They
    // deliberately enter after the interactive shell surfaces, not as the
    // first deferred panel competing with the newly mapped bar.
    UrlPanelLoader {
        panelUrl: Qt.resolvedUrl("../modules/ii/background/Background.qml")
        extraCondition: Config.options.background.enable
    }
    UrlPanelLoader {
        panelUrl: Qt.resolvedUrl("../modules/ii/editMode/EditModeChrome.qml")
        extraCondition: Config.options.background.enable
    }
    UrlPanelLoader {
        panelUrl: Qt.resolvedUrl("../modules/ii/background/desktopMenu/DesktopMenu.qml")
        extraCondition: Config.options.background.enable
    }
    UrlPanelLoader {
        panelUrl: Qt.resolvedUrl("../modules/ii/videoEditor/VideoEditorPopup.qml")
        extraCondition: GlobalStates.videoEditorPopupOpen
    }
    UrlPanelLoader {
        panelUrl: Qt.resolvedUrl("../modules/ii/videoEditor/VideoEditor.qml")
        extraCondition: GlobalStates.videoEditorOpen
    }
    UrlPanelLoader { panelUrl: Qt.resolvedUrl("../modules/ii/scratchpadOverlay/ScratchpadOverlay.qml") }
    UrlPanelLoader {
        panelUrl: Qt.resolvedUrl("../modules/ii/alarmRingingPopup/AlarmRingingPopup.qml")
        extraCondition: AlarmService.ringingAlarmIndex !== -1 && Config.options.time.alarms.useFullscreenPopup
    }
    UrlPanelLoader {
        panelUrl: Qt.resolvedUrl("../modules/ii/screenshotOverlay/ScreenshotOverlay.qml")
        extraCondition: GlobalStates.screenshotOverlayOpen
    }
    UrlPanelLoader {
        panelUrl: Qt.resolvedUrl("../modules/ii/tilingAssistant/TilingOverlay.qml")
        extraCondition: Config.options.tiling.enable
    }
    UrlPanelLoader {
        panelUrl: Qt.resolvedUrl("../modules/ii/tilingAssistant/LayoutHint.qml")
        extraCondition: Config.options.tiling.enable
    }
    UrlPanelLoader {
        panelUrl: Qt.resolvedUrl("../modules/ii/tilingAssistant/TilingStackBadges.qml")
        extraCondition: Config.options.tiling.enable && Config.options.tiling.overlay.stackIndicator
    }
    UrlPanelLoader {
        panelUrl: Qt.resolvedUrl("../modules/ii/dynamicIsland/DynamicIsland.qml")
        extraCondition: IslandPolicy.enabled
    }
    UrlPanelLoader {
        panelUrl: Qt.resolvedUrl("../modules/ii/touchGestures/TouchGestures.qml")
        extraCondition: Config.ready && Boolean(Config.options?.interactions?.touchGestures?.enable)
    }
    UrlPanelLoader {
        panelUrl: Qt.resolvedUrl("../modules/ii/phoneControls/PhoneFloatingWindowControls.qml")
        extraCondition: PhoneScrcpyService.mirrorRunning || PhoneScrcpyService.mirrorLaunching || KdeConnectService.scrcpyRunning
    }
}
