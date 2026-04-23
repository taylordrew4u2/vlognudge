//
//  TimelineView.swift
//  VlogNudge
//
//  6:3:1 — Dominant bg, Secondary list rows & cards, Accent filter & actions.
//

import SwiftUI
import SwiftData
import AVKit
import UIKit

struct TimelineView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Clip.recordedAt, order: .reverse) private var clips: [Clip]
    @Query(sort: \VlogAlbum.sortOrder) private var albums: [VlogAlbum]
    @State private var selectedDate: Date = Date()
    @State private var previewClip: Clip?
    @State private var filterAlbumName: String?

    private var daysWithClips: Set<String> {
        Set(clips.map { $0.dayKey })
    }

    private var selectedDayClips: [Clip] {
        let key = DateHelpers.dayKey(from: selectedDate)
        return clips.filter { clip in
            clip.dayKey == key && (filterAlbumName == nil || clip.albumName == filterAlbumName)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: VNSpacing.lg) {
                    // Calendar date picker card
                    DatePicker("Day",
                               selection: $selectedDate,
                               displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .tint(VNColor.accent)
                    .vnCard()

                    // Clips list
                    if selectedDayClips.isEmpty {
                        VStack(spacing: VNSpacing.md) {
                            Image(systemName: "video.slash")
                                .font(.system(size: 40))
                                .foregroundStyle(VNColor.textTertiary)
                            Text("No clips this day")
                                .font(VNFont.subheadline)
                                .foregroundStyle(VNColor.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, VNSpacing.xxxl)
                    } else {
                        VStack(alignment: .leading, spacing: VNSpacing.sm) {
                            Text("Clips (\(selectedDayClips.count))")
                                .font(VNFont.caption)
                                .foregroundStyle(VNColor.textTertiary)
                                .padding(.horizontal, VNSpacing.xs)

                            VStack(spacing: 1) {
                                ForEach(selectedDayClips) { clip in
                                    Button {
                                        previewClip = clip
                                    } label: {
                                        ClipRow(clip: clip)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .clipShape(RoundedRectangle(cornerRadius: VNRadius.lg))
                        }

                        // Open in Photos button
                        Button {
                            openPhotosAlbum()
                        } label: {
                            HStack(spacing: VNSpacing.sm) {
                                Image(systemName: "arrow.up.forward.app.fill")
                                    .foregroundStyle(VNColor.accent)
                                Text("Open in Photos")
                                    .font(VNFont.subheadline)
                                    .foregroundStyle(VNColor.textPrimary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(VNColor.textTertiary)
                            }
                            .vnCard()
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, VNSpacing.lg)
                .padding(.top, VNSpacing.sm)
                .padding(.bottom, VNSpacing.huge)
            }
            .background(VNColor.dominant)
            .navigationTitle("Timeline")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            filterAlbumName = nil
                        } label: {
                            if filterAlbumName == nil {
                                Label("All Albums", systemImage: "checkmark")
                            } else {
                                Text("All Albums")
                            }
                        }
                        ForEach(albums) { album in
                            Button {
                                filterAlbumName = album.name
                            } label: {
                                if filterAlbumName == album.name {
                                    Label(album.name, systemImage: "checkmark")
                                } else {
                                    Text(album.name)
                                }
                            }
                        }
                    } label: {
                        Label(
                            filterAlbumName ?? "All",
                            systemImage: "line.3.horizontal.decrease.circle"
                        )
                        .foregroundStyle(VNColor.accent)
                    }
                }
            }
            .sheet(item: $previewClip) { clip in
                ClipPreviewView(clip: clip)
            }
        }
    }

    private func openPhotosAlbum() {
        if let url = URL(string: "photos-redirect://"),
           UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Clip Row (themed)

struct ClipRow: View {
    let clip: Clip

    var body: some View {
        HStack(spacing: VNSpacing.md) {
            RoundedRectangle(cornerRadius: VNRadius.sm)
                .fill(VNColor.secondaryLight)
                .frame(width: 56, height: 72)
                .overlay(
                    Image(systemName: "video.fill")
                        .foregroundStyle(VNColor.textTertiary)
                )

            VStack(alignment: .leading, spacing: VNSpacing.xs) {
                Text(clip.recordedAt, style: .time)
                    .font(VNFont.headline)
                    .foregroundStyle(VNColor.textPrimary)
                Text("\(Int(clip.duration))s")
                    .font(VNFont.caption)
                    .foregroundStyle(VNColor.textTertiary)
                if let prompt = clip.topicPrompt {
                    Text(prompt)
                        .font(VNFont.caption)
                        .foregroundStyle(VNColor.textSecondary)
                        .lineLimit(2)
                }
            }

            Spacer()

            if clip.starred {
                Image(systemName: "star.fill")
                    .foregroundStyle(VNColor.warning)
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(VNColor.textTertiary)
        }
        .padding(VNSpacing.md)
        .background(VNColor.secondary)
    }
}

// MARK: - Clip Preview (themed)

struct ClipPreviewView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let clip: Clip
    @State private var player: AVPlayer?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if let player {
                    VideoPlayer(player: player)
                        .onAppear { player.play() }
                } else {
                    VNColor.dominant
                        .overlay(
                            ProgressView()
                                .tint(VNColor.accent)
                        )
                }

                HStack {
                    Button {
                        clip.starred.toggle()
                        try? modelContext.save()
                    } label: {
                        Label(clip.starred ? "Starred" : "Star",
                              systemImage: clip.starred ? "star.fill" : "star")
                    }
                    .tint(VNColor.warning)
                    .buttonStyle(.bordered)

                    Spacer()

                    Button(role: .destructive) {
                        modelContext.delete(clip)
                        try? modelContext.save()
                        dismiss()
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    .tint(VNColor.destructive)
                    .buttonStyle(.bordered)
                }
                .padding(VNSpacing.lg)
                .background(VNColor.secondary)
            }
            .background(VNColor.dominant)
            .navigationTitle(clip.recordedAt.formatted(date: .abbreviated, time: .shortened))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(VNColor.accent)
                }
            }
            .task {
                if let avAsset = await PhotosService.fetchAVAsset(localIdentifier: clip.photosAssetID) {
                    let item = AVPlayerItem(asset: avAsset)
                    player = AVPlayer(playerItem: item)
                }
            }
        }
    }
}
