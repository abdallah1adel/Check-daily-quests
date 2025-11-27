import Foundation
import CoreHaptics
import UIKit

#if os(iOS)
class PCPOSHaptics {
    static let shared = PCPOSHaptics()
    private var engine: CHHapticEngine?
    
    private init() {
        prepareHaptics()
    }
    
    func prepareHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            engine = try CHHapticEngine()
            try engine?.start()
        } catch {
            print("Failed to start haptic engine: \(error.localizedDescription)")
        }
    }
    
    func playAngry() {
        // Aggressive double tap
        playPattern(events: [
            hapticEvent(intensity: 0.8, sharpness: 0.9, time: 0),
            hapticEvent(intensity: 0.9, sharpness: 1.0, time: 0.1),
            hapticEvent(intensity: 0.7, sharpness: 0.8, time: 0.2)
        ])
    }
    
    func playCurious() {
        // Gentle questioning pattern
        playPattern(events: [
            hapticEvent(intensity: 0.4, sharpness: 0.4, time: 0),
            hapticEvent(intensity: 0.5, sharpness: 0.6, time: 0.15)
        ])
    }
    
    func playEnergetic() {
        // Bouncy rhythm
        playPattern(events: [
            hapticEvent(intensity: 0.6, sharpness: 0.7, time: 0),
            hapticEvent(intensity: 0.5, sharpness: 0.6, time: 0.1),
            hapticEvent(intensity: 0.7, sharpness: 0.8, time: 0.2),
            hapticEvent(intensity: 0.4, sharpness: 0.5, time: 0.3)
        ])
    }
    
    func playCalm() {
        // Soft breathing wave
        playPattern(events: [
            continuousEvent(intensity: 0.3, sharpness: 0.1, time: 0, duration: 1.0)
        ])
    }
    
    // MARK: - Interaction Patterns
    
    func playZoomIn() {
        // Accelerating tap
        playPattern(events: [
            hapticEvent(intensity: 0.3, sharpness: 0.4, time: 0),
            hapticEvent(intensity: 0.5, sharpness: 0.6, time: 0.08),
            hapticEvent(intensity: 0.7, sharpness: 0.8, time: 0.14)
        ])
    }
    
    func playZoomOut() {
        // Decelerating tap
        playPattern(events: [
            hapticEvent(intensity: 0.7, sharpness: 0.8, time: 0),
            hapticEvent(intensity: 0.5, sharpness: 0.6, time: 0.08),
            hapticEvent(intensity: 0.3, sharpness: 0.4, time: 0.16)
        ])
    }
    
    func playBounce() {
        // Impact feel
        playPattern(events: [
            hapticEvent(intensity: 0.8, sharpness: 0.5, time: 0)
        ])
    }
    
    func playCollision() {
        // Heavy collision feel
        playPattern(events: [
            hapticEvent(intensity: 1.0, sharpness: 0.8, time: 0),
            continuousEvent(intensity: 0.5, sharpness: 0.3, time: 0.05, duration: 0.1)
        ])
    }
    
    func playListeningStart() {
        // Ascending attention
        playPattern(events: [
            hapticEvent(intensity: 0.4, sharpness: 0.5, time: 0),
            hapticEvent(intensity: 0.6, sharpness: 0.7, time: 0.05)
        ])
    }
    
    func playListeningStop() {
        // Completion chime
        playPattern(events: [
            hapticEvent(intensity: 0.6, sharpness: 0.7, time: 0),
            continuousEvent(intensity: 0.3, sharpness: 0.2, time: 0.05, duration: 0.15)
        ])
    }
    
    func playSpeakingStart() {
        // Soft pulse
        playPattern(events: [
            continuousEvent(intensity: 0.35, sharpness: 0.3, time: 0, duration: 0.2)
        ])
    }
    
    func playSuccess() {
        // Ascending success chime
        playPattern(events: [
            hapticEvent(intensity: 0.5, sharpness: 0.4, time: 0),
            hapticEvent(intensity: 0.7, sharpness: 0.6, time: 0.1),
            hapticEvent(intensity: 1.0, sharpness: 0.8, time: 0.2)
        ])
    }
    
    func playError() {
        // Double buzz error
        playPattern(events: [
            continuousEvent(intensity: 1.0, sharpness: 0.8, time: 0, duration: 0.1),
            continuousEvent(intensity: 1.0, sharpness: 0.8, time: 0.2, duration: 0.1)
        ])
    }
    
    func playSelection() {
        // Light tap for UI selection
        playPattern(events: [
            hapticEvent(intensity: 0.4, sharpness: 0.3, time: 0)
        ])
    }
    
    func playHeartbeat() {
        // Thud-thud
        playPattern(events: [
            hapticEvent(intensity: 0.6, sharpness: 0.3, time: 0),
            hapticEvent(intensity: 0.4, sharpness: 0.2, time: 0.15)
        ])
    }
    
    // MARK: - Legacy (with auto emotion detection)
    
    // MARK: - PAD Emotion Haptics
    
    func playMoodHaptic(pad: PADEmotion) {
        // Map PAD values to Haptic Parameters
        // Arousal -> Intensity (Energy)
        // Dominance -> Sharpness (Confidence/Power)
        // Pleasure -> Pattern Complexity (Rhythm)
        
        let intensity = max(0.3, min(1.0, 0.5 + pad.arousal * 0.5))
        let sharpness = max(0.1, min(1.0, 0.5 + pad.dominance * 0.5))
        
        var events: [CHHapticEvent] = []
        
        if pad.pleasure > 0.5 {
            // Happy/Positive: Upward, bouncy pattern
            events = [
                hapticEvent(intensity: intensity * 0.8, sharpness: sharpness * 0.8, time: 0),
                hapticEvent(intensity: intensity, sharpness: sharpness, time: 0.1)
            ]
        } else if pad.pleasure < -0.5 {
            // Sad/Negative: Downward, heavy pattern
            events = [
                continuousEvent(intensity: intensity, sharpness: sharpness * 0.5, time: 0, duration: 0.2)
            ]
        } else if pad.arousal > 0.6 {
            // High Energy (Excited/Angry): Rapid pulses
            events = [
                hapticEvent(intensity: intensity, sharpness: sharpness, time: 0),
                hapticEvent(intensity: intensity, sharpness: sharpness, time: 0.08),
                hapticEvent(intensity: intensity, sharpness: sharpness, time: 0.16)
            ]
        } else {
            // Neutral/Calm: Gentle pulse
            events = [
                hapticEvent(intensity: intensity * 0.6, sharpness: sharpness * 0.6, time: 0)
            ]
        }
        
        playPattern(events: events)
    }
    
    // MARK: - Legacy (with auto emotion detection)
    
    func playEmotionHaptic(valence: CGFloat, arousal: CGFloat) {
        // Map legacy valence/arousal to PAD
        let pad = PADEmotion(pleasure: Float(valence), arousal: Float(arousal), dominance: 0.0)
        playMoodHaptic(pad: pad)
    }
    
    // MARK: - Helper Methods
    
    private func hapticEvent(intensity: Float, sharpness: Float, time: TimeInterval) -> CHHapticEvent {
        let intensityParam = CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity)
        let sharpnessParam = CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
        return CHHapticEvent(eventType: .hapticTransient, parameters: [intensityParam, sharpnessParam], relativeTime: time)
    }
    
    private func continuousEvent(intensity: Float, sharpness: Float, time: TimeInterval, duration: TimeInterval) -> CHHapticEvent {
        let intensityParam = CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity)
        let sharpnessParam = CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
        return CHHapticEvent(eventType: .hapticContinuous, parameters: [intensityParam, sharpnessParam], relativeTime: time, duration: duration)
    }
    
    private func playPattern(events: [CHHapticEvent]) {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        guard !events.isEmpty else { return }
        
        try? engine?.start()
        
        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
        } catch {
            print("Failed to play haptic: \(error.localizedDescription)")
        }
    }
}
#else
class PCPOSHaptics {
    static let shared = PCPOSHaptics()
    private init() {}
    func prepareHaptics() {}
    func playAngry() {}
    func playCurious() {}
    func playEnergetic() {}
    func playCalm() {}
    func playZoomIn() {}
    func playZoomOut() {}
    func playBounce() {}
    func playCollision() {}
    func playListeningStart() {}
    func playListeningStop() {}
    func playSpeakingStart() {}
    func playSuccess() {}
    func playError() {}
    func playSelection() {}
    func playHeartbeat() {}
    func playMoodHaptic(pad: PADEmotion) {}
    func playEmotionHaptic(valence: CGFloat, arousal: CGFloat) {}
}
#endif
