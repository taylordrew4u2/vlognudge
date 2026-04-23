//
//  HomeView.swift
//  VlogNudge
//
//  Main landing screen: album grid, today's progress, and record button.
//  6:3:1 — Dominant bg, Secondary cards, Accent CTAs & active states.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState

    @Query(sort: \VlogAlbum.sortOrder) private var albums: [VlogAlbum]
    @Query(sort: \Clip.recordedAt, order: .reverse) private var allClips: [Clip]
    @Query private var settingsArray: [UserSettings]

    @State private var showNewAlbumSheet = false

    private var settings: UserSettings {
        settingsArray.first ?? UserSettings()
    }

    private var todayClips: [Clip] {
        let today = DateHelpers.dayKey(from: Date())
        return allClips.filter { $0.dayKey == today }
    }

    private var target: Int {
        settings.frequency.baselineCountPerDay == 0
            ? 8
            : settings.frequency.baselineCountPerDay
    }

    private var progressFraction: Double {
        min(1.0, Double(todayClips.count) / Double(max(1, target)))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: VNSpacing.xxl) {
                    todayProgress
                    albumsSection
                    recordSection
                }
                .padding(.horizontal, VNSpacing.lg)
                .padding(.top, VNSpacing.sm)
                .padding(.bottom, VNSpacing.huge)
            }
            .background(VNColor.dominant)
            .navigationTitle("VlogNudge")
            .sheet(isPresented: $showNewAlbumSheet) {
                NewAlbumSheet()
            }
        }
    }

    // MARK: - Today Progress Ring Card

    private var todayProgress: some View {
        HStack(spacing: VNSpacing.lg) {
            VStack(alignment: .leading, spacing: VNSpacing.xs) {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("\(todayClips.count)")
                        .font(VNFont.heroNumber)
                        .foregroundStyle(VNColor.textPrimary)
                    Text("/\(target)")
                        .font(VNFont.title3)
                        .foregroundStyle(VNColor.textTertiary)
                }
                Text("clips today")
                    .font(VNFont.caption)
                    .foregroundStyle(VNColor.textSecondary)
            }

            Spacer()

            // Progress ring — accent color
            ZStack {
                Circle()
                    .stroke(VNColor.textTertiary.opacity(0.15), lineWidth: 7)
                Circle()
                    .trim(from: 0, to: progressFraction)
                    .stroke(
                        VNColor.accent,
                        style: StrokeStyle(lineWidth: 7, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.6), value: progressFraction)

                Text("\(Int(progressFraction * 100))%")
                    .font(VNFont.caption)
                    .foregroundStyle(VNColor.accent)
            }
            .frame(width: 64, height: 64)
        }
        .vnCard()
    }

    // MARK: - Albums Grid

    private var albumsSection: some View {
        VStack(alignment: .leading, spacing: VNSpacing.md) {
            HStack {
                Text("Albums")
                    .font(VNFont.title3)
                    .foregroundStyle(VNColor.textPrimary)
                Spacer()
                Button {
                    showNewAlbumSheet = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(VNColor.accent)
                }
            }

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: VNSpacing.md),
                    GridItem(.flexible(), spacing: VNSpacing.md)
                ],
                spacing: VNSpacing.md
            ) {
                ForEach(albums) { album in
                    AlbumCard(
                        album: album,
                        clipCount: allClips.filter { $0.albumName == album.name }.count,
                        isActive: appState.activeAlbumName == album.name
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            appState.activeAlbumName = album.name
                        }
                    }
                }
            }
        }
    }

    // MARK: - Record Button

    private var recordSection: some View {
        VStack(spacing: VNSpacing.md) {
            if let album = albums.first(where: { $0.name == appState.activeAlbumName }) {
                HStack(spacing: VNSpacing.sm) {
                    Image(systemName: album.systemIcon)
                        .foregroundStyle(VNColor.accent)
                    Text("Saving to \(album.name)")
                        .font(VNFont.subheadline)
                        .foregroundStyle(VNColor.textSecondary)
                }
            }

            Button {
                appState.requestCapture(prompt: nil)
            } label: {
                HStack(spacing: VNSpacing.sm) {
                    Image(systemName: "video.circle.fill")
                        .font(.title2)
                    Text("Record")
                        .font(VNFont.title3)
                }
                .foregroundStyle(VNColor.dominant)
                .frame(maxWidth: .infinity)
                .padding(.vertical, VNSpacing.xl)
                .background(VNColor.accent, in: RoundedRectangle(cornerRadius: VNRadius.lg))
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Album Card (6:3:1 themed)

struct AlbumCard: View {
    let album: VlogAlbum
    let clipCount: Int
    let isActive: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: VNSpacing.sm) {
                Image(systemName: album.systemIcon)
                    .font(.title)
                    .foregroundStyle(isActive ? VNColor.accent : VNColor.textSecondary)

                Spacer()

                Text(album.name)
                    .font(VNFont.headline)
                    .foregroundStyle(VNColor.textPrimary)
                    .lineLimit(1)

                Text("\(clipCount) clips")
                    .font(VNFont.caption)
                    .foregroundStyle(VNColor.textTertiary)
            }
            .padding(VNSpacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 140)
            .background(
                isActive ? VNColor.secondaryLight : VNColor.secondary,
                in: RoundedRectangle(cornerRadius: VNRadius.lg)
            )
            .overlay(
                RoundedRectangle(cornerRadius: VNRadius.lg)
                    .stroke(isActive ? VNColor.accent : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(album.name), \(clipCount) clips\(isActive ? ", active" : "")")
    }
}
