import Foundation
import Combine

/// Local User Traits Engine
/// Learns user preferences, behavior patterns, and communication style
/// All data stored on-device only - NEVER synced to cloud
@MainActor
class UserTraitsEngine: ObservableObject {
    static let shared = UserTraitsEngine()
    
    @Published var userProfile: UserProfile
    @Published var isLearning: Bool = false
    
    private var observations: [UserObservation] = []
    private let maxObservations = 100
    
    private init() {
        // Load saved profile
        if let saved = UserDefaults.standard.data(forKey: "userProfile"),
           let profile = try? JSONDecoder().decode(UserProfile.self, from: saved) {
            self.userProfile = profile
        } else {
            self.userProfile = UserProfile()
        }
    }
    
    // MARK: - User Profile
    
    struct UserProfile: Codable {
        var communicationStyle: CommunicationStyle
        var emotionalBaseline: EmotionalBaseline
        var preferredTopics: [String: Float] // Topic -> Interest level
        var interactionPatterns: InteractionPatterns
        var learningProgress: Float // 0.0 to 1.0
        
        init() {
            self.communicationStyle = CommunicationStyle()
            self.emotionalBaseline = EmotionalBaseline()
            self.preferredTopics = [:]
            self.interactionPatterns = InteractionPatterns()
            self.learningProgress = 0.0
        }
    }
    
    struct CommunicationStyle: Codable {
        var verbosity: Float = 0.5        // Short (0) ↔ Verbose (1)
        var formality: Float = 0.5        // Casual (0) ↔ Formal (1)
        var emotiveness: Float = 0.5      // Neutral (0) ↔ Expressive (1)
        var questionRate: Float = 0.0     // % of inputs that are questions
    }
    
    struct EmotionalBaseline: Codable {
        var averageValence: Float = 0.0   // -1.0 to 1.0
        var averageArousal: Float = 0.5   // 0.0 to 1.0
        var variability: Float = 0.3      // Emotional range
        var responseToPositive: Float = 0.7
        var responseToNegative: Float = 0.5
    }
    
    struct InteractionPatterns: Codable {
        var preferredTimeOfDay: TimeOfDay = .any
        var averageSessionLength: TimeInterval = 300 // 5 minutes
        var typicalResponseTime: TimeInterval = 30
        var interactionFrequency: Float = 0.5 // Daily (1.0) ↔ Rare (0.0)
    }
    
    enum TimeOfDay: String, Codable {
        case morning, afternoon, evening, night, any
    }
    
    // MARK: - Learning from Observations
    
    struct UserObservation {
        let text: String
        let emotion: PADEmotion
        let timestamp: Date
        let intent: MetadataGraph.Intent
        let responseTime: TimeInterval
    }
    
    /// "Think hard" - Deep analysis of user behavior
    func think(about observation: UserObservation) {
        print("UserTraitsEngine: 🧠 Thinking deeply about user behavior...")
        
        observations.append(observation)
        if observations.count > maxObservations {
            observations.removeFirst()
        }
        
        isLearning = true
        
        // Deep pattern analysis
        Task {
            await analyzePatterns()
            isLearning = false
        }
    }
    
    private func analyzePatterns() async {
        // Simulate "thinking hard" with slight delay
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
        
        guard !observations.isEmpty else { return }
        
        print("UserTraitsEngine: Analyzing \(observations.count) observations...")
        
        // 1. Learn Communication Style
        updateCommunicationStyle()
        
        // 2. Learn Emotional Baseline
        updateEmotionalBaseline()
        
        // 3. Detect Preferred Topics
        updatePreferredTopics()
        
        // 4. Learn Interaction Patterns
        updateInteractionPatterns()
        
        // 5. Update learning progress
        userProfile.learningProgress = min(1.0, Float(observations.count) / Float(maxObservations))
        
        // Save profile
        saveProfile()
        
        print("UserTraitsEngine: ✅ Learning complete (progress: \(Int(userProfile.learningProgress * 100))%)")
    }
    
