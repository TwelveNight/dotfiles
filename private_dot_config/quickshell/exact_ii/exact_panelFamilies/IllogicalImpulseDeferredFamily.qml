import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.panels.shellSwitcher
import qs.modules.common.panels.windowSwitcher
import qs.modules.ii.displayModesPopup
import qs.modules.ii.background
import qs.modules.ii.background.desktopMenu
import qs.modules.ii.bar
import qs.modules.ii.bluetoothConnectionPopup
import qs.modules.ii.bluetoothPairing
import qs.modules.ii.cheatsheet
import qs.modules.ii.notes
import qs.modules.ii.clock
import qs.modules.ii.dock
import qs.modules.ii.easyEffects
import qs.modules.ii.lock
import qs.modules.ii.mediaControls
import qs.modules.ii.notificationPopup
import qs.modules.ii.onScreenDisplay
import qs.modules.ii.onScreenDisplay.minimalist
import qs.modules.common.onScreenKeyboard
import qs.modules.ii.oledSaver
import qs.modules.ii.overview
import qs.modules.ii.polkit
import qs.modules.ii.regionSelector
import qs.modules.ii.screenCorners
import qs.modules.ii.screenTranslator
import qs.modules.ii.sessionScreen
import qs.modules.ii.sidebarPolicies
import qs.modules.ii.sidebarDashboard
import qs.modules.ii.overlay
import qs.modules.ii.verticalBar
import qs.modules.ii.wallpaperSelector
import qs.modules.ii.wrappedFrame
import qs.modules.ii.colorPickerPopup
import qs.modules.ii.videoEditor
import qs.modules.ii.localSendPopup
import qs.modules.ii.scratchpadOverlay
import qs.modules.ii.keyboardLayoutTransitionPopup
import qs.modules.ii.keypressDisplay
import qs.modules.ii.topLayer
import qs.modules.ii.tilingAssistant
import qs.modules.ii.usage
import qs.modules.ii.modes
import qs.modules.ii.modeFlashPopup
import qs.modules.ii.alarmRingingPopup
import qs.modules.ii.reminderAlertPopup
import qs.modules.ii.screenTimeOverlay
import qs.modules.ii.screenshotOverlay
import qs.modules.ii.dynamicIsland
import qs.modules.ii.dynamicIsland.core
import qs.modules.ii.touchGestures
import qs.modules.ii.editMode
import qs.modules.tablet.appDrawer
import qs.modules.ii.phoneControls
import qs.modules.ii.recordingToolbar

// Secondary panels stay behind URLs so their import graphs are compiled only
// when PanelSchedule releases their individual creation slot.
Scope {
    UrlPanelLoader { panelUrl: Qt.resolvedUrl("../modules/ii/cheatsheet/Cheatsheet.qml") }
    UrlPanelLoader {
        panelUrl: Qt.resolvedUrl("../modules/ii/notes/NotesApp.qml")
        extraCondition: Config.options.notes.enable
    }
    UrlPanelLoader {
        panelUrl: Qt.resolvedUrl("../modules/ii/clock/ClockApp.qml")
        extraCondition: Config.options.clockApp?.enable ?? true
    }
    UrlPanelLoader { panelUrl: Qt.resolvedUrl("../modules/ii/easyEffects/EasyEffectsApp.qml") }
    UrlPanelLoader {
        panelUrl: Qt.resolvedUrl("../modules/ii/usage/UsageApp.qml")
        extraCondition: Config.options.appStats.overlayEnabled
    }
    UrlPanelLoader {
        panelUrl: Qt.resolvedUrl("../modules/ii/modes/ModesApp.qml")
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
    UrlPanelLoader { panelUrl: Qt.resolvedUrl("../modules/ii/displayModesPopup/DisplayModesPopup.qml") }
    UrlPanelLoader { panelUrl: Qt.resolvedUrl("../modules/ii/sessionScreen/SessionScreen.qml") }
    UrlPanelLoader { panelUrl: Qt.resolvedUrl("../modules/common/panels/shellSwitcher/ShellSwitcher.qml") }
    // Always loaded so switching off Alt+Tab also releases its bindings.
    UrlPanelLoader { panelUrl: Qt.resolvedUrl("../modules/common/panels/windowSwitcher/WindowSwitcherPanel.qml") }
    UrlPanelLoader { panelUrl: Qt.resolvedUrl("../modules/common/panels/windowSwitcher/WindowSwitcherPeek.qml") }
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
        // A Medium or Strong reminder taking the screen; built only while one does.
        extraCondition: RemindersService.ringingId.length > 0 && !GlobalStates.islandOwnsReminder
        panelUrl: Qt.resolvedUrl("../modules/ii/reminderAlertPopup/ReminderAlertPopup.qml")
    }
    UrlPanelLoader {
        panelUrl: Qt.resolvedUrl("../modules/ii/screenTimeOverlay/ScreenTimeOverlay.qml")
        extraCondition: (Config.options.screenTime?.enable ?? true) && ScreenTimeLimits.activeBlock !== null
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
