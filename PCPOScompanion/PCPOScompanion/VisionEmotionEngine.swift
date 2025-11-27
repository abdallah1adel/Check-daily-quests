import Foundation
import Vision
import CoreMedia
import UIKit
import Combine

@MainActor
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
    
    // CoreML Emotion Model
    private var emotionModel: VNCoreMLModel?
    
    // Gesture Tracking State
    private var noseHistory: [CGPoint] = []
    private var lastGestureTime: Date = Date()
    private let historyLimit = 10 
    private let gestureCooldown: TimeInterval = 1.0

    init() {
        setupCoreML()
    }

    private func setupCoreML() {
        // Attempt to load 'EmotionNet' from bundle
        // User must add EmotionNet.mlmodel to the project
        if let modelURL = Bundle.main.url(forResource: "EmotionNet", withExtension: "mlmodelc") {
            do {
                let model = try VNCoreMLModel(for: MLModel(contentsOf: modelURL))
                self.emotionModel = model
                print("VisionEmotionEngine: CoreML Model Loaded")
            } catch {
                print("VisionEmotionEngine: Failed to load CoreML model - \(error)")
            }
        } else {
            print("VisionEmotionEngine: EmotionNet.mlmodelc not found in bundle.")
        }
    }

    func process(sampleBuffer: CMSampleBuffer) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        var requests: [VNRequest] = []
        
        // 1. Face Landmarks Request
        let landmarksRequest = VNDetectFaceLandmarksRequest { [weak self] req, err in
            guard let self = self else { return }
            guard let result = req.results?.first as? VNFaceObservation else { return }
            self.deriveEmotion(from: result)
        }
        requests.append(landmarksRequest)
        
        // 2. CoreML Emotion Request (if model exists)
        if let model = emotionModel {
            let emotionRequest = VNCoreMLRequest(model: model) { [weak self] req, err in
                guard let self = self else { return }
                guard let results = req.results as? [VNClassificationObservation],
                      let topResult = results.first else { return }
                
                // Map CoreML output to our system
                // Assuming classes like: "Happy", "Sad", "Neutral", etc.
                DispatchQueue.main.async {
                    self.handleCoreMLEmotion(topResult.identifier, confidence: topResult.confidence)
                }
            }
            // Use center crop or full image depending on model training
            emotionRequest.imageCropAndScaleOption = .centerCrop 
            requests.append(emotionRequest)
        }

        try? sequenceHandler.perform(requests, on: pixelBuffer, orientation: .leftMirrored)
    }
    
    private func handleCoreMLEmotion(_ emotion: String, confidence: Float) {
        // Map string emotion to PAD values
        // This runs in parallel with heuristic checks
        // We can blend them or let CoreML override
        print("CoreML Emotion: \(emotion) (\(confidence))")
        
        // Example mapping (customize based on actual model labels)
        /*
        switch emotion.lowercased() {
        case "happy": currentPulse.valence = 1.0
        case "sad": currentPulse.valence = -1.0
        case "angry": currentPulse.arousal = 1.0
        default: break
        }
        */
    }

    private func deriveEmotion(from face: VNFaceObservation) {
        guard let landmarks = face.landmarks else { return }

        // 1. Eye Openness & Wink Detection
        var eyeOpenVal: Double = 0.5
        var detectedGesture: Gesture = .none
        
        if let leftEye = landmarks.leftEye, let rightEye = landmarks.rightEye {
            let leftHeight = boundingBoxHeight(of: leftEye)
            let rightHeight = boundingBoxHeight(of: rightEye)
            let eyeRatio = Double((leftHeight + rightHeight) / 2.0)
            eyeOpenVal = clamp((eyeRatio - 0.02) / 0.06, 0, 1)
            
            // Wink Detection
            // If one eye is significantly more closed than the other
            let diff = abs(leftHeight - rightHeight)
            if diff > 0.02 && Date().timeIntervalSince(lastGestureTime) > gestureCooldown {
                if leftHeight < rightHeight {
                    detectedGesture = .winkLeft // User's left eye (mirrored)
                } else {
                    detectedGesture = .winkRight
                }
                lastGestureTime = Date()
            }
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
        if let mouthRegion = landmarks.outerLips {
            // Get the first and last points as left/right corners
            let points = mouthRegion.normalizedPoints
            if points.count >= 2 {
                let leftCornerY = points.first!.y
                let rightCornerY = points.last!.y
                // Center is average of all points
                let mouthCenterY = points.map { $0.y }.reduce(0, +) / CGFloat(points.count)
                let cornerLift = Double(((leftCornerY + rightCornerY) / 2) - mouthCenterY)
                smileVal = clamp(cornerLift * 10.0, 0, 1)
            }
        }

        // 4. Brow Raise
        var browRaiseVal: Double = 0.0
        if let leftBrow = landmarks.leftEyebrow, let leftEye = landmarks.leftEye {
            let dist = averageY(of: leftBrow) - averageY(of: leftEye)
            browRaiseVal = clamp(Double((dist - 0.05) / 0.05), 0, 1)
        }
        
        // 5. Head Gesture Detection (Nod/Shake)
        if let nose = landmarks.nose {
            let noseCenter = averagePoint(of: nose)
            trackNose(point: noseCenter)
            
            if detectedGesture == .none && Date().timeIntervalSince(lastGestureTime) > gestureCooldown {
                detectedGesture = detectHeadGesture()
                if detectedGesture != .none {
                    lastGestureTime = Date()
                }
            }
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
            
            self.currentPulse = EmotionPulse(
                valence: valence,
                arousal: arousal,
                focus: 1.0,
                detectedGesture: detectedGesture
            )
        }
    }
    
    // MARK: - Gesture Logic
    
    private func trackNose(point: CGPoint) {
        noseHistory.append(point)
        if noseHistory.count > historyLimit {
            noseHistory.removeFirst()
        }
    }
    
    private func detectHeadGesture() -> Gesture {
        guard noseHistory.count >= historyLimit else { return .none }
        
        // Calculate deltas
        let xs = noseHistory.map { $0.x }
        let ys = noseHistory.map { $0.y }
        
        let xRange = (xs.max() ?? 0) - (xs.min() ?? 0)
        let yRange = (ys.max() ?? 0) - (ys.min() ?? 0)
        
        // Thresholds (tuned for normalized coordinates)
        let movementThreshold: CGFloat = 0.03 // 3% of screen movement
        
        if yRange > movementThreshold && yRange > xRange * 2.0 {
            // Vertical movement dominant -> NOD
            // Check for oscillation (up-down-up)
            // Simplified: just range check for now
            return .nod
        } else if xRange > movementThreshold && xRange > yRange * 2.0 {
            // Horizontal movement dominant -> SHAKE
            return .shake
        }
        
        return .none
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
    private func averagePoint(of region: VNFaceLandmarkRegion2D) -> CGPoint {
        let points = region.normalizedPoints
        let sum = points.reduce(CGPoint.zero) { CGPoint(x: $0.x + $1.x, y: $0.y + $1.y) }
        return CGPoint(x: sum.x / CGFloat(points.count), y: sum.y / CGFloat(points.count))
    }
    private func clamp(_ v: Double, _ a: Double, _ b: Double) -> Double {
        return min(max(v, a), b)
    }
    private func lerp(_ a: Double, _ b: Double, _ t: Double) -> Double {
        return a + (b - a) * t
    }
}
