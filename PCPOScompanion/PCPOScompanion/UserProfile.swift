import Foundation
import SwiftUI

// MARK: - User Profile Model
/// Universal user profile for multi-user system (Phase 2)

struct UserProfile: Codable, Identifiable {
    var id: String // Firebase UID
    var email: String
    var displayName: String
    var photoURL: String?
    
    // Biometric Data (Encrypted in cloud)
    var faceEmbedding: [Float]? // 512-dim from Vision
    var voiceEmbedding: [Float]? // 512-dim from SpeakerEncoder
    
    // Social Integration
    var socialAccounts: SocialAccounts
    
    // Personality & Preferences
    var personalityPreset: MoodState
    var ttsEnabled: Bool
    var sttEnabled: Bool
    var ttsVoice: String
    var sttLanguage: String
    
    // Metadata
    var createdAt: Date
    var lastLoginAt: Date
    
    init(id: String = UUID().uuidString, email: String, displayName: String) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.socialAccounts = SocialAccounts()
        self.personalityPreset = MoodState() // Default mood
        self.ttsEnabled = true
        self.sttEnabled = true
        self.ttsVoice = "com.apple.voice.compact.en-US.Samantha"
        self.sttLanguage = "en-US"
        self.createdAt = Date()
        self.lastLoginAt = Date()
    }
}

// MARK: - Social Accounts

struct SocialAccounts: Codable {
    var facebookID: String?
    var instagramHandle: String?
    var profilePicURL: String?
}

// MARK: - 374 Mood System (22 × 17)

enum PrimaryEmotion: String, CaseIterable, Codable {
    // Positive Emotions (11)
    case joy = "joy"
    case excitement = "excitement"
    case contentment = "contentment"
    case love = "love"
    case pride = "pride"
    case curiosity = "curiosity"
    case surprise = "surprise"
    case interest = "interest"
    case anticipation = "anticipation"
    case hope = "hope"
    case gratitude = "gratitude"
    
    // Negative Emotions (11)
    case sadness = "sadness"
    case disappointment = "disappointment"
    case grief = "grief"
    case loneliness = "loneliness"
    case guilt = "guilt"
    case anger = "anger"
    case frustration = "frustration"
    case irritation = "irritation"
    case disgust = "disgust"
    case contempt = "contempt"
    case fear = "fear"
    case anxiety = "anxiety"
}

enum EnergyLevel: Int, CaseIterable, Codable {
    case dormant = 0        // 0%
    case resting = 1        // 6%
    case calm = 2           // 12%
    case relaxed = 3        // 18%
    case content = 4        // 25%
    case engaged = 5        // 31%
    case active = 6         // 37%
    case alert = 7          // 43%
    case focused = 8        // 50%
    case energized = 9      // 56%
    case excited = 10       // 62%
    case enthusiastic = 11  // 68%
    case passionate = 12    // 75%
    case intense = 13       // 81%
    case frenzied = 14      // 87%
    case ecstatic = 15      // 93%
    case transcendent = 16  // 100%
    
    var percentage: Int { rawValue * 6 }
}

struct MoodState: Codable {
    var primary: PrimaryEmotion
    var energy: EnergyLevel
    var blend: [String: Float] // Emoji keys for smooth transitions
    
    init(primary: PrimaryEmotion = .contentment, energy: EnergyLevel = .calm) {
        self.primary = primary
        self.energy = energy
        self.blend = [primary.rawValue: 1.0]
    }
    
    var displayName: String {
        "\(primary.rawValue.capitalized) (\(energy.percentage)%)"
    }
    
    var emoji: String {
        switch primary {
        case .joy: return "😊"
        case .excitement: return "🤩"
        case .contentment: return "😌"
        case .love: return "🥰"
        case .pride: return "😎"
        case .curiosity: return "🤔"
        case .surprise: return "😲"
        case .interest: return "🧐"
        case .anticipation: return "😃"
        case .hope: return "🙏"
        case .gratitude: return "🙌"
        case .sadness: return "😢"
        case .disappointment: return "😞"
        case .grief: return "😭"
        case .loneliness: return "😔"
        case .guilt: return "😰"
        case .anger: return "😠"
        case .frustration: return "😤"
        case .irritation: return "😒"
        case .disgust: return "🤢"
        case .contempt: return "😑"
        case .fear: return "😨"
        case .anxiety: return "😟"
        }
    }
    
    // Smooth transition between moods
    static func transition(from: MoodState, to: MoodState, progress: Float) -> MoodState {
        let blendedEnergy = Int(Float(from.energy.rawValue) * (1 - progress) + 
                                 Float(to.energy.rawValue) * progress)
        
        var newState = MoodState(
            primary: progress < 0.5 ? from.primary : to.primary,
            energy: EnergyLevel(rawValue: blendedEnergy) ?? .calm
        )
        
        // Blend emotions
        newState.blend = [
            from.primary.rawValue: 1 - progress,
            to.primary.rawValue: progress
        ]
        
        return newState
    }
}
