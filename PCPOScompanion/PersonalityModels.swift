import Foundation
import SwiftUI

// MARK: - 1. Personality Template
struct Personality: Codable {
    var cheerfulness: CGFloat    // bright, bouncy, vibrant
    var empathy: CGFloat         // caring reactions
    var curiosity: CGFloat       // tilting head, asking questions
    var calmness: CGFloat        // slow movement, soft colors
    var confidence: CGFloat      // bold facial expressions
    
    static let heroic = Personality(cheerfulness: 0.8, empathy: 0.6, curiosity: 0.5, calmness: 0.4, confidence: 0.9)
    static let calmNavigator = Personality(cheerfulness: 0.4, empathy: 0.9, curiosity: 0.6, calmness: 0.9, confidence: 0.5)
    static let playful = Personality(cheerfulness: 1.0, empathy: 0.5, curiosity: 0.7, calmness: 0.3, confidence: 0.7)
}

// MARK: - 2. Long-Term Emotional State
struct CompanionMood: Codable {
    var mood: CGFloat = 0.0       // -1 (sad) → +1 (happy)
    var energy: CGFloat = 1.0     // 0 (tired) → 1 (energetic)
    var trust: CGFloat = 0.0      // 0 (new) → 1 (deep bond)
}

// MARK: - 3. Short-Term Emotional Reactivity
struct EmotionPulse {
    var valence: CGFloat = 0.0    // negative ↔ positive (-1 to 1)
    var arousal: CGFloat = 0.0    // calm ↔ energetic (0 to 1)
    var focus: CGFloat = 0.0      // distracted ↔ attentive (0 to 1)
}

// MARK: - 5. Expression Engine Output
struct AnimationParams {
    var eyeOpen: CGFloat = 0.5
    var browRaise: CGFloat = 0.0
    var mouthSmile: CGFloat = 0.0
    var mouthOpen: CGFloat = 0.0
    var headTilt: CGFloat = 0.0
    var glow: CGFloat = 0.0
    var colorTint: Color = .blue
}
