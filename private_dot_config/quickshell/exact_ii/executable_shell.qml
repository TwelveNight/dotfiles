//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000
// Qt allocates a depth-stencil renderbuffer per window (and per layer) for 2D opaque batching. The rendered
// output is identical without it; it only trades a little GPU time on heavy overdraw for ~20 MB per
// fullscreen window on HiDPI.
//@ pragma Env QSG_NO_DEPTH_BUFFER=1
//@ pragma Env MALLOC_CONF=dirty_decay_ms:1000,muzzy_decay_ms:1000,background_thread:true
// Qt falls back to the basic render loop on NVIDIA's Wayland EGL, which renders every window in
// turn on the GUI thread. When the GPU has clocked down after a while idle, the driver spin-waits
// there for 50-200 ms and every GUI-driven animation (the overview's opening zoom first) jumps.
// Threaded gives each window its own render thread and keeps the GUI thread's clock at 120 Hz.
//@ pragma Env QSG_RENDER_LOOP=threaded

// Remove two slashes below and adjust the value to change the UI scale
////@ pragma Env QT_SCALE_FACTOR=1

import "modules/common"
import "modules/common/idleDim"
import "services"
import "panelFamilies"

import QtQuick
import QtQuick.Window
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

ShellRoot {
    id: root
    property string openRgbApplyScript: Quickshell.shellPath("scripts/colors/openRGB/apply_openrgb.py")
    property bool openRgbStartupApplied: false

    // Stuff for every panel family
    ReloadPopup {}
    AltTabSwitcher {}
    IdleDim {} // hypridle's 120 s dim, see hypr/hypridle.conf

    // Boot split: only what the FIRST PAINT needs runs during engine load.
    // Everything else starts from a 3 s timer — panel incubation is main-thread
    // work, and ~40 singleton initializations (each spawning one-shot probes,
    // FileView reads or daemons) compete with it and delay the bar's first
    // mapped frame. Services still start exactly once per engine generation:
    // the timer re-arms on every hot reload just like Component.onCompleted did.
    Component.onCompleted: {
        if (Qt.application) {
            Qt.application.applicationName = "quickshell";
            Qt.application.organizationName = "Unknown Organization";
            Qt.application.organizationDomain = "unknown.organization";
        }
        MaterialThemeLoader.reapplyTheme();
        Wallpapers.load();
        ConflictKiller.load(); // Startup hygiene: conflicting notification daemons must die early
        deferredServicesTimer.restart();
    }

    Timer {
        id: deferredServicesTimer
        interval: 7000
        onTriggered: root.startDeferredServices()
    }

    // A single callback that touches every service keeps the GUI thread busy for
    // several seconds after Configuration Loaded. Run one initialization per
    // event-loop slice instead: total background work is unchanged, but the bar,
    // compositor and IPC get a chance to respond between expensive singletons.
    property var deferredServiceSteps: []
    property int deferredServiceStepIndex: 0

    function startDeferredServices() {
        const timetable = Config.options?.calendar?.timetable;
        const hasCalendarSubscriptions = (timetable?.imports?.enable ?? false)
            || ((timetable?.subscriptions ?? []).length > 0);
        deferredServiceSteps = [
            () => Hyprsunset.load(),
            () => DisplayColorFilter.load(),
            () => Cliphist.refresh(),
            () => Updates.load(),
            () => ShellUpdates.load(),
            () => FeatureDeps.checkCore(),
            () => { if (Config.options?.update?.aiSummary) ShellUpdateSummary.load(); },
            () => { if (Config.options?.light?.darkMode?.automatic ?? false) DarkModeService.automatic; },
            () => { if (Config.options?.sounds?.enable) SoundService.indexReady; },
            () => { if (Config.options?.background?.mediaMode?.musicVideo?.enable) VideoColorSampler.active; },
            () => { if (Config.options?.waterReminder?.enable) WaterReminderService.enabled; },
            () => { if (Config.options?.calendar?.timetable?.notifications?.enable) CalendarNotifier.enabled; },
            () => { Todo.list; },
            () => { if (hasCalendarSubscriptions) CalendarSubscriptions.enabled; },
            () => { if (timetable?.imports?.enable && timetable?.imports?.gmailIcs?.enable) GmailCalendarImport.enabled; },
            () => { if (timetable?.imports?.enable && timetable?.imports?.outlook?.enable) OutlookCalendarImport.enabled; },
            () => { if (timetable?.imports?.enable && timetable?.imports?.outlook?.icsAttachments?.enable) OutlookIcsImport.enabled; },
            () => { if (timetable?.birthdays?.enable) BirthdaysService.enabled; },
            () => { if (Config.options?.googleDrive?.enabled) GoogleDriveService.configured; },
            () => { if (Config.options?.appStats?.enable ?? true) AppStats.stateDir; },
            () => { if (Config.options?.notes?.enable ?? true) NotesService.ready; },
            () => { if (Config.options?.modes?.enable ?? true) Modes.ready; },
            () => { if (Config.options?.tiling?.enable) TilingAssistant.enabled; },
            () => { if (Config.options?.launcher?.typeToSearch?.enable ?? false) TypeToSearch.armed; },
            () => { StaleFocusRelease.active; },
            () => { if (Config.options?.interactions?.touchGestures?.enable ?? true) TouchGestureService.enabled; },
            () => { if (Config.options?.bar?.workspaces?.autoCompact ?? false) WorkspaceCompactor.enabled; },
            () => { if (Config.options?.dictation?.enabled) DictationService.installed; },
            () => { if (Config.options?.budsLink?.enabled) BudsLinkService.serviceAvailable; },
            () => { if (Config.options?.policies?.phone !== 0) KdeConnectService.available; },
            () => { if (Config.options?.policies?.phone !== 0) PhoneContactsService.available; },
            () => { if (Config.options?.policies?.phone !== 0) PhoneScrcpyService.available; },
            () => { if (Config.options?.localMedia?.enabled) LocalMediaService.hasSession; },
            () => { if (Config.options?.localMedia?.enabled) LocalMediaSelection.lastSelectionDescription; },
            () => root.applyOpenRgbIfEnabled()
        ];
        deferredServiceStepIndex = 0;
        deferredServiceStepTimer.restart();
    }

    Timer {
        id: deferredServiceStepTimer
        interval: 150
        repeat: true
        onTriggered: {
            if (root.deferredServiceStepIndex >= root.deferredServiceSteps.length) {
                stop();
                return;
            }
            const step = root.deferredServiceSteps[root.deferredServiceStepIndex++];
            step();
        }
    }

    // Panel families. The list and the switch itself live on PanelFamily now — this file
    // owning a second copy of the family names is how the two drift apart.
    function cyclePanelFamily() {
        PanelFamily.cycle();
    }

    function applyOpenRgbIfEnabled() {
        if (openRgbStartupApplied)
            return;
        if (!Config.ready)
            return;
        if (!(Config.options && Config.options.appearance && Config.options.appearance.openrgb && Config.options.appearance.openrgb.enable))
            return;
        if (!(Config.options && Config.options.appearance && Config.options.appearance.openrgb && Config.options.appearance.openrgb.applyOnStartup))
            return;
        openRgbStartupApplied = true;
        openRgbApplyProc.command = ["python3", openRgbApplyScript];
        openRgbApplyProc.running = false;
        openRgbApplyProc.running = true;
    }

    Connections {
        target: Config
        function onReadyChanged() {
            if (Config.ready)
                root.applyOpenRgbIfEnabled();
        }
    }

    Process {
        id: openRgbApplyProc
    }

    // Families are loaded by URL rather than as inline components: an inline `component: X {}`
    // compiles X and its whole import closure (for Waffle: 144 files plus the FluentWinUI3/Fusion
    // style and Kirigami plugins) at startup even when that family is never active. With a URL,
    // nothing is compiled until the family is wanted.
    //
    // LazyLoader.setSource() compiles the component but never incubates it, and setActive(true)
    // before a component exists is a silent no-op, so `active` must depend on `source` to avoid
    // the family never loading when the two bindings settle in the wrong order.
    component PanelFamilyLoader: LazyLoader {
        required property string identifier
        required property string familyUrl
        property bool extraCondition: true
        readonly property bool wanted: Config.ready && Config.options.panelFamily === identifier && extraCondition
        source: wanted ? familyUrl : ""
        active: wanted && source !== ""
    }

    PanelFamilyLoader {
        identifier: "ii"
        familyUrl: Qt.resolvedUrl("panelFamilies/IllogicalImpulseFamily.qml")
    }

    PanelFamilyLoader {
        identifier: "tablet"
        familyUrl: Qt.resolvedUrl("panelFamilies/TabletFamily.qml")
    }

    PanelFamilyLoader {
        identifier: "waffle"
        familyUrl: Qt.resolvedUrl("panelFamilies/WaffleFamily.qml")
    }

    // Closing destroys the window and its page tree, at once or after
    // `appearance.settingsUnloadDelay` seconds, or never when that is negative;
    // a reopen before then only shows the hidden window again. Screenshot
    // capture only hides it temporarily; its Process belongs to the current
    // page and must survive until capture finishes.

    Loader {
        id: settingsLoader
        // Seconds; 0 frees Settings as soon as it closes, a negative value never does.
        readonly property int unloadDelay: Config.options?.appearance?.settingsUnloadDelay ?? 0
        readonly property bool keepAliveWanted: unloadDelay !== 0
        // Raised when Settings opens, not when it closes: the close would
        // otherwise race `active` below and tear the window down first.
        property bool keptAlive: false

        active: GlobalStates.settingsOpen || GlobalStates.settingsSuspendedForScreenshot || keptAlive
        // Synchronous: the window itself builds in a few tens of ms once
        // compiled (see settingsWarmup), while an asynchronous build held the
        // window back for most of a second. Pages still load asynchronously.
        asynchronous: false
        source: "SettingsWindow.qml"
        onActiveChanged: {
            if (!active && settingsGarbageCollect)
                settingsGarbageCollect.restart();
        }
        onUnloadDelayChanged: {
            settingsUnloadTimer.stop();
            if (!keepAliveWanted) {
                keptAlive = false;
            } else if (GlobalStates.settingsOpen) {
                keptAlive = true;
            } else if (keptAlive && unloadDelay > 0) {
                settingsUnloadTimer.restart();
            }
        }

    }

    Timer {
        id: settingsUnloadTimer
        interval: Math.max(1, settingsLoader.unloadDelay) * 1000
        onTriggered: {
            if (!GlobalStates.settingsOpen)
                settingsLoader.keptAlive = false;
        }
    }

    Connections {
        target: GlobalStates
        function onSettingsOpenChanged() {
            if (GlobalStates.settingsOpen) {
                settingsUnloadTimer.stop();
                settingsLoader.keptAlive = settingsLoader.keepAliveWanted;
            } else if (settingsLoader.keptAlive && settingsLoader.unloadDelay > 0) {
                settingsUnloadTimer.restart();
            }
        }
    }

    // Compiles Settings and every page ahead of the first open. Compiling is
    // what made the first open of a session (and each first page visit) slow;
    // an asynchronous component compiles off the GUI thread, and the engine
    // keeps compiled code after a first visit anyway. No objects are created.
    Timer {
        id: settingsWarmup
        property var components: []
        interval: 25000
        running: Config.ready && components.length === 0
        onTriggered: {
            const urls = ["SettingsWindow.qml"].concat(SettingsPageRegistry.pages.map(page => page.component));
            settingsWarmup.components = urls.map(url => Qt.createComponent(url, Component.Asynchronous));
        }
    }

    // Loader deletion is deferred. Collect only after its tree and the
    // window-owned search data have been released, never inside destruction.
    Timer {
        id: settingsGarbageCollect
        interval: 0
        onTriggered: {
            if (!settingsLoader.active)
                gc();
        }
    }

    // Welcome runs in-process so it shares Config, GlobalStates and the same
    // Quickshell lifecycle as Settings and is also destroyed on close.
    Loader {
        id: welcomeLoader
        active: Config.ready && GlobalStates.welcomeOpen
        asynchronous: true
        source: "modules/welcome/WelcomeWindow.qml"
    }

    // The Welcome's stand-in while it is stepped aside for Edit Mode. A layer
    // surface rather than a smaller window: a Wayland toplevel cannot place
    // itself beside the toolbar, and this has to.
    // A number on each physical panel while the displays step asks which is
    // which. One surface per screen, so the answer is on the screen itself.
    LazyLoader {
        id: displayIdentifyLoader
        readonly property bool wanted: Config.ready && GlobalStates.displayIdentifyActive
        source: wanted ? "modules/welcome/WelcomeDisplayIdentifier.qml" : ""
        active: wanted && source !== ""
    }

    LazyLoader {
        id: welcomeCollapsedLoader
        readonly property bool wanted: Config.ready
            && GlobalStates.welcomeOpen
            && GlobalStates.welcomeCollapsed
        source: wanted ? "modules/welcome/WelcomeCollapsedPill.qml" : ""
        active: wanted && source !== ""
    }

    // ── The Welcome, when the setup script asked for one ─────────────────────
    //
    // A marker written by the SHELL would mean "I have greeted this user", and
    // that is a one-way door: after the first install it would never open
    // again - not on a reinstall, not after `./setup resetfirstrun`. Deciding
    // is the setup's job, and it already knows the difference between a first
    // install and an update (`INSTALL_FIRSTRUN`).
    //
    // So the setup asks in whichever way can work. If a shell is already
    // running it calls `qs -c ii ipc call welcome open` and this is not
    // involved at all. A real first install is run from a TTY with no shell to
    // answer - and `hyprctl reload` does not re-run exec-once, so it will not
    // start one - and there the setup leaves this file behind instead. Read
    // once, opened once, deleted.
    property bool welcomeRequested: false

    FileView {
        id: welcomeRequest
        path: Directories.welcomeRequestPath
        // No file is the normal state - every start without a pending request
        // would otherwise log a read failure - so the miss is silent and
        // onLoadFailed needs no handler.
        printErrors: false
        onLoaded: root.welcomeRequested = true
        Component.onCompleted: welcomeRequest.reload()
    }

    // Let the session draw itself before a window lands on top of it: on a
    // first login this runs while the bar and the wallpaper are still arriving.
    Timer {
        interval: 2500
        repeat: false
        running: root.welcomeRequested && Config.ready
        onTriggered: {
            root.welcomeRequested = false;
            Quickshell.execDetached(["rm", "-f", welcomeRequest.path]);
            // The clean workspace is `openWelcome`'s own business now — the
            // install's terminal is only the loudest case of the clutter every
            // way in has to get out from under.
            GlobalStates.openWelcome();
        }
    }

    // Shortcuts
    IpcHandler {
        target: "panelFamily"

        function cycle() {
            root.cyclePanelFamily();
        }

        /// Opens the chooser rather than switching. The cycle above stays for anyone who
        /// scripted it, but it is the wrong default: it walks through the family in between.
        function pick(): void {
            GlobalStates.shellSwitcherOpen = true;
        }

        function set(familyId: string): void {
            PanelFamily.select(familyId);
        }

        function list(): string {
            return PanelFamily.available.map(family => family.id).join("\n");
        }
    }

    GlobalShortcut {
        name: "panelFamilyCycle"
        description: "Cycles panel family"

        onPressed: root.cyclePanelFamily()
    }

    GlobalShortcut {
        name: "panelFamilyPicker"
        description: "Opens the shell chooser"

        onPressed: GlobalStates.shellSwitcherOpen = !GlobalStates.shellSwitcherOpen
    }
}
