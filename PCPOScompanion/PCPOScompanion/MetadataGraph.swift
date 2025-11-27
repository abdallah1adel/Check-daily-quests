import Foundation

/// Privacy-Preserving Metadata Graph
/// Only this data is sent to OpenAI - never raw user text
struct MetadataGraph: Codable {
    // Emotional State
    let emotionVector: EmotionVector
    
    // Intent Classification
    let intent: Intent
    
    // Conversation Context
    let conversationState: ConversationState
    
    // Temporal Data
    let timestamp: Date
    let sessionDuration: TimeInterval
    
    struct EmotionVector: Codable {
        let valence: Float        // -1.0 to 1.0
        let arousal: Float        // 0.0 to 1.0
        let dominance: Float      // 0.0 to 1.0
        let confidence: Float     // 0.0 to 1.0
    }
    
    enum Intent: String, Codable {
        case greeting
        case question
        case command
        case expression
        case search
        case unknown
    }
    
    struct ConversationState: Codable {
        let turnCount: Int
        let avgResponseTime: TimeInterval
        let topicDrift: Float     // 0.0 to 1.0
        let engagementLevel: Float // 0.0 to 1.0
    }
    
    /// Generate metadata from raw input WITHOUT exposing the text
    static func extract(from text: String, emotion: PADEmotion, history: [ChatMessage]) -> MetadataGraph {
        // Extract intent without sending text
        let intent = classifyIntent(text)
        
        // Build emotion vector
        let emotionVector = EmotionVector(
            valence: Float(emotion.valence),
            arousal: Float(emotion.arousal),
            dominance: Float(emotion.dominance),
            confidence: 0.8
        )
        
        // Analyze conversation state
        let conversationState = ConversationState(
            turnCount: history.count,
            avgResponseTime: calculateAvgResponseTime(history),
            topicDrift: 0.0, // TODO: Implement topic tracking
            engagementLevel: 0.7
        )
        
        return MetadataGraph(
            emotionVector: emotionVector,
            intent: intent,
            conversationState: conversationState,
            timestamp: Date(),
            sessionDuration: Date().timeIntervalSince(history.first?.timestamp ?? Date())
        )
    }
    
    private static func classifyIntent(_ text: String) -> Intent {
        let lower = text.lowercased()
        
        if lower.contains("search") || lower.contains("find") || lower.contains("look up") {
            return .search
        } else if lower.hasSuffix("?") || lower.starts(with: "what") || lower.starts(with: "how") {
            return .question
        } else if lower.contains("hi") || lower.contains("hello") || lower.contains("hey") {
            return .greeting
        } else if lower.contains("please") || lower.starts(with: "can you") {
            return .command
        } else if lower.contains("happy") || lower.contains("sad") || lower.contains("angry") {
            return .expression
        } else {
            return .unknown
        }
    }
    
    private static func calculateAvgResponseTime(_ history: [ChatMessage]) -> TimeInterval {
        guard history.count > 1 else { return 0 }
        
        var totalTime: TimeInterval = 0
        for i in 1..<history.count {
            totalTime += history[i].timestamp.timeIntervalSince(history[i-1].timestamp)
        }
        
        return totalTime / Double(history.count - 1)
    }
}

/// OpenAI Tuning Response (what comes back from cloud)
struct TuningGuidance: Codable {
    let suggestedEmotion: String?
    let responseStrategy: ResponseStrategy
    let confidenceBoost: Float
    let suggestedTopics: [String]
    
    enum ResponseStrategy: String, Codable {
        case empathetic
        case informative
        case playful
        case serious
        case brief
        case detailed
    }
}
