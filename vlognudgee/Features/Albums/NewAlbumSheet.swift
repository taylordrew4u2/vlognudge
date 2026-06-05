//
//  NewAlbumSheet.swift
//  VlogNudge
//
//  6:3:1 — Secondary form rows, Accent selections & create button.
//

import SwiftUI
import SwiftData

struct NewAlbumSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query private var existingAlbums: [VlogAlbum]

    @State private var name: String = ""
    @State private var selectedIcon: String = "film.stack"
    @State private var selectedColor: String = "EF5350"

    private let iconOptions = [
        "film.stack", "video.fill", "camera.fill", "star.fill",
        "house.fill", "airplane", "figure.walk", "cup.and.saucer.fill"
    ]

    private let colorOptions = [
        "EF5350", "235789", "F1D302", "22C55E",
        "8B5CF6", "EC4899", "F97316", "3B82F6"
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Album name", text: $name)
                }

                Section("Icon") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: VNSpacing.lg) {
                        ForEach(iconOptions, id: \.self) { icon in
                            Image(systemName: icon)
                                .font(.title2)
                                .foregroundStyle(selectedIcon == icon ? Color(hex: selectedColor) : VNColor.textTertiary)
                                .frame(width: 48, height: 48)
                                .background(
                                    selectedIcon == icon ? Color(hex: selectedColor).opacity(0.15) : Color.clear,
                                    in: RoundedRectangle(cornerRadius: VNRadius.md)
                                )
                                .onTapGesture { selectedIcon = icon }
                                .accessibilityLabel(icon)
                        }
                    }
                    .padding(.vertical, VNSpacing.xs)
                }

                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: VNSpacing.lg) {
                        ForEach(colorOptions, id: \.self) { hex in
                            Circle()
                                .fill(Color(hex: hex))
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Circle()
                                        .stroke(VNColor.textPrimary, lineWidth: selectedColor == hex ? 2.5 : 0)
                                        .padding(2)
                                )
                                .onTapGesture { selectedColor = hex }
                        }
                    }
                    .padding(.vertical, VNSpacing.xs)
                }
            }
            .scrollContentBackground(.hidden)
            .background(VNColor.dominant)
            .tint(VNColor.accent)
            .navigationTitle("New Album")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(VNColor.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        let album = VlogAlbum(
                            name: name.trimmingCharacters(in: .whitespaces),
                            systemIcon: selectedIcon,
                            colorHex: selectedColor
                        )
                        modelContext.insert(album)
                        try? modelContext.save()
                        dismiss()
                    }
                    .disabled(trimmedName.isEmpty || isDuplicate)
                    .foregroundStyle(VNColor.accent)
                }
            }
        }
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespaces)
    }

    private var isDuplicate: Bool {
        existingAlbums.contains { $0.name.lowercased() == trimmedName.lowercased() }
    }
}
