//
//  IdeasView.swift
//  VlogNudge
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
                    ContentUnavailableView {
                        Label("No ideas yet", systemImage: "lightbulb")
                    } description: {
                        Text("Hit the button below the next time a vlog idea hits you — we'll surface it as a prompt on your next nudge.")
                    }
                } else {
                    List {
                        ForEach(memos) { memo in
                            IdeaRow(memo: memo)
                        }
                        .onDelete(perform: delete)
                    }
                }
            }
            .navigationTitle("Ideas")
            .safeAreaInset(edge: .bottom) {
                Button {
                    showRecorder = true
                } label: {
                    HStack {
                        Image(systemName: "mic.fill")
                        Text("Capture idea")
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue, in: RoundedRectangle(cornerRadius: 14))
                    .padding()
                }
                .buttonStyle(.plain)
            }
            .sheet(isPresented: $showRecorder) {
                IdeaRecorderView()
            }
        }
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            let memo = memos[index]
            if let path = memo.audioFilePath {
                try? FileManager.default.removeItem(atPath: path)
            }
            modelContext.delete(memo)
        }
        try? modelContext.save()
    }
}

struct IdeaRow: View {
    @Environment(\.modelContext) private var modelContext
    let memo: IdeaMemo
    @State private var isPlaying = false
    @State private var player: AVAudioPlayer?

    var body: some View {
        HStack {
            Button {
                togglePlayback()
            } label: {
                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.title)
                    .foregroundStyle(.blue)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(memo.createdAt, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(memo.createdAt, style: .time)
                    .font(.headline)
            }

            Spacer()

            if memo.usedAt != nil {
                Label("Used", systemImage: "checkmark.circle.fill")
                    .labelStyle(.iconOnly)
                    .foregroundStyle(.green)
            }
        }
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

// MARK: - Recorder

struct IdeaRecorderView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var recorder: AVAudioRecorder?
    @State private var isRecording = false
    @State private var elapsed: Int = 0
    @State private var timer: Timer?

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "mic.circle.fill")
                .font(.system(size: 120))
                .foregroundStyle(isRecording ? .red : .blue)
                .symbolEffect(.pulse, isActive: isRecording)

            Text(isRecording ? "Recording \(elapsed)s" : "Tap the button to start")
                .font(.title2.bold())

            Spacer()

            Button {
                toggleRecording()
            } label: {
                Text(isRecording ? "Stop and save" : "Start recording")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isRecording ? Color.red : Color.blue,
                                in: RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
            .padding()

            Button("Cancel") { dismiss() }
                .foregroundStyle(.secondary)
                .padding(.bottom)
        }
        .onAppear {
            prepareAudioSession()
        }
    }

    private func prepareAudioSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playAndRecord, mode: .default)
        try? session.setActive(true)
        session.requestRecordPermission { _ in }
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
