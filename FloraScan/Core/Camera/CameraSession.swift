//
//  CameraSession.swift
//  FloraScan
//
//  Created by José Luis Corral López on 28/4/26.
//

import AVFoundation
import CoreImage
import SwiftUI
import os

@MainActor
@Observable
final class CameraSession {
    enum Status: Equatable {
        case idle, running, denied, failed(String)
    }

    private(set) var status: Status = .idle

    // AVFoundation objects live on the camera queue.
    nonisolated(unsafe) let session = AVCaptureSession()
    private let queue = DispatchQueue(label: "io.jlcl11.florascan.camera")
    nonisolated(unsafe) private let videoOutput = AVCaptureVideoDataOutput()
    nonisolated(unsafe) private let photoOutput = AVCapturePhotoOutput()
    private let delegate = CameraSessionDelegate()

    func start(onFrame: @escaping @Sendable (CIImage, CGImagePropertyOrientation) -> Void) async {
        delegate.onFrame = onFrame

        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            await configureAndStart()
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            if granted { await configureAndStart() } else { status = .denied }
        default:
            status = .denied
        }
    }

    func stop() {
        delegate.onFrame = nil
        delegate.onPhoto = nil
        queue.async { [weak self] in
            self?.session.stopRunning()
        }
    }

    func capturePhoto(completion: @escaping @Sendable (Data?) -> Void) {
        delegate.onPhoto = completion
        let settings = AVCapturePhotoSettings()
        settings.photoQualityPrioritization = .balanced
        photoOutput.capturePhoto(with: settings, delegate: delegate)
    }

    /// Capture a single photo with 10s timeout.
    /// Uses a lock-protected flag to guarantee the continuation resumes exactly once.
    func capturePhotoData() async -> Data? {
        await withCheckedContinuation { continuation in
            let resumed = OSAllocatedUnfairLock(initialState: false)

            Task {
                try? await Task.sleep(for: .seconds(10))
                let alreadyResumed = resumed.withLock { r -> Bool in
                    if r { return true }
                    r = true
                    return false
                }
                guard !alreadyResumed else { return }
                continuation.resume(returning: nil)
            }

            capturePhoto { data in
                let alreadyResumed = resumed.withLock { r -> Bool in
                    if r { return true }
                    r = true
                    return false
                }
                guard !alreadyResumed else { return }
                continuation.resume(returning: data)
            }
        }
    }

    private func configureAndStart() async {
        await withCheckedContinuation { cont in
            queue.async { [weak self] in
                guard let self else { cont.resume(); return }

                // If already configured, just restart
                if !self.session.inputs.isEmpty {
                    self.videoOutput.setSampleBufferDelegate(self.delegate, queue: self.queue)
                    if !self.session.isRunning {
                        self.session.startRunning()
                    }
                    Task { @MainActor in self.status = .running }
                    cont.resume()
                    return
                }

                self.session.beginConfiguration()
                self.session.sessionPreset = .high

                guard let device = AVCaptureDevice.default(
                    .builtInWideAngleCamera, for: .video, position: .back
                ),
                let input = try? AVCaptureDeviceInput(device: device),
                self.session.canAddInput(input) else {
                    Task { @MainActor in self.status = .failed("Camera not available.") }
                    self.session.commitConfiguration()
                    cont.resume()
                    return
                }

                self.session.addInput(input)

                self.videoOutput.alwaysDiscardsLateVideoFrames = true
                self.videoOutput.setSampleBufferDelegate(self.delegate, queue: self.queue)
                if self.session.canAddOutput(self.videoOutput) {
                    self.session.addOutput(self.videoOutput)
                }
                if self.session.canAddOutput(self.photoOutput) {
                    self.session.addOutput(self.photoOutput)
                }

                self.session.commitConfiguration()
                self.session.startRunning()
                Task { @MainActor in self.status = .running }
                cont.resume()
            }
        }
    }
}

// MARK: - Delegate (non-observable, handles AVFoundation callbacks on camera queue)

private final class CameraSessionDelegate: NSObject,
    AVCaptureVideoDataOutputSampleBufferDelegate,
    AVCapturePhotoCaptureDelegate,
    @unchecked Sendable
{
    nonisolated(unsafe) var onFrame: ((CIImage, CGImagePropertyOrientation) -> Void)?
    nonisolated(unsafe) var onPhoto: ((Data?) -> Void)?

    nonisolated func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        onFrame?(ciImage, .right)
    }

    nonisolated func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        if let error {
            Logger.camera.error("Photo capture failed: \(error.localizedDescription)")
            onPhoto?(nil)
            return
        }
        guard let data = photo.fileDataRepresentation() else {
            Logger.camera.error("Photo fileDataRepresentation returned nil")
            onPhoto?(nil)
            return
        }
        onPhoto?(data)
    }
}
