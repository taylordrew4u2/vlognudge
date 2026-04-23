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

    private let manager = CLLocationManager()
    private var currentAuthorizationStatus: CLAuthorizationStatus = .notDetermined

    private override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        manager.allowsBackgroundLocationUpdates = true
        manager.pausesLocationUpdatesAutomatically = false
    }

    func requestAlwaysAuthorization() async {
        manager.requestAlwaysAuthorization()
    }

    func start() {
        manager.startMonitoringSignificantLocationChanges()
    }

    func stop() {
        manager.stopMonitoringSignificantLocationChanges()
    }

    // MARK: - Geofence registration

    /// Register geofences from SwiftData. iOS limits us to ~20 regions per app,
    /// so we pick the ones nearest the current location.
    func refreshGeofences(from geofences: [Geofence], near location: CLLocation?) {
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
    }

    // MARK: - Delegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        currentAuthorizationStatus = manager.authorizationStatus
        if manager.authorizationStatus == .authorizedAlways {
            start()
        }
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
        Task {
            await handleSignificantLocationChange(location: location)
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
