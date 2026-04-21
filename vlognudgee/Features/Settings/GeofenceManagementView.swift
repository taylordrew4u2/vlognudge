//
//  GeofenceManagementView.swift
//  VlogNudge
//

import SwiftUI
import SwiftData
import MapKit
import CoreLocation

struct GeofenceManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Geofence.name) private var geofences: [Geofence]
    @State private var showAddSheet = false
    @State private var editingFence: Geofence?

    var body: some View {
        List {
            if geofences.isEmpty {
                ContentUnavailableView {
                    Label("No geofences yet", systemImage: "mappin.slash")
                } description: {
                    Text("Add places you go often — home, the club, your favorite spots — to get nudged when you arrive or leave.")
                }
            } else {
                ForEach(geofences) { fence in
                    Button {
                        editingFence = fence
                    } label: {
                        GeofenceRow(fence: fence)
                    }
                    .buttonStyle(.plain)
                }
                .onDelete(perform: delete)
            }
        }
        .navigationTitle("Geofences")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            GeofenceEditorView(existingFence: nil)
        }
        .sheet(item: $editingFence) { fence in
            GeofenceEditorView(existingFence: fence)
        }
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(geofences[index])
        }
        try? modelContext.save()
    }
}

struct GeofenceRow: View {
    let fence: Geofence

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "mappin.circle.fill")
                    .foregroundStyle(.red)
                Text(fence.name).font(.headline)
                Spacer()
                Text("\(Int(fence.radius))m")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 8) {
                if fence.nudgeOnEntry {
                    Label("Entry", systemImage: "arrow.down.to.line")
                        .font(.caption2)
                        .foregroundStyle(.blue)
                }
                if fence.nudgeOnExit {
                    Label("Exit", systemImage: "arrow.up.forward")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
            }
        }
    }
}

// MARK: - Editor

