pragma ComponentBehavior: Bound

import QtQuick
import qs.services

/**
 * Weather the island may glance at.
 *
 * True once the service has real data: `Weather.data` starts as a placeholder
 * (lastRefresh "00:00") and only the fetch overwrites it, so showing before that
 * would advertise a fake 0°C. The shared weather-service switch gates all
 * requests. While enabled, this source keeps an active island glance fresh on
 * the service's own interval.
 */
ContinuousSource {
    id: source

    activityId: "weather"

    condition: Weather.enabled && Weather.data?.lastRefresh !== undefined
        && Weather.data.lastRefresh !== "00:00"

    // A QtObject has no default property: the timer hangs off a property, the way
    // BatterySource hangs its Connections.
    property Timer _refetch: Timer {
        interval: Weather.fetchInterval
        running: Weather.enabled && source.active
        repeat: true
        // Not forced: getData rate-limits itself, so an island left open for
        // weeks cannot turn into a polling loop against the API.
        onTriggered: Weather.getData(false)
    }
}
