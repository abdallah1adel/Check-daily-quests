import Foundation

class PersistenceManager {
    static let shared = PersistenceManager()
    
    private let moodKey = "companion_mood"
    private let personalityKey = "companion_personality"
    private let companionNameKey = "companion_name"
    private let voiceIdentifierKey = "voice_identifier"
    private let speechRateKey = "speech_rate"
    
    func saveMood(_ mood: CompanionMood) {
        if let data = try? JSONEncoder().encode(mood) {
            UserDefaults.standard.set(data, forKey: moodKey)
        }
    }
    
    func loadMood() -> CompanionMood {
        if let data = UserDefaults.standard.data(forKey: moodKey),
           let mood = try? JSONDecoder().decode(CompanionMood.self, from: data) {
            return mood
        }
        return CompanionMood()
    }
    
    func savePersonality(_ personality: Personality) {
        if let data = try? JSONEncoder().encode(personality) {
            UserDefaults.standard.set(data, forKey: personalityKey)
        }
    }
    
    func loadPersonality() -> Personality {
        if let data = UserDefaults.standard.data(forKey: personalityKey),
           let personality = try? JSONDecoder().decode(Personality.self, from: data) {
            return personality
        }
        return .heroic
    }
    
    func saveCompanionName(_ name: String) {
        UserDefaults.standard.set(name, forKey: companionNameKey)
    }
    
    func loadCompanionName() -> String {
        if let name = UserDefaults.standard.string(forKey: companionNameKey), !name.isEmpty {
            return name
        }
        return "PCPOS" // Default name
    }
    
    func saveVoiceIdentifier(_ identifier: String) {
        UserDefaults.standard.set(identifier, forKey: voiceIdentifierKey)
    }
    
    func loadVoiceIdentifier() -> String? {
        return UserDefaults.standard.string(forKey: voiceIdentifierKey)
    }
    
    func saveSpeechRate(_ rate: Float) {
        UserDefaults.standard.set(rate, forKey: speechRateKey)
    }
    
    func loadSpeechRate() -> Float {
        let rate = UserDefaults.standard.float(forKey: speechRateKey)
        return rate > 0 ? rate : 0.5 // Default rate
    }
    private let ttsProviderKey = "tts_provider"
    private let ttsApiKeyKey = "tts_api_key"
    
    func saveTTSProvider(_ provider: TTSProvider) {
        if let data = try? JSONEncoder().encode(provider) {
            UserDefaults.standard.set(data, forKey: ttsProviderKey)
        }
    }
    
    func loadTTSProvider() -> TTSProvider {
        if let data = UserDefaults.standard.data(forKey: ttsProviderKey),
           let provider = try? JSONDecoder().decode(TTSProvider.self, from: data) {
            return provider
        }
        return .openAI // Default to OpenAI for human-like voice
    }
    
    func saveTTSApiKey(_ key: String) {
        // In a real app, use Keychain. For this prototype, UserDefaults is acceptable but not secure.
        UserDefaults.standard.set(key, forKey: ttsApiKeyKey)
    }
    
    func loadTTSApiKey() -> String {
        return UserDefaults.standard.string(forKey: ttsApiKeyKey) ?? ""
    }
}
