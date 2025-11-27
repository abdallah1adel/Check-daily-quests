import Foundation
import CoreML
import Vision
import CoreImage
import Combine

@MainActor
class CoreMLEmotionEngine: ObservableObject {
    @Published var currentPulse: EmotionPulse = EmotionPulse()
    
    // Placeholder for the generated MLModel class
    // In a real app, this would be `private let model = try? CNNEmotions(configuration: ...)`
    private var model: VNCoreMLModel?
    
    init() {
        setupModel()
    }
    
    private func setupModel() {
        // INSTRUCTIONS:
        // 1. Train an Image Classifier in CreateML with classes: Happy, Sad, Angry, Neutral, Surprise.
        // 2. Drag the .mlmodel file into Xcode.
        // 3. Rename it to 'EmotionClassifier'.
        // 4. Uncomment the code below.
        
        /*
        do {
            let config = MLModelConfiguration()
            let model = try EmotionClassifier(configuration: config)
            self.model = try VNCoreMLModel(for: model.model)
        } catch {
            print("Failed to load CoreML model: \(error)")
        }
        */
    }
    
    func process(pixelBuffer: CVPixelBuffer) {
        guard let model = model else {
            // Fallback: If no model, just do nothing or random noise
            // For now, we rely on the VisionEmotionEngine if this fails
            return
        }
        
        let request = VNCoreMLRequest(model: model) { [weak self] request, error in
            guard let results = request.results as? [VNClassificationObservation],
                  let topResult = results.first else { return }
            
            DispatchQueue.main.async {
                self?.mapClassificationToPulse(identifier: topResult.identifier, confidence: topResult.confidence)
            }
        }
        
        request.imageCropAndScaleOption = .centerCrop
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .leftMirrored, options: [:])
        try? handler.perform([request])
    }
    
    private func mapClassificationToPulse(identifier: String, confidence: Float) {
        // Map string labels to our EmotionPulse (valence, arousal)
        var pulse = EmotionPulse()
        let intensity = CGFloat(confidence)
        
        switch identifier.lowercased() {
        case "happy":
            pulse.valence = 1.0 * intensity
            pulse.arousal = 0.5 * intensity
        case "sad":
            pulse.valence = -0.8 * intensity
            pulse.arousal = -0.5 * intensity
        case "angry":
            pulse.valence = -0.5 * intensity
            pulse.arousal = 1.0 * intensity
        case "surprise":
            pulse.valence = 0.2 * intensity
            pulse.arousal = 1.0 * intensity
        case "neutral":
            pulse.valence = 0.0
            pulse.arousal = 0.0
        default:
            break
        }
        
        self.currentPulse = pulse
    }
}
