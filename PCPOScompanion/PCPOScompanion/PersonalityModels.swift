import Foundation
import SwiftUI
import ActivityKit
import Combine

// MARK: - 1. Personality Template
struct Personality: Codable {
    var cheerfulness: CGFloat    // bright, bouncy, vibrant
    var empathy: CGFloat         // caring reactions
    var curiosity: CGFloat       // tilting head, asking questions
    var calmness: CGFloat        // slow movement, soft colors
    var confidence: CGFloat      // bold facial expressions
    var warmth: CGFloat = 0.5    // emotional warmth
    
    static let heroic = Personality(cheerfulness: 0.8, empathy: 0.6, curiosity: 0.5, calmness: 0.4, confidence: 0.9, warmth: 0.7)
    static let calmNavigator = Personality(cheerfulness: 0.4, empathy: 0.9, curiosity: 0.6, calmness: 0.9, confidence: 0.5, warmth: 0.8)
    static let playful = Personality(cheerfulness: 1.0, empathy: 0.5, curiosity: 0.7, calmness: 0.3, confidence: 0.7, warmth: 0.6)
}

// MARK: - 2. Long-Term Emotional State
struct CompanionMood: Codable {
    var mood: CGFloat = 0.0       // -1 (sad) → +1 (happy)
    var energy: CGFloat = 1.0     // 0 (tired) → 1 (energetic)
    var trust: CGFloat = 0.0      // 0 (new) → 1 (deep bond)
}

// MARK: - 3. Short-Term Emotional Reactivity
enum Gesture: String, Codable {
    case none
    case nod
    case shake
    case winkLeft
    case winkRight
}

struct EmotionPulse {
    var valence: CGFloat = 0.0    // negative ↔ positive (-1 to 1)
    var arousal: CGFloat = 0.0    // calm ↔ energetic (0 to 1)
    var focus: CGFloat = 0.0      // distracted ↔ attentive (0 to 1)
    var detectedGesture: Gesture = .none // New gesture tracking
}

// MARK: - 5. Expression Engine Output
struct AnimationParams {
    var eyeOpen: CGFloat = 0.5
    var browRaise: CGFloat = 0.0
    var mouthSmile: CGFloat = 0.0
    var mouthOpen: CGFloat = 0.0
    var headTilt: CGFloat = 0.0
    var glow: CGFloat = 0.0
    var colorTint: Color = .green
    var morphFactor: CGFloat = 0.0 // 0 = Brackets, 1 = Circle
    
    // New Life Params
    var gazeX: CGFloat = 0.0 // -1 to 1
    var gazeY: CGFloat = 0.0 // -1 to 1
    var smirk: CGFloat = 0.0 // -1 to 1
    
    // Animation Control Params (used by PersonalityEngine mood mapping)
    var speed: CGFloat = 1.0 // Animation speed multiplier
    var primaryColor: Color = .green // Primary emotion color
    var expressionIntensity: Float = 0.5 // Overall expression intensity
}

// MARK: - Shared Emotion State
enum EmotionState: String, Codable {
    case happy = "HAPPY"
    case sad = "SAD"
    case angry = "ANGRY"
    case excited = "EXCITED"
    case calm = "CALM"
    case surprised = "SURPRISED"
    case neutral = "NEUTRAL"
    case heroic = "HEROIC"
    case curious = "CURIOUS"
    case love = "LOVE"
    
    // Convenience initializer
    init(from string: String) {
        self = EmotionState(rawValue: string.uppercased()) ?? .neutral
    }
    
    var color: String {
        switch self {
        case .happy, .excited: return "#00FFFF" // Cyan
        case .sad: return "#4A90D9"              // Blue
        case .angry: return "#FF6B6B"            // Red
        case .calm, .neutral: return "#50C878"   // Green
        case .surprised: return "#FFD700"        // Gold
        case .heroic: return "#9B59B6"           // Purple
        case .curious: return "#F39C12"          // Orange
        case .love: return "#FF69B4"             // Pink
        }
    }
}

// MARK: - AI State (Shared for Live Activity)
enum AIState: String, Codable {
    case idle = "Idle"
    case listening = "Listening"
    case thinking = "Thinking"
    case speaking = "Speaking"
}

// MARK: - Live Activity Attributes (Shared)

