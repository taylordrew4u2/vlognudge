//
//  LocationService.swift
//  VlogNudge
//

import Foundation
import CoreLocation
import SwiftData
import Observation

@Observable
final class LocationService: NSObject, CLLocationManagerDelegate {
    static let shared = LocationService()

    private static let backgroundLocationEnabledKey = "backgroundLocationNudgesEnabled"

    private let manager = CLLocationManager()
    private var currentAuthorizationStatus: CLAuthorizationStatus = .notDetermined
    private var shouldRequestAlwaysAfterWhenInUse = false
    private(set) var isBackgroundLocationEnabled = false
    private(set) var isBackgroundLocationActive = false
    private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    private(set) var currentLocation: CLLocation?

    private override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        manager.allowsBackgroundLocationUpdates = false
        manager.pausesLocationUpdatesAutomatically = true
        currentAuthorizationStatus = manager.authorizationStatus
        authorizationStatus = manager.authorizationStatus
        isBackgroundLocationEnabled = Self.savedBackgroundLocationEnabled
    }

    func requestWhenInUseAuthorization() async {
        manager.requestWhenInUseAuthorization()
    }

    func enableBackgroundLocation() {
        isBackgroundLocationEnabled = true
        Self.savedBackgroundLocationEnabled = true
        switch manager.authorizationStatus {
        case .notDetermined:
            shouldRequestAlwaysAfterWhenInUse = true
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse:
            manager.requestAlwaysAuthorization()
        default:
            break
        }
        updateBackgroundLocationState()
    }

    func disableBackgroundLocation() {
        isBackgroundLocationEnabled = false
        Self.savedBackgroundLocationEnabled = false
        stop()
    }

    func restoreExplicitBackgroundLocationIfNeeded() {
        isBackgroundLocationEnabled = Self.savedBackgroundLocationEnabled
        updateBackgroundLocationState()
    }

    private func start() {
        guard isBackgroundLocationEnabled,
              manager.authorizationStatus == .authorizedAlways else { return }
        manager.allowsBackgroundLocationUpdates = true
        manager.pausesLocationUpdatesAutomatically = true
        manager.startMonitoringSignificantLocationChanges()
        isBackgroundLocationActive = true
    }

    private func stop() {
        manager.stopMonitoringSignificantLocationChanges()
        for region in manager.monitoredRegions {
            manager.stopMonitoring(for: region)
        }
        manager.allowsBackgroundLocationUpdates = false
        isBackgroundLocationActive = false
    }

    // MARK: - Geofence registration

    /// Register geofences from SwiftData. iOS limits us to ~20 regions per app,
    /// so we pick the ones nearest the current location.
    func refreshGeofences(from geofences: [Geofence], near location: CLLocation?) {
        guard isBackgroundLocationEnabled,
              manager.authorizationStatus == .authorizedAlways else {
            stop()
            return
        }

        // Stop monitoring all current regions
        for region in manager.monitoredRegions {
            manager.stopMonitoring(for: region)
        }

        let sorted: [Geofence]
        if let loc = location {
            sorted = geofences.sorted { a, b in
                let aLoc = CLLocation(latitude: a.latitude, longitude: a.longitude)
                let bLoc = CLLocation(latitude: b.latitude, longitude: b.longitude)
                return aLoc.distance(from: loc) < bLoc.distance(from: loc)
            }
        } else {
            sorted = geofences
        }

        for fence in sorted.prefix(18) {  // leave headroom for system
            let region = CLCircularRegion(
                center: CLLocationCoordinate2D(latitude: fence.latitude, longitude: fence.longitude),
                radius: fence.radius,
                identifier: fence.id.uuidString
            )
            region.notifyOnEntry = fence.nudgeOnEntry
            region.notifyOnExit = fence.nudgeOnExit
            manager.startMonitoring(for: region)
        }
        start()
    }

    // MARK: - Delegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        currentAuthorizationStatus = manager.authorizationStatus
        authorizationStatus = manager.authorizationStatus
        if shouldRequestAlwaysAfterWhenInUse,
           manager.authorizationStatus == .authorizedWhenInUse {
            shouldRequestAlwaysAfterWhenInUse = false
            manager.requestAlwaysAuthorization()
        }
        updateBackgroundLocationState()
    }

    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        handleRegionEvent(region: region, kind: "entry")
    }

    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        handleRegionEvent(region: region, kind: "exit")
    }

    func locationManager(_ manager: CLLocationManager,
                         didUpdateLocations locations: [CLLocation]) {
        // Significant change — useful for detecting "new place not in geofences"
        // Could extend here: compare distance to all known geofences, and if > threshold
        // fire a "new_location" trigger.
        guard let location = locations.last else { return }
        currentLocation = location
        Task {
            await handleSignificantLocationChange(location: location)
        }
    }

    private func updateBackgroundLocationState() {
        if isBackgroundLocationEnabled, manager.authorizationStatus == .authorizedAlways {
            start()
        } else {
            stop()
        }
    }

    private static var savedBackgroundLocationEnabled: Bool {
        get {
            UserDefaults(suiteName: AppConstants.appGroupID)?
                .bool(forKey: backgroundLocationEnabledKey) ?? false
        }
        set {
            UserDefaults(suiteName: AppConstants.appGroupID)?
                .set(newValue, forKey: backgroundLocationEnabledKey)
        }
    }

    private func handleRegionEvent(region: CLRegion, kind: String) {
        let reason = "geofence_\(kind):\(region.identifier)"
        Task { @MainActor in
            let context = SharedModelContainer.backgroundContext()
            await NudgeScheduler.shared.evaluateContextTrigger(
                reason: reason,
                context: context
            )
        }
    }

    @MainActor
    private func handleSignificantLocationChange(location: CLLocation) async {
        let context = SharedModelContainer.backgroundContext()

        // Check if this is a new location (not near any known geofence)
        let fences = (try? context.fetch(FetchDescriptor<Geofence>())) ?? []
        let nearest = fences.min { a, b in
            let aLoc = CLLocation(latitude: a.latitude, longitude: a.longitude)
            let bLoc = CLLocation(latitude: b.latitude, longitude: b.longitude)
            return aLoc.distance(from: location) < bLoc.distance(from: location)
        }

        if let nearest = nearest {
            let nearestLoc = CLLocation(latitude: nearest.latitude, longitude: nearest.longitude)
            if location.distance(from: nearestLoc) > 500 {
                // New area
                await NudgeScheduler.shared.evaluateContextTrigger(
                    reason: "geofence_new_location",
                    context: context
                )
            }
        }

        // Refresh monitored regions relative to current position
        refreshGeofences(from: fences, near: location)
    }
}