    private func updateCommunicationStyle() {
        let avgLength = observations.map { Float($0.text.count) }.reduce(0, +) / Float(observations.count)
        userProfile.communicationStyle.verbosity = min(1.0, avgLength / 200.0)
        
        let questionCount = observations.filter { $0.intent == .question }.count
        userProfile.communicationStyle.questionRate = Float(questionCount) / Float(observations.count)
        
        // Detect formality based on punctuation and capitalization
        let formalCount = observations.filter { obs in
            obs.text.contains(".") && obs.text.first?.isUppercase == true
        }.count
        userProfile.communicationStyle.formality = Float(formalCount) / Float(observations.count)
    }
    
    private func updateEmotionalBaseline() {
        let avgValence = observations.map { Float($0.emotion.valence) }.reduce(0, +) / Float(observations.count)
        let avgArousal = observations.map { Float($0.emotion.arousal) }.reduce(0, +) / Float(observations.count)
        
        userProfile.emotionalBaseline.averageValence = avgValence
        userProfile.emotionalBaseline.averageArousal = avgArousal
        
        // Calculate variability
        let variance = observations.map { pow(Float($0.emotion.valence) - avgValence, 2) }.reduce(0, +) / Float(observations.count)
        userProfile.emotionalBaseline.variability = sqrt(variance)
    }
    
    private func updatePreferredTopics() {
        // Extract topics from text (simple keyword extraction)
        for obs in observations {
            let words = obs.text.lowercased().components(separatedBy: .whitespacesAndNewlines)
            
            for word in words where word.count > 4 {
                let currentInterest = userProfile.preferredTopics[word] ?? 0.5
                userProfile.preferredTopics[word] = min(1.0, currentInterest + 0.05)
            }
        }
        
        // Keep only top 20 topics
        if userProfile.preferredTopics.count > 20 {
            let sorted = userProfile.preferredTopics.sorted { $0.value > $1.value }
            userProfile.preferredTopics = Dictionary(uniqueKeysWithValues: sorted.prefix(20).map { ($0.key, $0.value) })
        }
    }
    
    private func updateInteractionPatterns() {
        // Time of day analysis
        let hour = Calendar.current.component(.hour, from: Date())
        let timeOfDay: TimeOfDay
        switch hour {
        case 6..<12: timeOfDay = .morning
        case 12..<17: timeOfDay = .afternoon
        case 17..<21: timeOfDay = .evening
        default: timeOfDay = .night
        }
        userProfile.interactionPatterns.preferredTimeOfDay = timeOfDay
        
        // Response time
        if observations.count > 1 {
            let responseTimes = observations.dropFirst().map { $0.responseTime }
            let avgResponseTime = responseTimes.reduce(0, +) / Double(responseTimes.count)
            userProfile.interactionPatterns.typicalResponseTime = avgResponseTime
        }
    }
    
    // MARK: - Adaptive Behavior
    
    /// Mimic user's communication style
    func adaptResponse(_ baseResponse: String) -> String {
        var adapted = baseResponse
        
        // Match verbosity
        if userProfile.communicationStyle.verbosity < 0.3 {
            // User is brief, keep response short
            adapted = String(adapted.prefix(50))
        } else if userProfile.communicationStyle.verbosity > 0.7 {
            // User is verbose, can be more detailed
            // Keep full response
        }
        
        // Match formality
        if userProfile.communicationStyle.formality < 0.3 {
            // User is casual, use contractions
            adapted = adapted
                .replacingOccurrences(of: "I am", with: "I'm")
                .replacingOccurrences(of: "You are", with: "You're")
        }
        
        return adapted
    }
    
    /// Get suggested emotion based on user's baseline
    func suggestEmotionResponse(to userEmotion: PADEmotion) -> String {
        if userEmotion.valence < -0.5 {
            // User is negative, show empathy
            return userProfile.emotionalBaseline.responseToNegative > 0.7 ? "SAD" : "CALM"
        } else if userEmotion.valence > 0.5 {
            // User is positive, match energy
            return userProfile.emotionalBaseline.responseToPositive > 0.7 ? "HAPPY" : "CALM"
        } else {
            return "NEUTRAL"
        }
    }
    
    // MARK: - Persistence
    
    private func saveProfile() {
        if let data = try? JSONEncoder().encode(userProfile) {
            UserDefaults.standard.set(data, forKey: "userProfile")
        }
    }
    
    func resetLearning() {
        observations.removeAll()
        userProfile = UserProfile()
        saveProfile()
        print("UserTraitsEngine: Learning reset")
    }
}
