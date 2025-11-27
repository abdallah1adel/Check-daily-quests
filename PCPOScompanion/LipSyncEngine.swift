import Foundation
import AVFoundation

class LipSyncEngine: ObservableObject {
    @Published var currentViseme: AnimationParams = AnimationParams()
    
    private var audioEngine: AVAudioEngine?
    private var analyzer: AVAudioPlayerNode? // Just a placeholder, we tap the input node
    
    func startMonitoring() {
        // In a real app, we would tap the output node of the TTS engine or the input node of the mic.
        // For this prototype, we will hook into the SpeechManager's audio session if possible,
        // or just simulate advanced visemes based on volume.
    }
    
    // Called by SpeechManager when audio buffer is available
    func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let frameLength = Int(buffer.frameLength)
        
        // 1. Calculate RMS (Root Mean Square) for Volume -> Mouth Open
        var sum: Float = 0
        for i in 0..<frameLength {
            sum += channelData[i] * channelData[i]
        }
        let rms = sqrt(sum / Float(frameLength))
        let volume = CGFloat(min(max(rms * 5.0, 0), 1.0)) // Boost and clamp
        
        // 2. Simple Frequency Analysis (Zero Crossing Rate) for Shape
        // High ZCR ~ Fricatives (S, F, T) -> Wide mouth
        // Low ZCR ~ Vowels (O, U) -> Round mouth
        var zeroCrossings = 0
        for i in 1..<frameLength {
            if (channelData[i-1] > 0 && channelData[i] <= 0) || (channelData[i-1] <= 0 && channelData[i] > 0) {
                zeroCrossings += 1
            }
        }
        let zcr = Float(zeroCrossings) / Float(frameLength)
        
        DispatchQueue.main.async {
            self.updateMouth(volume: volume, zcr: zcr)
        }
    }
    
    private func updateMouth(volume: CGFloat, zcr: Float) {
        // Heuristic Mapping
        var params = AnimationParams()
        
        // Base Openness
        params.mouthOpen = volume
        
        // Shape based on frequency
        if volume > 0.1 {
            if zcr > 0.1 {
                // High freq: S, T, F -> Wide smile-like shape
                params.mouthSmile = 0.5
            } else {
                // Low freq: O, U -> Round shape (negative smile = rounder in our simple model)
                params.mouthSmile = -0.2
            }
        }
        
        self.currentViseme = params
    }
}
