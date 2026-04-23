//
//  IdeasView.swift
//  VlogNudge
//
//  6:3:1 — Dominant bg, Secondary list rows, Accent play/record controls.
//

import SwiftUI
import SwiftData
import AVFoundation

struct IdeasView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \IdeaMemo.createdAt, order: .reverse) private var memos: [IdeaMemo]
    @State private var showRecorder = false

    var body: some View {
        NavigationStack {
            Group {
                if memos.isEmpty {
                    VStack(spacing: VNSpacing.lg) {
                        Image(systemName: "lightbulb")
                            .font(.system(size: 56))
                            .foregroundStyle(VNColor.textTertiary)
                        Text("No ideas yet")
                            .font(VNFont.title2)
                            .foregroundStyle(VNColor.textPrimary)
                        Text("Hit the button below the next time a vlog idea hits you — we'll surface it as a prompt on your next nudge.")
                            .font(VNFont.callout)
                            .foregroundStyle(VNColor.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, VNSpacing.xxxl)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(VNColor.dominant)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 1) {
                            ForEach(memos) { memo in
                                IdeaRow(memo: memo, onDelete: { deleteMemo(memo) })
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: VNRadius.lg))
                        .padding(.horizontal, VNSpacing.lg)
                        .padding(.top, VNSpacing.sm)
                        .padding(.bottom, 100) // room for bottom button
                    }
                    .background(VNColor.dominant)
                }
            }
            .navigationTitle("Ideas")
            .safeAreaInset(edge: .bottom) {
                Button {
                    showRecorder = true
                } label: {
                    HStack(spacing: VNSpacing.sm) {
                        Image(systemName: "mic.fill")
                        Text("Capture idea")
                    }
                    .font(VNFont.headline)
                    .foregroundStyle(VNColor.dominant)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, VNSpacing.lg)
                    .background(VNColor.accent, in: RoundedRectangle(cornerRadius: VNRadius.lg))
                    .padding(.horizontal, VNSpacing.lg)
                    .padding(.bottom, VNSpacing.sm)
                }
                .buttonStyle(.plain)
                .background(
                    LinearGradient(
                        colors: [VNColor.dominant, VNColor.dominant.opacity(0)],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                    .frame(height: 40)
                    .allowsHitTesting(false),
                    alignment: .top
                )
            }
            .sheet(isPresented: $showRecorder) {
                IdeaRecorderView()
            }
        }
    }

    private func deleteMemo(_ memo: IdeaMemo) {
        if let path = memo.audioFilePath {
            try? FileManager.default.removeItem(atPath: path)
        }
        modelContext.delete(memo)
        try? modelContext.save()
    }
}

// MARK: - Idea Row (themed)

struct IdeaRow: View {
    @Environment(\.modelContext) private var modelContext
    let memo: IdeaMemo
    let onDelete: () -> Void
    @State private var isPlaying = false
    @State private var player: AVAudioPlayer?

    var body: some View {
        HStack(spacing: VNSpacing.md) {
            Button {
                togglePlayback()
            } label: {
                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 38))
                    .foregroundStyle(VNColor.accent)
            }

            VStack(alignment: .leading, spacing: VNSpacing.xs) {
                Text(memo.createdAt, style: .date)
                    .font(VNFont.caption)
                    .foregroundStyle(VNColor.textTertiary)
                Text(memo.createdAt, style: .time)
                    .font(VNFont.headline)
                    .foregroundStyle(VNColor.textPrimary)
            }

            Spacer()

            if memo.usedAt != nil {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(VNColor.success)
            }

            Button(role: .destructive) {
                onDelete()
            } label: {
                Image(systemName: "trash")
                    .font(.subheadline)
                    .foregroundStyle(VNColor.textTertiary)
            }
        }
        .padding(VNSpacing.lg)
        .background(VNColor.secondary)
        .accessibilityLabel("Idea from \(memo.createdAt.formatted())")
    }

    private func togglePlayback() {
        if isPlaying {
            player?.stop()
            isPlaying = false
            return
        }
        guard let path = memo.audioFilePath else { return }
        let url = URL(fileURLWithPath: path)
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.play()
            isPlaying = true
        } catch {
            print("Playback error: \(error)")
        }
    }
}

// MARK: - Recorder (themed)

struct IdeaRecorderView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var recorder: AVAudioRecorder?
    @State private var isRecording = false
    @State private var elapsed: Int = 0
    @State private var timer: Timer?

    var body: some View {
        VStack(spacing: VNSpacing.xxxl) {
            Spacer()

            ZStack {
                // Glow ring when recording
                if isRecording {
                    Circle()
                        .fill(VNColor.accentGlow)
                        .frame(width: 160, height: 160)
                }

                Image(systemName: "mic.circle.fill")
                    .font(.system(size: 120))
                    .foregroundStyle(isRecording ? VNColor.accent : VNColor.textTertiary)
                    .symbolEffect(.pulse, isActive: isRecording)
            }
            .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: isRecording)

            Text(isRecording ? "Recording \(elapsed)s" : "Tap the button to start")
                .font(VNFont.title2)
                .foregroundStyle(VNColor.textPrimary)

            Spacer()

            Button {
                toggleRecording()
            } label: {
                Text(isRecording ? "Stop and save" : "Start recording")
                    .font(VNFont.headline)
                    .foregroundStyle(isRecording ? VNColor.textPrimary : VNColor.dominant)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, VNSpacing.lg)
                    .background(
                        isRecording ? VNColor.destructive : VNColor.accent,
                        in: RoundedRectangle(cornerRadius: VNRadius.lg)
                    )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, VNSpacing.lg)

            Button("Cancel") { dismiss() }
                .font(VNFont.subheadline)
                .foregroundStyle(VNColor.textSecondary)
                .padding(.bottom, VNSpacing.lg)
        }
        .background(VNColor.dominant)
        .onAppear {
            prepareAudioSession()
        }
    }

    private func prepareAudioSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playAndRecord, mode: .default)
        try? session.setActive(true)
        AVAudioApplication.requestRecordPermission { _ in }
    }

    private func toggleRecording() {
        if isRecording {
            stopAndSave()
        } else {
            startRecording()
        }
    }

    private func startRecording() {
        let filename = "idea-\(UUID().uuidString).m4a"
        let url = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(filename)

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue
        ]

        do {
            recorder = try AVAudioRecorder(url: url, settings: settings)
            recorder?.record()
            isRecording = true
            elapsed = 0
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                elapsed += 1
                if elapsed >= 30 { stopAndSave() }
            }
        } catch {
            print("Recorder error: \(error)")
        }
    }

    private func stopAndSave() {
        recorder?.stop()
        timer?.invalidate()
        let url = recorder?.url
        isRecording = false

        if let url {
            let memo = IdeaMemo(audioFilePath: url.path)
            modelContext.insert(memo)
            try? modelContext.save()
        }

        dismiss()
    }
}
