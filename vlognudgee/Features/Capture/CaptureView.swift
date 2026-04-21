//
//  CaptureView.swift
//  VlogNudge
//

import SwiftUI
import SwiftData
import AVFoundation

struct CaptureView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var recordingService = RecordingService.shared
    @State private var recordingTimer: Timer?
    @State private var elapsedSeconds: Int = 0
    @State private var showPostRecord = false
    @State private var lastSavedClip: Clip?

    let initialPrompt: String?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // Camera preview
            CameraPreviewView(session: recordingService.captureSession)
                .ignoresSafeArea()

            // Overlay
            VStack {
                topBar
                Spacer()
                if let prompt = initialPrompt, !prompt.isEmpty {
                    promptPill(prompt)
                }
                Spacer().frame(height: 20)
                bottomBar
            }
            .padding()

            if showPostRecord {
                postRecordOverlay
            }
        }
        .statusBarHidden()
        .task {
            await setUp()
        }
        .onDisappear {
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

    // MARK: - Subviews

    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                    .padding(12)
                    .background(.black.opacity(0.5), in: Circle())
            }

            Spacer()

            if let lastClipTime = lastClipTimeText() {
                Text(lastClipTime)
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.black.opacity(0.5), in: Capsule())
            }

            Spacer()

            Button {
                recordingService.flipCamera()
            } label: {
                Image(systemName: "arrow.triangle.2.circlepath.camera")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .padding(12)
                    .background(.black.opacity(0.5), in: Circle())
            }
        }
    }

    private func promptPill(_ text: String) -> some View {
        Text(text)
            .font(.callout)
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.black.opacity(0.6), in: Capsule())
            .padding(.horizontal, 40)
            .multilineTextAlignment(.center)
    }

    private var bottomBar: some View {
        VStack(spacing: 16) {
            if recordingService.isRecording {
                HStack(spacing: 6) {
                    Circle()
                        .fill(.red)
                        .frame(width: 8, height: 8)
                        .opacity(elapsedSeconds.isMultiple(of: 2) ? 1 : 0.3)
                    Text(formatElapsed(elapsedSeconds))
                        .font(.title3.monospacedDigit().bold())
                        .foregroundStyle(.white)
                }
            }

            Button {
                toggleRecording()
            } label: {
                ZStack {
                    Circle()
                        .stroke(.white, lineWidth: 4)
                        .frame(width: 80, height: 80)

                    if recordingService.isRecording {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(.red)
                            .frame(width: 32, height: 32)
                    } else {
                        Circle()
                            .fill(.red)
                            .frame(width: 64, height: 64)
                    }
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.bottom, 20)
    }

    private var postRecordOverlay: some View {
        ZStack {
            Color.black.opacity(0.85).ignoresSafeArea()
            VStack(spacing: 20) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.green)
                Text("Clip saved")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                if let clip = lastSavedClip {
                    HStack {
                        Text(Int(clip.duration).description + "s")
                        Text("•")
                        Text(clip.recordedAt, style: .time)
                    }
                    .foregroundStyle(.white.opacity(0.7))

                    Button {
                        clip.starred.toggle()
                        try? modelContext.save()
                    } label: {
                        Label(clip.starred ? "Starred" : "Star", systemImage: clip.starred ? "star.fill" : "star")
                            .font(.headline)
                            .foregroundStyle(clip.starred ? .yellow : .white)
                    }
                    .padding(.top, 12)
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
                    let assetID = try await PhotosService.saveVideo(at: rec.fileURL)
                    let clip = Clip(
                        recordedAt: rec.startDate,
                        duration: rec.duration,
                        photosAssetID: assetID,
                        topicPrompt: initialPrompt
                    )
                    modelContext.insert(clip)
                    try modelContext.save()
                    lastSavedClip = clip

                    // Tell scheduler a clip was filmed
                    await NudgeScheduler.shared.clipWasFilmed(context: modelContext)

                    withAnimation { showPostRecord = true }
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                    dismiss()
                } catch {
                    print("Failed to save clip: \(error)")
                    dismiss()
                }
            }
        case .failure(let error):
            print("Recording failed: \(error)")
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
