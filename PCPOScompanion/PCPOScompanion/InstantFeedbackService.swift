import Foundation
import Combine
import SwiftUI

// MARK: - Instant Feedback Animations

enum InstantGesture {
    case thinking      // Head tilt, slight eye squint
    case listening     // Focused gaze, small nod
    case processing    // Subtle glow pulse
    case acknowledging // Quick nod
    case confused      // Head tilt opposite direction
    case excited       // Bounce anticipation
}

struct InstantAnimationUpdate {
    let gesture: InstantGesture
    let duration: TimeInterval
    let soundEffect: String?
}

// MARK: - Instant Feedback Service

@MainActor
class InstantFeedbackService: ObservableObject {
    static let shared = InstantFeedbackService()
    
    private init() {}
    
    // MARK: - Immediate Response Generation
    
    /// Provides instant visual/audio feedback while LLM processes (0-50ms latency)
    func getInstantFeedback(for query: String, emotion: PADEmotion) -> InstantAnimationUpdate {
        let queryType = classifyQuickly(query)
        
        switch queryType {
        case .greeting:
            return InstantAnimationUpdate(
                gesture: .acknowledging,
                duration: 0.3,
                soundEffect: "soft_beep"
            )
            
        case .question:
            return InstantAnimationUpdate(
                gesture: .thinking,
                duration: 0.5,
                soundEffect: "thinking_hum"
            )
            
        case .command:
            return InstantAnimationUpdate(
                gesture: .listening,
                duration: 0.4,
                soundEffect: "acknowledge_chime"
            )
            
        case .excited:
            return InstantAnimationUpdate(
                gesture: .excited,
                duration: 0.2,
                soundEffect: "excited_chirp"
            )
            
        default:
            return InstantAnimationUpdate(
                gesture: .listening,
                duration: 0.3,
                soundEffect: nil
            )
        }
    }
    
    // MARK: - Pre-canned Responses (< 10ms)
    
    /// Returns immediate acknowledgment text while LLM generates full response
    func getInstantAck(for query: String) -> String {
        let lowercased = query.lowercased()
        
        // Greetings
        if lowercased.contains("hello") || lowercased.contains("hi ") {
            return pickRandom(["Hi!", "Hey there!", "Hello!"])
        }
        
        // Questions - thinking acknowledgment
        if lowercased.hasSuffix("?") {
            return pickRandom(["Hmm...", "Let me think...", "Good question..."])
        }
        
        // Commands - immediate okay
        if lowercased.hasPrefix("play") || lowercased.hasPrefix("open") {
            return pickRandom(["On it!", "Sure!", "Got it!"])
        }
        
        // Time/date - instant acknowledgment
        if lowercased.contains("time") || lowercased.contains("date") {
            return pickRandom(["Just a sec...", "Let me check..."])
        }
        
        // Default acknowledgment
        return pickRandom(["...", "Mhm...", "Okay..."])
    }
    
    // MARK: - Quick Classification (< 5ms)
    
    private enum QuickQueryType {
        case greeting
        case question
        case command
        case excited
        case other
    }
    
    private func classifyQuickly(_ query: String) -> QuickQueryType {
        let lowercased = query.lowercased()
        
        if lowercased.contains("hello") || lowercased.contains("hi ") {
            return .greeting
        }
        
        if lowercased.hasSuffix("?") || lowercased.hasPrefix("what") ||
           lowercased.hasPrefix("how") || lowercased.hasPrefix("why") {
            return .question
        }
        
        if lowercased.hasPrefix("play") || lowercased.hasPrefix("open") ||
           lowercased.hasPrefix("show") {
            return .command
        }
        
        if lowercased.hasSuffix("!") && lowercased.count < 15 {
            return .excited
        }
        
        return .other
    }
    
    private func pickRandom(_ options: [String]) -> String {
        return options.randomElement() ?? options.first ?? "..."
    }
}

// MARK: - Animation Extension

extension PersonalityEngine {
    /// Apply instant gesture animation (non-blocking)
    func applyInstantGesture(_ gesture: InstantGesture) {
        switch gesture {
        case .thinking:
            // Tilt head slightly, squint eyes
            animationParams.headTilt = 0.2
            animationParams.eyeOpen = 0.7
            
        case .listening:
            // Focused gaze at user, small nod
            animationParams.gazeX = 0
            animationParams.gazeY = 0
            animationParams.headTilt = 0.1
            
        case .processing:
            // Subtle glow pulse
            animationParams.glow = animationParams.glow + 0.2
            
        case .acknowledging:
            // Quick nod
            animationParams.headTilt = 0.3
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                self.animationParams.headTilt = 0.0
            }
            
        case .confused:
            // Tilt head opposite direction
            animationParams.headTilt = -0.2
            
        case .excited:
            // Bounce anticipation
            animationParams.glow = animationParams.glow + 0.3
            targetPAD.arousal = 0.8
        }
    }
}
