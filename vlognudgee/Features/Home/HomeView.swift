import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Query(sort: \VlogAlbum.sortOrder) private var albums: [VlogAlbum]
    @Query(sort: \Clip.recordedAt, order: .reverse) private var allClips: [Clip]
    @State private var showNewAlbumSheet = false

    private var todayClips: [Clip] {
        allClips.filter { Calendar.current.isDateInToday($0.recordedAt) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: VNSpacing.xxxl) {
                    captureHero
                    dailyNote
                    albumsSection
                }
                .padding(VNSpacing.xxl)
                .padding(.bottom, VNSpacing.xxl)
            }
            .background(VNColor.dominant)
            .navigationTitle("VlogNudge")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Image("VlogNudgeMark")
                        .resizable().scaledToFit()
                        .frame(width: 30, height: 30)
                        .accessibilityHidden(true)
                }
            }
            .sheet(isPresented: $showNewAlbumSheet) { NewAlbumSheet() }
        }
    }

    private var captureHero: some View {
        VStack(alignment: .leading, spacing: VNSpacing.xl) {
            Text(Date.now, format: .dateTime.weekday(.wide).month(.abbreviated).day())
                .font(VNFont.caption)
                .textCase(.uppercase)
                .tracking(1.5)
                .foregroundStyle(VNColor.textSecondary)
            Text("Keep the\nlittle things.")
                .font(VNFont.largeTitle)
                .foregroundStyle(VNColor.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            Text("A few seconds of today, worth keeping.")
                .font(VNFont.body)
                .foregroundStyle(VNColor.textSecondary)
            Button {
                appState.requestCapture(prompt: nil)
            } label: {
                HStack(spacing: VNSpacing.md) {
                    Image(systemName: "record.circle")
                        .font(.title2)
                    Text("Record a moment").font(VNFont.headline)
                    Spacer(minLength: 0)
                    Image(systemName: "arrow.up.right")
                }
                .padding(VNSpacing.xl)
                .foregroundStyle(VNColor.onAccent)
                .background(VNColor.accent, in: RoundedRectangle(cornerRadius: VNRadius.md))
            }
            .buttonStyle(.plain)
            Label("Saving to \(appState.activeAlbumName)", systemImage: "folder")
                .font(VNFont.caption)
                .foregroundStyle(VNColor.textSecondary)
        }
    }

    private var dailyNote: some View {
        HStack(alignment: .top, spacing: VNSpacing.lg) {
            Text(todayClips.count.formatted())
                .font(VNFont.heroNumber)
                .foregroundStyle(VNColor.accent)
            VStack(alignment: .leading, spacing: VNSpacing.xs) {
                Text("Moments today").font(VNFont.headline)
                Text(todayClips.isEmpty ? "Start with something small." : "A little collection of your day.")
                    .font(VNFont.footnote)
                    .foregroundStyle(VNColor.textSecondary)
            }
            Spacer(minLength: 0)
        }
        .foregroundStyle(VNColor.textPrimary)
        .padding(.vertical, VNSpacing.xl)
        .overlay(alignment: .top) { Rectangle().fill(VNColor.border).frame(height: 1) }
        .overlay(alignment: .bottom) { Rectangle().fill(VNColor.border).frame(height: 1) }
        .accessibilityElement(children: .combine)
    }

    private var albumsSection: some View {
        VStack(alignment: .leading, spacing: VNSpacing.lg) {
            HStack {
                Text("Your collections").font(VNFont.title2)
                Spacer()
                Button { showNewAlbumSheet = true } label: {
                    Image(systemName: "plus")
                        .font(.headline)
                        .frame(width: 44, height: 44)
                        .background(VNColor.secondaryLight, in: Circle())
                }
                .accessibilityLabel("Create album")
            }
            .foregroundStyle(VNColor.textPrimary)
            if albums.isEmpty {
                Text("Your first clips will go into Daily Vlogs. Add a collection for a trip, project, or everyday life.")
                    .font(VNFont.body)
                    .foregroundStyle(VNColor.textSecondary)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: dynamicTypeSize.isAccessibilitySize ? 260 : 145), spacing: VNSpacing.md)], spacing: VNSpacing.md) {
                    ForEach(albums) { album in
                        AlbumCard(album: album,
                                  clipCount: allClips.filter { $0.albumName == album.name }.count,
                                  isActive: appState.activeAlbumName == album.name) {
                            appState.activeAlbumName = album.name
                        }
                    }
                }
            }
        }
    }
}

struct AlbumCard: View {
    let album: VlogAlbum
    let clipCount: Int
    let isActive: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: VNSpacing.lg) {
                HStack {
                    Image(systemName: album.systemIcon).font(.title2)
                    Spacer()
                    if isActive { Image(systemName: "checkmark.circle.fill") }
                }
                .foregroundStyle(VNColor.accent)
                VStack(alignment: .leading, spacing: VNSpacing.xs) {
                    Text(album.name).font(VNFont.headline)
                        .fixedSize(horizontal: false, vertical: true)
                        .foregroundStyle(VNColor.textPrimary)
                    Text("\(clipCount) clips").font(VNFont.caption)
                        .foregroundStyle(VNColor.textSecondary)
                }
            }
            .padding(VNSpacing.xl)
            .frame(maxWidth: .infinity, minHeight: 150, alignment: .topLeading)
            .background(isActive ? VNColor.secondaryLight : VNColor.secondary,
                        in: RoundedRectangle(cornerRadius: VNRadius.md))
            .overlay {
                RoundedRectangle(cornerRadius: VNRadius.md)
                    .strokeBorder(isActive ? VNColor.accent : VNColor.border, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(album.name), \(clipCount) clips")
        .accessibilityValue(isActive ? "Selected for recording" : "")
        .accessibilityHint("Select this album for new recordings")
    }
}
