import AVFoundation
import UIKit
import SwiftUI
import Combine

@MainActor
final class CameraManager: NSObject, ObservableObject {
    @Published var isRunning = false
    var sampleBufferHandler: ((CMSampleBuffer) -> Void)?

#if os(iOS)
    private let captureSession = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let queue = DispatchQueue(label: "camera.queue")
    
    /// Public access to session for CameraPreview
    var session: AVCaptureSession { captureSession }
    
    /// Check and request camera permissions
    func checkPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            break
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { _ in }
        default:
            break
        }
    }

    func start() {
        guard !captureSession.isRunning else { return }
        // Run configuration on background queue to avoid blocking UI
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            self.captureSession.beginConfiguration()
            self.captureSession.sessionPreset = .medium

            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
                  let input = try? AVCaptureDeviceInput(device: device) else {
                print("Unable to get front camera")
                self.captureSession.commitConfiguration()
                return
            }

            self.captureSession.inputs.forEach { self.captureSession.removeInput($0) }
            if self.captureSession.canAddInput(input) { self.captureSession.addInput(input) }

            self.videoOutput.setSampleBufferDelegate(self, queue: self.queue)
            self.videoOutput.alwaysDiscardsLateVideoFrames = true
            self.captureSession.outputs.forEach { self.captureSession.removeOutput($0) }
            if self.captureSession.canAddOutput(self.videoOutput) { self.captureSession.addOutput(self.videoOutput) }

            if let conn = self.videoOutput.connection(with: .video), conn.isVideoOrientationSupported {
                conn.videoOrientation = .portrait
            }

            self.captureSession.commitConfiguration()
            self.captureSession.startRunning()
            DispatchQueue.main.async { self.isRunning = true }
        }
    }

    func stop() {
        guard captureSession.isRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession.stopRunning()
            DispatchQueue.main.async { self?.isRunning = false }
        }
    }
#else
    // VisionOS Stub (No Camera Access needed for HUD)
    var session: Any? { nil }
    
    func checkPermissions() {}
    
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

// MARK: - Camera Preview View (UIViewRepresentable)

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        view.layer.addSublayer(previewLayer)
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if let layer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
            layer.frame = uiView.bounds
        }
    }
}
#endif
