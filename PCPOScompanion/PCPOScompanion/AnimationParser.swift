import Foundation
import SwiftUI

// MARK: - Animation Parser
// Extracts emotion and movement parameters from LLM responses

class AnimationParser {
    static let shared = AnimationParser()
    
    private init() {}
    
    // MARK: - Parse LLM Response
    
    func parse(_ response: String) -> (text: String, params: AnimationUpdate?) {
        // Extract emotion and movement tags from response
        // Format: [EMOTION: happy] [MOVEMENT: bounce] Actual response text
        
        var cleanText = response
        var emotion: String?
        var movement: AnimationUpdate.MovementType?
        
        // Extract EMOTION tag
        if let emotionRange = response.range(of: #"\[EMOTION:\s*(\w+)\]"#, options: .regularExpression) {
            let emotionTag = String(response[emotionRange])
            if let match = emotionTag.range(of: #":\s*(\w+)"#, options: .regularExpression) {
                emotion = String(emotionTag[match]).replacingOccurrences(of: ":", with: "").trimmingCharacters(in: .whitespaces).uppercased()
            }
            cleanText = cleanText.replacingOccurrences(of: emotionTag, with: "").trimmingCharacters(in: .whitespaces)
        }
        
        // Extract MOVEMENT tag
        if let movementRange = response.range(of: #"\[MOVEMENT:\s*(\w+)\]"#, options: .regularExpression) {
            let movementTag = String(response[movementRange])
            if let match = movementTag.range(of: #":\s*(\w+)"#, options: .regularExpression) {
                let movementStr = String(movementTag[match]).replacingOccurrences(of: ":", with: "").trimmingCharacters(in: .whitespaces).lowercased()
                movement = AnimationUpdate.MovementType(rawValue: movementStr) ?? .calm
            }
            cleanText = cleanText.replacingOccurrences(of: movementTag, with: "").trimmingCharacters(in: .whitespaces)
        }
        
        // If we found tags, create animation update
        if let emotion = emotion {
            let animationUpdate = createAnimationUpdate(emotion: emotion, movement: movement)
            return (cleanText, animationUpdate)
        }
        
        return (cleanText, nil)
    }
    
    // MARK: - Create Animation Update
    
    private func createAnimationUpdate(emotion: String, movement: AnimationUpdate.MovementType?) -> AnimationUpdate {
        // Map emotion string to arousal/valence values
        let (arousal, valence) = emotionToValues(emotion)
        
        return AnimationUpdate(
            emotion: emotion,
            arousal: arousal,
            valence: valence,
            movement: movement ?? inferMovement(from: emotion)
        )
    }
    
    // MARK: - Emotion Mapping
    
    private func emotionToValues(_ emotion: String) -> (arousal: Float, valence: Float) {
        switch emotion {
        case "HAPPY":
            return (0.6, 0.8)
        case "EXCITED":
            return (0.9, 0.9)
        case "CALM":
            return (0.3, 0.4)
        case "SAD":
            return (0.3, -0.6)
        case "ANGRY":
            return (0.8, -0.7)
        case "SURPRISED":
            return (0.8, 0.5)
        case "NEUTRAL":
            return (0.4, 0.0)
        default:
            return (0.4, 0.2)
        }
    }
    
    private func inferMovement(from emotion: String) -> AnimationUpdate.MovementType {
        switch emotion {
        case "HAPPY", "EXCITED":
            return .bounce
        case "CALM", "SAD":
            return .calm
        case "ANGRY":
            return .shake
        case "SURPRISED":
            return .energetic
        default:
            return .idle
        }
    }
    
    // MARK: - Apply to Personality Engine
    
    func applyAnimation(_ update: AnimationUpdate, to engine: PersonalityEngine) {
        print("AnimationParser: Applying \(update.emotion) with movement: \(update.movement)")
        
        // Delegate to PersonalityEngine's new PAD-based handler
        engine.applyLLMAnimation(update)
    }
}
