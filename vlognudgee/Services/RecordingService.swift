//
//  RecordingService.swift
//  VlogNudge
//
//  AVCaptureSession wrapper. Vertical-only orientation lock.
//  Saves to temp file, then PhotosService moves it to the Daily Vlogs album.
//

import Foundation
import AVFoundation
import Observation
import os
import UIKit

@Observable
final class RecordingService: NSObject, @unchecked Sendable {
    static let shared = RecordingService()

    // Published state
    private var isConfigured = false
    var isRecording = false

    // AVCapture components
    private(set) var captureSession = AVCaptureSession()
    private var videoDeviceInput: AVCaptureDeviceInput?
    private var audioDeviceInput: AVCaptureDeviceInput?
    private let movieOutput = AVCaptureMovieFileOutput()
    private let sessionQueue = DispatchQueue(label: "vlognudge.session")

    // Recording state
    private var currentRecordingURL: URL?
    private var recordingStartDate: Date?
    private var completionHandler: ((Result<RecordingResult, Error>) -> Void)?

    struct RecordingResult {
        let fileURL: URL
        let startDate: Date
        let duration: TimeInterval
    }

    // Front or back camera
    enum CameraPosition { case front, back }
    private var currentPosition: CameraPosition = .back

    override init() {
        super.init()
    }

    // MARK: - Permissions

    func requestPermissions() async -> Bool {
        async let video = AVCaptureDevice.requestAccess(for: .video)
        async let audio = AVCaptureDevice.requestAccess(for: .audio)
        let (v, a) = await (video, audio)
        return v && a
    }

    // MARK: - Session Setup

    func configureSession() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            sessionQueue.async {
                do {
                    try self.configureSessionInternal()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func configureSessionInternal() throws {
        guard !isConfigured else { return }
        captureSession.beginConfiguration()
        defer { captureSession.commitConfiguration() }
        // Clean up a partial failed configuration before retrying.
        captureSession.inputs.forEach { captureSession.removeInput($0) }
        captureSession.outputs.forEach { captureSession.removeOutput($0) }
        videoDeviceInput = nil
        audioDeviceInput = nil
        currentPosition = .back
        captureSession.sessionPreset = .hd1920x1080

        // Video input
        if let videoDevice = AVCaptureDevice.default(
            .builtInWideAngleCamera,
            for: .video,
            position: .back
        ) {
            do {
                let input = try AVCaptureDeviceInput(device: videoDevice)
                if captureSession.canAddInput(input) {
                    captureSession.addInput(input)
                    videoDeviceInput = input
                }
            } catch {
                Logger.recording.error("Video device setup failed: \(error.localizedDescription, privacy: .public)")
            }
        }

        // Audio input
        if let audioDevice = AVCaptureDevice.default(for: .audio) {
            do {
                let input = try AVCaptureDeviceInput(device: audioDevice)
                if captureSession.canAddInput(input) {
                    captureSession.addInput(input)
                    audioDeviceInput = input
                }
            } catch {
                Logger.recording.error("Audio device setup failed: \(error.localizedDescription, privacy: .public)")
            }
        }

        // Movie output
        if captureSession.canAddOutput(movieOutput) {
            captureSession.addOutput(movieOutput)

            // Lock to portrait
            if let connection = movieOutput.connection(with: .video),
               connection.isVideoRotationAngleSupported(90) {
                connection.videoRotationAngle = 90  // portrait
            }
        }

        guard videoDeviceInput != nil, audioDeviceInput != nil,
              captureSession.outputs.contains(where: { $0 === movieOutput }) else {
            throw NSError(domain: "RecordingService", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "The camera or microphone is unavailable. Try again on your iPhone."])
        }
        isConfigured = true
    }

    func startSession() async -> Bool {
        await withCheckedContinuation { continuation in
            sessionQueue.async {
                if self.isConfigured && !self.captureSession.isRunning {
                    self.captureSession.startRunning()
                }
                continuation.resume(returning: self.captureSession.isRunning)
            }
        }
    }

    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self, self.captureSession.isRunning else { return }
            self.captureSession.stopRunning()
        }
    }

    // MARK: - Flip Camera

    func flipCamera() {
        sessionQueue.async { [weak self] in
            guard let self, !self.movieOutput.isRecording, self.completionHandler == nil,
                  let currentInput = self.videoDeviceInput else { return }
            self.captureSession.beginConfiguration()
            self.captureSession.removeInput(currentInput)

            let newPosition: AVCaptureDevice.Position =
                (self.currentPosition == .back) ? .front : .back

            if let newDevice = AVCaptureDevice.default(
                .builtInWideAngleCamera,
                for: .video,
                position: newPosition
            ) {
                do {
                    let newInput = try AVCaptureDeviceInput(device: newDevice)
                    if self.captureSession.canAddInput(newInput) {
                        self.captureSession.addInput(newInput)
                        self.videoDeviceInput = newInput
                        self.currentPosition = (newPosition == .back) ? .back : .front
                    } else {
                        self.captureSession.addInput(currentInput)
                    }
                } catch {
                    self.captureSession.addInput(currentInput)
                }
            } else {
                self.captureSession.addInput(currentInput)
            }

            // Re-lock orientation on the new connection
            if let connection = self.movieOutput.connection(with: .video),
               connection.isVideoRotationAngleSupported(90) {
                connection.videoRotationAngle = 90
            }

            self.captureSession.commitConfiguration()
        }
    }

    // MARK: - Record

    func startRecording(completion: @escaping (Result<RecordingResult, Error>) -> Void) {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            guard !self.movieOutput.isRecording, self.completionHandler == nil else { return }
            guard self.isConfigured, self.captureSession.isRunning else {
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "RecordingService", code: 2,
                        userInfo: [NSLocalizedDescriptionKey: "The camera is not ready. Close capture and try again."])))
                }
                return
            }

            let tempDir = FileManager.default.temporaryDirectory
            let filename = "vlog-\(UUID().uuidString).mov"
            let url = tempDir.appendingPathComponent(filename)

            self.currentRecordingURL = url
            self.recordingStartDate = Date()
            self.completionHandler = completion

            self.movieOutput.startRecording(to: url, recordingDelegate: self)

        }
    }

    func stopRecording() {
        sessionQueue.async { [weak self] in
            guard let self, self.movieOutput.isRecording else { return }
            self.movieOutput.stopRecording()
        }
    }
}

// MARK: - AVCaptureFileOutputRecordingDelegate

extension RecordingService: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput,
                    didStartRecordingTo fileURL: URL,
                    from connections: [AVCaptureConnection]) {
        DispatchQueue.main.async { self.isRecording = true }
    }

    func fileOutput(_ output: AVCaptureFileOutput,
                    didFinishRecordingTo outputFileURL: URL,
                    from connections: [AVCaptureConnection],
                    error: Error?) {

        // All session state is owned by sessionQueue; deliver the result on main.
        sessionQueue.async {
            let completion = self.completionHandler
            let startDate = self.recordingStartDate ?? Date()
            let duration = max(0, CMTimeGetSeconds(output.recordedDuration))
            let result: Result<RecordingResult, Error>
            if let error = error as NSError?,
               error.userInfo[AVErrorRecordingSuccessfullyFinishedKey] as? Bool != true {
                result = .failure(error)
            } else {
                result = .success(RecordingResult(fileURL: outputFileURL,
                    startDate: startDate, duration: duration.isFinite ? duration : 0))
            }
            self.completionHandler = nil
            self.recordingStartDate = nil
            self.currentRecordingURL = nil
            DispatchQueue.main.async {
                self.isRecording = false
                completion?(result)
            }
        }
    }
}
