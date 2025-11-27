import Foundation
import SwiftUI

// MARK: - PAD Emotion Model
// Pleasure-Arousal-Dominance Model for nuanced emotional state tracking

struct PADEmotion: Codable, Equatable {
    var pleasure: Float   // -1.0 (Misery) to 1.0 (Ecstasy)
    var arousal: Float    // -1.0 (Sleep) to 1.0 (Frenzy)
    var dominance: Float  // -1.0 (Fear) to 1.0 (Rage/Power)
    
    // Alias for compatibility with other systems
    var valence: Float { pleasure }
    
    static let neutral = PADEmotion(pleasure: 0, arousal: 0, dominance: 0)
    
    // Common Emotional States mapped to PAD
    static let happy = PADEmotion(pleasure: 0.8, arousal: 0.6, dominance: 0.5)
    static let sad = PADEmotion(pleasure: -0.6, arousal: -0.4, dominance: -0.3)
    static let angry = PADEmotion(pleasure: -0.5, arousal: 0.8, dominance: 0.8)
    static let fearful = PADEmotion(pleasure: -0.7, arousal: 0.7, dominance: -0.6)
    static let surprised = PADEmotion(pleasure: 0.6, arousal: 0.8, dominance: -0.2)
    static let bored = PADEmotion(pleasure: -0.3, arousal: -0.6, dominance: -0.1)
    static let excited = PADEmotion(pleasure: 0.9, arousal: 0.9, dominance: 0.4)
    static let relaxed = PADEmotion(pleasure: 0.7, arousal: -0.5, dominance: 0.3)
}

// MARK: - Emotion Mapper
// Maps PAD values to AnimationParams for the avatar

class EmotionMapper {
    static func map(_ pad: PADEmotion) -> AnimationParams {
        var params = AnimationParams()
        
        // 1. PLEASURE (Valence)
        // Controls: Smile/Frown, Eye Shape, Color Warmth
        
        if pad.pleasure > 0 {
            // Positive: Smile, Open Eyes
            params.mouthSmile = CGFloat(pad.pleasure)
            params.eyeOpen = 1.0 + CGFloat(pad.pleasure * 0.2) // Slightly wider eyes
            params.colorTint = Color(hue: 0.5 + Double(pad.pleasure) * 0.1, saturation: 0.8, brightness: 1.0) // Shift towards cyan/blue/purple
        } else {
            // Negative: Frown, Squint/Sad Eyes
            params.mouthSmile = CGFloat(pad.pleasure) // Negative value = frown
            params.eyeOpen = 1.0 - CGFloat(abs(pad.pleasure) * 0.3) // Droopy eyes
            params.colorTint = Color(hue: 0.0 + Double(abs(pad.pleasure)) * 0.1, saturation: 0.8, brightness: 1.0) // Shift towards red/orange
        }
        
        // 2. AROUSAL (Energy)
        // Controls: Movement Speed (handled by engine), Pupil Size, Glow, Breathing
        
        params.glow = 0.5 + CGFloat(pad.arousal * 0.5) // Higher arousal = brighter glow
        params.browRaise = CGFloat(pad.arousal * 0.5) // Alertness
        
        // 3. DOMINANCE (Power/Control)
        // Controls: Head Tilt (Confidence), Gaze Directness (handled by engine)
        
        if pad.dominance > 0 {
            // High Dominance: Confident, Head held high (or slight tilt)
            params.headTilt = CGFloat(pad.dominance * 0.1)
        } else {
            // Low Dominance: Submissive, Head down/shy
            params.headTilt = CGFloat(pad.dominance * 0.2)
        }
        
        return params
    }
    
    // Interpolate between two PAD states
    static func interpolate(from start: PADEmotion, to end: PADEmotion, progress: Float) -> PADEmotion {
        return PADEmotion(
            pleasure: start.pleasure + (end.pleasure - start.pleasure) * progress,
            arousal: start.arousal + (end.arousal - start.arousal) * progress,
            dominance: start.dominance + (end.dominance - start.dominance) * progress
        )
    }
}