@available(iOS 16.1, *)
struct PCPOSActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var currentEmotion: String
        var intensity: Double
        var aiState: AIState // Defined in PersonalityModels.swift
        var isThinking: Bool
        var lastMessage: String
        var currentSymbol: String = "faceid" 
        
        // Large expansion mode
        var isLargeExpansion: Bool = false
        var searchResults: String = "" 
        
        // Symbol Secrets integration
        var hasSecret: Bool = false
        var isViewingSecret: Bool = false
        var secretPlaybackStep: Int = 0
        var secretSenderName: String = ""
        var secretSymbolName: String = ""
        var secretColorHex: String = ""
        var secretEffectType: String = ""
    }
    
    // Static attributes
    var companionName: String
    var companionColor: String // Hex color
}

// MARK: - Live Activity Manager (Shared)

@available(iOS 16.1, *)
class LiveActivityManager: ObservableObject {
    static let shared = LiveActivityManager()
    
    @Published var currentActivity: Activity<PCPOSActivityAttributes>?
    
    private init() {
         // Restore existing activity if any
         Task {
             for await activity in Activity<PCPOSActivityAttributes>.activityUpdates {
                 print("✅ Live Activity restored: \(activity.id)")
                 await MainActor.run {
                     self.currentActivity = activity
                 }
                 observeActivityState(activity)
             }
         }
    }
    
    // MARK: - Activity Lifecycle
    
    func startActivity(companionName: String, color: String) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("⚠️ Live Activities are not enabled")
            return
        }
        
        // Check if activity already exists
        if let existingActivity = currentActivity {
            print("ℹ️ Live Activity already exists: \(existingActivity.id)")
            return
        }
        
        let attributes = PCPOSActivityAttributes(
            companionName: companionName,
            companionColor: color
        )
        
        let initialState = PCPOSActivityAttributes.ContentState(
            currentEmotion: "happy",
            intensity: 0.5,
            aiState: .idle,
            isThinking: false,
            lastMessage: "", 
            currentSymbol: "faceid"
        )
        
        let content = ActivityContent(
            state: initialState,
            staleDate: Date().addingTimeInterval(3600),
            relevanceScore: 100
        )
        
        do {
            let activity = try Activity<PCPOSActivityAttributes>.request(
                attributes: attributes,
                content: content,
                pushType: nil
            )
            
            currentActivity = activity
            print("✅ Live Activity started: \(activity.id)")
            
            observeActivityState(activity)
        } catch {
            print("❌ Failed to start Live Activity: \(error.localizedDescription)")
        }
    }
    
    func updateActivity(emotion: String, intensity: Double, aiState: AIState, message: String, isLargeExpansion: Bool = false, searchResults: String = "", currentSymbol: String? = nil) {
        guard let activity = currentActivity else { return }
        
        // Use passed symbol or default to faceid (PCPOSFaceSystem dependency removed for shared compatibility)
        let resolvedSymbol = currentSymbol ?? "faceid"
        
        Task {
            let newState = PCPOSActivityAttributes.ContentState(
                currentEmotion: emotion,
                intensity: intensity,
                aiState: aiState,
                isThinking: aiState == .thinking,
                lastMessage: message,
                currentSymbol: resolvedSymbol,
                isLargeExpansion: isLargeExpansion,
                searchResults: searchResults
            )
            
            let content = ActivityContent(
                state: newState,
                staleDate: Date().addingTimeInterval(3600),
                relevanceScore: 100
            )
            
            await activity.update(content)
        }
    }
    
    func endActivity() {
        guard let activity = currentActivity else { return }
        
        let finalState = PCPOSActivityAttributes.ContentState(
            currentEmotion: "neutral",
            intensity: 0.0,
            aiState: .idle,
            isThinking: false,
            lastMessage: "PCPOS is resting",
            currentSymbol: "faceid"
        )
        
        let finalContent = ActivityContent(
            state: finalState,
            staleDate: nil
        )
        
        Task {
            await activity.end(finalContent, dismissalPolicy: .immediate)
            currentActivity = nil
        }
    }
    
    private func observeActivityState(_ activity: Activity<PCPOSActivityAttributes>) {
        Task {
            for await state in activity.activityStateUpdates {
                if state == .ended || state == .dismissed {
                    if currentActivity?.id == activity.id {
                        await MainActor.run {
                            self.currentActivity = nil
                        }
                    }
                }
            }
        }
    }
}
