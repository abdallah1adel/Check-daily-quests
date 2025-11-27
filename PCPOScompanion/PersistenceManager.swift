import Foundation

class PersistenceManager {
    static let shared = PersistenceManager()
    
    private let moodKey = "companion_mood"
    private let personalityKey = "companion_personality"
    
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
}
