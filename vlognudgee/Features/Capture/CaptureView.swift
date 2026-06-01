//
//  CaptureView.swift
//  VlogNudge
//
//  6:3:1 — Full-screen camera with accent overlays and themed post-capture.
//

import SwiftUI
import SwiftData
import AVFoundation
import os

struct CaptureView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @State private var recordingService = RecordingService.shared
    @State private var recordingTimer: Timer?
    @State private var elapsedSeconds: Int = 0
    @State private var showPostRecord = false
    @State private var lastSavedClip: Clip?
    @State private var autoDismissTask: Task<Void, Never>?

    let initialPrompt: String?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            CameraPreviewView(session: recordingService.captureSession)
                .ignoresSafeArea()

            // Semi-transparent gradient at top for readability
            VStack {
                LinearGradient(
                    colors: [.black.opacity(0.5), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 120)
                Spacer()
                LinearGradient(
                    colors: [.clear, .black.opacity(0.4)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 200)
            }
            .ignoresSafeArea()

            VStack {
                topBar
                Spacer()
                if let prompt = initialPrompt, !prompt.isEmpty {
                    promptPill(prompt)
                }
                Spacer().frame(height: VNSpacing.xl)
                bottomBar
            }
            .padding(VNSpacing.lg)

            if showPostRecord {
                postRecordOverlay
            }
        }
        .statusBarHidden()
        .task {
            await setUp()
        }
        .onDisappear {
            autoDismissTask?.cancel()
            recordingService.stopSession()
        }
    }

    // MARK: - Setup

    private func setUp() async {
        let granted = await recordingService.requestPermissions()
        guard granted else { return }
        await recordingService.configureSession()
        recordingService.startSession()
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                    .padding(VNSpacing.md)
                    .background(.black.opacity(0.4), in: Circle())
            }

            Spacer()

            if let lastClipTime = lastClipTimeText() {
                Text(lastClipTime)
                    .font(VNFont.caption)
                    .foregroundStyle(.white.opacity(0.9))
                    .padding(.horizontal, VNSpacing.md)
                    .padding(.vertical, VNSpacing.sm)
                    .background(.black.opacity(0.4), in: Capsule())
            }

            Spacer()

            Button {
                recordingService.flipCamera()
            } label: {
                Image(systemName: "arrow.triangle.2.circlepath.camera")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .padding(VNSpacing.md)
                    .background(.black.opacity(0.4), in: Circle())
            }
        }
    }

    // MARK: - Prompt Pill

    private func promptPill(_ text: String) -> some View {
        Text(text)
            .font(VNFont.callout)
            .foregroundStyle(.white)
            .padding(.horizontal, VNSpacing.lg)
            .padding(.vertical, VNSpacing.md)
            .background(VNColor.secondary.opacity(0.8), in: Capsule())
            .padding(.horizontal, VNSpacing.xxxl)
            .multilineTextAlignment(.center)
    }

    // MARK: - Bottom Bar (record button)

    private var bottomBar: some View {
        VStack(spacing: VNSpacing.lg) {
            if recordingService.isRecording {
                HStack(spacing: VNSpacing.sm) {
                    Circle()
                        .fill(VNColor.destructive)
                        .frame(width: 8, height: 8)
                        .opacity(elapsedSeconds.isMultiple(of: 2) ? 1 : 0.3)
                    Text(formatElapsed(elapsedSeconds))
                        .font(.title3.monospacedDigit().bold())
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, VNSpacing.lg)
                .padding(.vertical, VNSpacing.sm)
                .background(.black.opacity(0.4), in: Capsule())
            }

            Button {
                toggleRecording()
            } label: {
                ZStack {
                    // Outer accent ring
                    Circle()
                        .stroke(VNColor.accent.opacity(0.6), lineWidth: 4)
                        .frame(width: 84, height: 84)

                    if recordingService.isRecording {
                        // Stop icon (rounded square)
                        RoundedRectangle(cornerRadius: 6)
                            .fill(VNColor.accent)
                            .frame(width: 32, height: 32)
                    } else {
                        // Record circle — accent colored
                        Circle()
                            .fill(VNColor.accent)
                            .frame(width: 68, height: 68)
                    }
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(recordingService.isRecording ? "Stop recording" : "Start recording")
        }
        .padding(.bottom, VNSpacing.xl)
    }

    // MARK: - Post Record Overlay

    private var postRecordOverlay: some View {
        ZStack {
            VNColor.dominant.opacity(0.92).ignoresSafeArea()
            VStack(spacing: VNSpacing.xl) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(VNColor.accent)
                Text("Clip saved")
                    .font(VNFont.title2)
                    .foregroundStyle(VNColor.textPrimary)
                if let clip = lastSavedClip {
                    HStack(spacing: VNSpacing.sm) {
                        Text(Int(clip.duration).description + "s")
                        Text("·")
                        Text(clip.recordedAt, style: .time)
                    }
                    .font(VNFont.callout)
                    .foregroundStyle(VNColor.textSecondary)

                    Button {
                        clip.starred.toggle()
                        try? modelContext.save()
                    } label: {
                        Label(clip.starred ? "Starred" : "Star", systemImage: clip.starred ? "star.fill" : "star")
                            .font(VNFont.headline)
                            .foregroundStyle(clip.starred ? VNColor.warning : VNColor.textSecondary)
                    }
                    .padding(.top, VNSpacing.md)
                }
            }
        }
    }

    // MARK: - Actions

    private func toggleRecording() {
        if recordingService.isRecording {
            recordingService.stopRecording()
            recordingTimer?.invalidate()
        } else {
            elapsedSeconds = 0
            recordingService.startRecording { result in
                Task { @MainActor in
                    handleRecordingFinished(result: result)
                }
            }
            recordingTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                elapsedSeconds += 1
            }
        }
    }

    @MainActor
    private func handleRecordingFinished(result: Result<RecordingService.RecordingResult, Error>) {
        switch result {
        case .success(let rec):
            Task {
                do {
                    let albumName = appState.activeAlbumName
                    let assetID = try await PhotosService.saveVideo(at: rec.fileURL, toAlbumNamed: albumName)
                    let clip = Clip(
                        recordedAt: rec.startDate,
                        duration: rec.duration,
                        photosAssetID: assetID,
                        topicPrompt: initialPrompt,
                        albumName: albumName
                    )
                    modelContext.insert(clip)
                    try modelContext.save()
                    lastSavedClip = clip

                    await NudgeScheduler.shared.clipWasFilmed(context: modelContext)

                    withAnimation { showPostRecord = true }
                    autoDismissTask = Task {
                        try? await Task.sleep(nanoseconds: 2_000_000_000)
                        guard !Task.isCancelled else { return }
                        dismiss()
                    }
                } catch {
                    Logger.capture.error("Failed to save clip: \(error.localizedDescription, privacy: .public)")
                    dismiss()
                }
            }
        case .failure(let error):
            Logger.capture.error("Recording failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func formatElapsed(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }

    private func lastClipTimeText() -> String? {
        var descriptor = FetchDescriptor<Clip>(
            sortBy: [SortDescriptor(\.recordedAt, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        guard let last = (try? modelContext.fetch(descriptor))?.first else {
            return "First clip of the day"
        }
        let minutes = DateHelpers.minutesAgo(from: last.recordedAt)
        if minutes < 60 {
            return "Last clip: \(minutes)m ago"
        } else {
            return "Last clip: \(minutes / 60)h \(minutes % 60)m ago"
        }
    }
}

// MARK: - Camera Preview UIKit Bridge

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewUIView {
        let view = PreviewUIView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewUIView, context: Context) {}

    final class PreviewUIView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var videoPreviewLayer: AVCaptureVideoPreviewLayer {
            layer as! AVCaptureVideoPreviewLayer
        }
    }
}
