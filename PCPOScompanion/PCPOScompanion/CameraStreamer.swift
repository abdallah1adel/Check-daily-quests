import Foundation
import Combine
import AVFoundation
import UIKit

#if os(iOS)
class CameraStreamer: ObservableObject {
    static let shared = CameraStreamer()
    
    private let deviceLink = DeviceLinkService.shared
    private var isStreaming = false
    private var lastFrameTime: TimeInterval = 0
    private let targetFPS: Double = 15.0 // Cap FPS to reduce latency/bandwidth
    
    private init() {}
    
    func startStreaming(from cameraManager: CameraManager) {
        guard !isStreaming else { return }
        isStreaming = true
        deviceLink.start() // Start advertising
        
        cameraManager.sampleBufferHandler = { [weak self] buffer in
            self?.processFrame(buffer)
        }
    }
    
    func stopStreaming() {
        isStreaming = false
        deviceLink.stop()
    }
    
    private func processFrame(_ buffer: CMSampleBuffer) {
        let currentTime = CACurrentMediaTime()
        guard currentTime - lastFrameTime >= (1.0 / targetFPS) else { return }
        lastFrameTime = currentTime
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(buffer) else { return }
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()
        
        // Resize/Compress for transmission
        // 500px width is enough for HUD preview
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent),
              let jpegData = UIImage(cgImage: cgImage).jpegData(compressionQuality: 0.4) else { return }
        
        // Send via Multipeer
        deviceLink.send(data: jpegData)
    }
}
#endif
