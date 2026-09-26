pragma Singleton

import QtQuick
import Quickshell

/**
 * Hands out creation slots to shell panels, one per tick.
 *
 * Every panel is gated on the same `Config.ready`, so without this they are all built in
 * a single event loop pass — around forty subtrees, every module they import, once per
 * monitor — and nothing paints until the last one exists. That is the multi-second freeze
 * at startup, and a smaller one whenever a family is rebuilt.
 *
 * Panels are still built synchronously, one at a time. Quickshell's own asynchronous
 * incubation is not an option for them: an `IpcHandler` finalised from the incubation
 * controller crashes in post-reload registration, and most panels declare one. Yielding
 * between panels is what keeps the shell drawing; the work itself is unchanged.
 */
Singleton {
    id: root

    /// Slots handed out so far. A panel takes one when it first wants to exist, so the
    /// order is the order they were declared in.
    property int issued: 0

    /// Slots cleared for creation. A panel builds once its own number comes up.
    property int released: 0

    function take(): int {
        return ++root.issued;
    }

    Timer {
        // The bar owns ticket 1. Give its initial mapped frame a real quiet window
        // before the background and the dozens of hidden utility surfaces begin
        // compiling. Eight milliseconds was shorter than one 120 Hz frame, so the
        // next synchronous panel could occupy the GUI thread before the compositor
        // ever saw the bar. Afterwards keep several frames between panels: startup
        // finishes a little later, but the visible shell arrives first and remains
        // responsive while secondary surfaces are populated.
        interval: root.released === 0 ? 1 : (root.released === 1 ? 700 : 120)
        repeat: true
        running: root.released < root.issued

        onTriggered: root.released++
    }
}
