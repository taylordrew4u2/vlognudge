//
//  TimelineView.swift
//  VlogNudge
//

import SwiftUI
import SwiftData
import AVKit
import UIKit

struct TimelineView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Clip.recordedAt, order: .reverse) private var clips: [Clip]
    @State private var selectedDate: Date = Date()
    @State private var previewClip: Clip?

    private var daysWithClips: Set<String> {
        Set(clips.map { $0.dayKey })
    }

    private var selectedDayClips: [Clip] {
        let key = DateHelpers.dayKey(from: selectedDate)
        return clips.filter { $0.dayKey == key }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    DatePicker("Day",
                               selection: $selectedDate,
                               displayedComponents: .date)
                    .datePickerStyle(.graphical)
                }

                if selectedDayClips.isEmpty {
                    Section {
                        Text("No clips this day")
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Section("Clips (\(selectedDayClips.count))") {
                        ForEach(selectedDayClips) { clip in
                            Button {
                                previewClip = clip
                            } label: {
                                ClipRow(clip: clip)
                            }
                            .buttonStyle(.plain)
                            .swipeActions {
                                Button(clip.starred ? "Unstar" : "Star") {
                                    clip.starred.toggle()
                                    try? modelContext.save()
                                }
                                .tint(.yellow)
                            }
                        }
                    }

                    Section {
                        Button {
                            openPhotosAlbum()
                        } label: {
                            Label("Open album in Photos (for CapCut)", systemImage: "arrow.up.forward.app.fill")
                        }
                    } footer: {
                        Text("Photos → Daily Vlogs album → tap Select → share to CapCut.")
                    }
                }
            }
            .navigationTitle("Timeline")
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

struct ClipRow: View {
    let clip: Clip

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.secondary.opacity(0.2))
                .frame(width: 60, height: 80)
                .overlay(Image(systemName: "video.fill").foregroundStyle(.secondary))

            VStack(alignment: .leading, spacing: 4) {
                Text(clip.recordedAt, style: .time)
                    .font(.headline)
                Text("\(Int(clip.duration))s")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let prompt = clip.topicPrompt {
                    Text(prompt)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer()

            if clip.starred {
                Image(systemName: "star.fill")
                    .foregroundStyle(.yellow)
            }
        }
    }
}

struct ClipPreviewView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let clip: Clip
    @State private var player: AVPlayer?

    var body: some View {
        NavigationStack {
            VStack {
                if let player {
                    VideoPlayer(player: player)
                        .onAppear { player.play() }
                } else {
                    ProgressView()
                        .frame(maxHeight: .infinity)
                }

                HStack {
                    Button {
                        clip.starred.toggle()
                        try? modelContext.save()
                    } label: {
                        Label(clip.starred ? "Starred" : "Star",
                              systemImage: clip.starred ? "star.fill" : "star")
                    }
                    .buttonStyle(.bordered)

                    Spacer()

                    Button(role: .destructive) {
                        modelContext.delete(clip)
                        try? modelContext.save()
                        dismiss()
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            }
            .navigationTitle(clip.recordedAt.formatted(date: .abbreviated, time: .shortened))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .task {
                if let avAsset = PhotosService.fetchAVAsset(localIdentifier: clip.photosAssetID) {
                    let item = AVPlayerItem(asset: avAsset)
                    player = AVPlayer(playerItem: item)
                }
            }
        }
    }
}