struct GeofenceEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let existingFence: Geofence?

    @State private var name: String = ""
    @State private var radius: Double = 100
    @State private var nudgeOnEntry: Bool = true
    @State private var nudgeOnExit: Bool = true
    @State private var customEntryPrompt: String = ""
    @State private var customExitPrompt: String = ""
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060),
            latitudinalMeters: 500,
            longitudinalMeters: 500
        )
    )
    @State private var pinCoordinate: CLLocationCoordinate2D?
    @State private var searchText: String = ""
    @State private var searchResults: [MKMapItem] = []

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("e.g. Home, Secret Pour", text: $name)
                }

                Section("Location") {
                    TextField("Search address or place", text: $searchText)
                        .onSubmit { performSearch() }

                    if !searchResults.isEmpty {
                        ForEach(searchResults, id: \.self) { item in
                            Button {
                                selectSearchResult(item)
                            } label: {
                                VStack(alignment: .leading) {
                                    Text(item.name ?? "Place")
                                        .font(.subheadline)
                                    if let address = formatAddress(item) {
                                        Text(address)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }

                    Map(position: $cameraPosition) {
                        if let coord = pinCoordinate {
                            Annotation("Pin", coordinate: coord) {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.title)
                                    .foregroundStyle(.red)
                            }
                            MapCircle(center: coord, radius: radius)
                                .foregroundStyle(.red.opacity(0.15))
                                .stroke(.red, lineWidth: 1.5)
                        }
                    }
                    .frame(height: 280)
                    .cornerRadius(10)

                    Button("Use current location") {
                        useCurrentLocation()
                    }
                }

                Section("Radius") {
                    VStack(alignment: .leading) {
                        Text("\(Int(radius)) meters")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Slider(value: $radius, in: 50...500, step: 10)
                    }
                }

                Section("Nudges") {
                    Toggle("Nudge on entry", isOn: $nudgeOnEntry)
                    Toggle("Nudge on exit", isOn: $nudgeOnExit)
                }

                Section("Custom prompts (optional)") {
                    TextField("Entry prompt (e.g. 'Pre-show clip?')",
                              text: $customEntryPrompt)
                    TextField("Exit prompt (e.g. 'Post-show recap?')",
                              text: $customExitPrompt)
                }
            }
            .navigationTitle(existingFence == nil ? "Add Geofence" : "Edit Geofence")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!isValid)
                }
            }
            .onAppear {
                loadFromExisting()
            }
        }
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && pinCoordinate != nil
    }

    private func loadFromExisting() {
        guard let fence = existingFence else { return }
        name = fence.name
        radius = fence.radius
        nudgeOnEntry = fence.nudgeOnEntry
        nudgeOnExit = fence.nudgeOnExit
        customEntryPrompt = fence.customPromptOnEntry ?? ""
        customExitPrompt = fence.customPromptOnExit ?? ""
        let coord = CLLocationCoordinate2D(latitude: fence.latitude, longitude: fence.longitude)
        pinCoordinate = coord
        cameraPosition = .region(
            MKCoordinateRegion(
                center: coord,
                latitudinalMeters: max(300, fence.radius * 4),
                longitudinalMeters: max(300, fence.radius * 4)
            )
        )
    }

    private func performSearch() {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        let search = MKLocalSearch(request: request)
        search.start { response, _ in
            if let items = response?.mapItems {
                searchResults = Array(items.prefix(5))
            }
        }
    }

    private func selectSearchResult(_ item: MKMapItem) {
        let coord = item.placemark.coordinate
        pinCoordinate = coord
        cameraPosition = .region(
            MKCoordinateRegion(
                center: coord,
                latitudinalMeters: max(300, radius * 4),
                longitudinalMeters: max(300, radius * 4)
            )
        )
        if name.isEmpty, let placeName = item.name {
            name = placeName
        }
        searchResults = []
        searchText = ""
    }

    private func useCurrentLocation() {
        let manager = CLLocationManager()
        manager.requestWhenInUseAuthorization()
        if let loc = manager.location {
            pinCoordinate = loc.coordinate
            cameraPosition = .region(
                MKCoordinateRegion(
                    center: loc.coordinate,
                    latitudinalMeters: max(300, radius * 4),
                    longitudinalMeters: max(300, radius * 4)
                )
            )
        }
    }

    private func formatAddress(_ item: MKMapItem) -> String? {
        let parts: [String?] = [
            item.placemark.thoroughfare,
            item.placemark.locality,
            item.placemark.administrativeArea
        ]
        let filtered = parts.compactMap { $0 }
        return filtered.isEmpty ? nil : filtered.joined(separator: ", ")
    }

    private func save() {
        guard let coord = pinCoordinate else { return }

        if let fence = existingFence {
            fence.name = name
            fence.latitude = coord.latitude
            fence.longitude = coord.longitude
            fence.radius = radius
            fence.nudgeOnEntry = nudgeOnEntry
            fence.nudgeOnExit = nudgeOnExit
            fence.customPromptOnEntry = customEntryPrompt.isEmpty ? nil : customEntryPrompt
            fence.customPromptOnExit = customExitPrompt.isEmpty ? nil : customExitPrompt
        } else {
            let new = Geofence(
                name: name,
                latitude: coord.latitude,
                longitude: coord.longitude,
                radius: radius
            )
            new.nudgeOnEntry = nudgeOnEntry
            new.nudgeOnExit = nudgeOnExit
            new.customPromptOnEntry = customEntryPrompt.isEmpty ? nil : customEntryPrompt
            new.customPromptOnExit = customExitPrompt.isEmpty ? nil : customExitPrompt
            modelContext.insert(new)
        }

        try? modelContext.save()

        // Refresh monitored regions
        let allFences = (try? modelContext.fetch(FetchDescriptor<Geofence>())) ?? []
        let currentLoc = CLLocationManager().location
        LocationService.shared.refreshGeofences(from: allFences, near: currentLoc)

        dismiss()
    }
}
