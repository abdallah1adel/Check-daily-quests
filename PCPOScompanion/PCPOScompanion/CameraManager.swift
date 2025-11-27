import AVFoundation
import UIKit
import Combine

@MainActor
final class CameraManager: NSObject, ObservableObject {
    @Published var isRunning = false
    var sampleBufferHandler: ((CMSampleBuffer) -> Void)?

#if os(iOS)
    private let session = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let queue = DispatchQueue(label: "camera.queue")

    func start() {
        guard !session.isRunning else { return }
        // Run configuration on background queue to avoid blocking UI
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            self.session.beginConfiguration()
            self.session.sessionPreset = .medium

            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
                  let input = try? AVCaptureDeviceInput(device: device) else {
                print("Unable to get front camera")
                self.session.commitConfiguration()
                return
            }

            self.session.inputs.forEach { self.session.removeInput($0) }
            if self.session.canAddInput(input) { self.session.addInput(input) }

            self.videoOutput.setSampleBufferDelegate(self, queue: self.queue)
            self.videoOutput.alwaysDiscardsLateVideoFrames = true
            self.session.outputs.forEach { self.session.removeOutput($0) }
            if self.session.canAddOutput(self.videoOutput) { self.session.addOutput(self.videoOutput) }

            if let conn = self.videoOutput.connection(with: .video), conn.isVideoOrientationSupported {
                conn.videoOrientation = .portrait
            }

            self.session.commitConfiguration()
            self.session.startRunning()
            DispatchQueue.main.async { self.isRunning = true }
        }
    }

    func stop() {
        guard session.isRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.stopRunning()
            DispatchQueue.main.async { self?.isRunning = false }
        }
    }
#else
    // VisionOS Stub (No Camera Access needed for HUD)
    func start() {
        print("CameraManager: Camera not available/needed on visionOS")
        isRunning = true
    }
    
    func stop() {
        isRunning = false
    }
#endif
}

#if os(iOS)
extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        sampleBufferHandler?(sampleBuffer)
    }
}
#endif
