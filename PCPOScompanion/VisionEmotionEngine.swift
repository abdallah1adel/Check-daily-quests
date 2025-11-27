import Foundation
import Vision
import CoreMedia
import UIKit
import Combine

final class VisionEmotionEngine: ObservableObject {
    // We output an EmotionPulse that the PersonalityEngine can consume
    @Published var currentPulse = EmotionPulse()
    
    // Also raw params for direct driving if needed
    @Published var rawEyeOpen: Double = 0.5
    @Published var rawMouthOpen: Double = 0.0
    @Published var rawSmile: Double = 0.0
    @Published var rawBrowRaise: Double = 0.0
    
    private let sequenceHandler = VNSequenceRequestHandler()
    private let smoothing: Double = 0.15

    func process(sampleBuffer: CMSampleBuffer) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let request = VNDetectFaceLandmarksRequest { [weak self] req, err in
            guard let self = self else { return }
            guard let result = req.results?.first as? VNFaceObservation else {
                // No face? slowly drift to neutral?
                // For now, do nothing or reset
                return
            }
            self.deriveEmotion(from: result)
        }

        // orientation: front camera mirrored usually
        try? sequenceHandler.perform([request], on: pixelBuffer, orientation: .leftMirrored)
    }

    private func deriveEmotion(from face: VNFaceObservation) {
        guard let landmarks = face.landmarks else { return }

        // 1. Eye Openness
        var eyeOpenVal: Double = 0.5
        if let leftEye = landmarks.leftEye, let rightEye = landmarks.rightEye {
            let leftHeight = boundingBoxHeight(of: leftEye)
            let rightHeight = boundingBoxHeight(of: rightEye)
            let eyeRatio = Double((leftHeight + rightHeight) / 2.0)
            eyeOpenVal = clamp((eyeRatio - 0.02) / 0.06, 0, 1)
        }

        // 2. Mouth Open
        var mouthOpenVal: Double = 0.0
        if let inner = landmarks.innerLips, let outer = landmarks.outerLips {
            let innerH = boundingBoxHeight(of: inner)
            let outerH = boundingBoxHeight(of: outer)
            let mouthRatio = Double(innerH / max(outerH, 0.0001))
            mouthOpenVal = clamp((mouthRatio - 0.18) / 0.25, 0, 1)
        }

        // 3. Smile (Corner Lift)
        var smileVal: Double = 0.0
        if let left = landmarks.leftMouth, let right = landmarks.rightMouth {
            let leftY = averageY(of: left)
            let rightY = averageY(of: right)
            let mouthCenterY = averageY(of: landmarks.mouth ?? left)
            // In Vision, Y is up? No, usually normalized 0..1 bottom-left origin in some contexts,
            // but VNFaceObservation landmarks are normalized to the bounding box.
            // Actually, let's stick to the user's heuristic which seemed to work for them:
            // "smaller y means higher corner (in Vision coordinates)" -> Wait, Vision origin is usually bottom-left.
            // If origin is bottom-left, higher Y is UP.
            // If origin is top-left (like UIKit), higher Y is DOWN.
            // VNFaceObservation normalized points: (0,0) is bottom-left of the face bounding box.
            // So Higher Y = Higher on face.
            // So a smile (corners go UP) means corners Y > center Y.
            
            let cornerLift = Double(((leftY + rightY)/2) - mouthCenterY)
            // If corners are higher than center, it's positive.
            // Threshold might need tuning.
            smileVal = clamp(cornerLift * 10.0, 0, 1)
        }

        // 4. Brow Raise
        var browRaiseVal: Double = 0.0
        if let leftBrow = landmarks.leftEyebrow, let leftEye = landmarks.leftEye {
            let dist = averageY(of: leftBrow) - averageY(of: leftEye)
            browRaiseVal = clamp(Double((dist - 0.05) / 0.05), 0, 1)
        }

        // Smooth and Publish on Main Thread
        DispatchQueue.main.async {
            self.rawEyeOpen = self.lerp(self.rawEyeOpen, eyeOpenVal, self.smoothing)
            self.rawMouthOpen = self.lerp(self.rawMouthOpen, mouthOpenVal, self.smoothing)
            self.rawSmile = self.lerp(self.rawSmile, smileVal, self.smoothing)
            self.rawBrowRaise = self.lerp(self.rawBrowRaise, browRaiseVal, self.smoothing)
            
            // Map to EmotionPulse
            // Valence: Smile - Frown? For now just smile.
            let valence = self.rawSmile * 2.0 - 1.0 // -1 to 1 roughly
            // Arousal: Eye open + Brow raise?
            let arousal = (self.rawEyeOpen + self.rawBrowRaise) / 2.0
            // Focus: 1.0 if face detected (implicit)
            
            self.currentPulse = EmotionPulse(valence: valence, arousal: arousal, focus: 1.0)
        }
    }

    // Helpers
    private func boundingBoxHeight(of region: VNFaceLandmarkRegion2D) -> CGFloat {
        let ys = (0..<region.pointCount).map { region.normalizedPoints[$0].y }
        guard let minY = ys.min(), let maxY = ys.max() else { return 0 }
        return maxY - minY
    }
    private func averageY(of region: VNFaceLandmarkRegion2D) -> CGFloat {
        let ys = (0..<region.pointCount).map { region.normalizedPoints[$0].y }
        return ys.reduce(0,+) / CGFloat(region.pointCount)
    }
    private func clamp(_ v: Double, _ a: Double, _ b: Double) -> Double {
        return min(max(v, a), b)
    }
    private func lerp(_ a: Double, _ b: Double, _ t: Double) -> Double {
        return a + (b - a) * t
    }
}
