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
import UIKit

@Observable
final class RecordingService: NSObject, @unchecked Sendable {
    static let shared = RecordingService()

    // Published state
    var isSessionRunning = false
    var isRecording = false
    var errorMessage: String?

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
    private(set) var currentPosition: CameraPosition = .back

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

    func configureSession() async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            sessionQueue.async { [weak self] in
                self?.configureSessionInternal()
                continuation.resume()
            }
        }
    }

    private func configureSessionInternal() {
        captureSession.beginConfiguration()
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
                DispatchQueue.main.async {
                    self.errorMessage = "Video device setup failed: \(error.localizedDescription)"
                }
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
                DispatchQueue.main.async {
                    self.errorMessage = "Audio device setup failed: \(error.localizedDescription)"
                }
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

        captureSession.commitConfiguration()
    }

    func startSession() {
        sessionQueue.async { [weak self] in
            guard let self, !self.captureSession.isRunning else { return }
            self.captureSession.startRunning()
            DispatchQueue.main.async { self.isSessionRunning = true }
        }
    }

    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self, self.captureSession.isRunning else { return }
            self.captureSession.stopRunning()
            DispatchQueue.main.async { self.isSessionRunning = false }
        }
    }

    // MARK: - Flip Camera

    func flipCamera() {
        sessionQueue.async { [weak self] in
            guard let self, let currentInput = self.videoDeviceInput else { return }
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
                        DispatchQueue.main.async {
                            self.currentPosition = (newPosition == .back) ? .back : .front
                        }
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
            guard !self.movieOutput.isRecording else { return }

            let tempDir = FileManager.default.temporaryDirectory
            let filename = "vlog-\(UUID().uuidString).mov"
            let url = tempDir.appendingPathComponent(filename)

            self.currentRecordingURL = url
            self.recordingStartDate = Date()
            self.completionHandler = completion

            self.movieOutput.startRecording(to: url, recordingDelegate: self)

            DispatchQueue.main.async { self.isRecording = true }
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
                    didFinishRecordingTo outputFileURL: URL,
                    from connections: [AVCaptureConnection],
                    error: Error?) {

        DispatchQueue.main.async { self.isRecording = false }

        guard let startDate = recordingStartDate else { return }
        let duration = Date().timeIntervalSince(startDate)

        if let error = error as NSError?,
           error.userInfo[AVErrorRecordingSuccessfullyFinishedKey] as? Bool != true {
            completionHandler?(.failure(error))
        } else {
            let result = RecordingResult(
                fileURL: outputFileURL,
                startDate: startDate,
                duration: duration
            )
            completionHandler?(.success(result))
        }

        completionHandler = nil
        recordingStartDate = nil
        currentRecordingURL = nil
    }
}
