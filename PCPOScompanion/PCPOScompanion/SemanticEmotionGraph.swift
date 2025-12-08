import Foundation
import SwiftUI
import Combine

// MARK: - Semantic Emotion Graph (Hash Tree for Word → Emotion Mapping)
// Maps spoken words to emotional states and animation IDs

@MainActor
class SemanticEmotionGraph: ObservableObject {
    static let shared = SemanticEmotionGraph()
    
    // Published state for UI binding
    @Published var currentEmotion: EmotionNode = .neutral
    @Published var currentAnimationID: Int = 0
    @Published var emotionHistory: [EmotionNode] = []
    
    // Hash tree for O(1) word lookup
    private var wordEmotionMap: [String: EmotionNode] = [:]
    private var emotionToAnimation: [EmotionNode: [Int]] = [:]
    
    init() {
        buildSemanticTree()
        buildAnimationMappings()
    }
    
    // MARK: - Core Processing
    
    func processSemantic(_ text: String) -> Int {
        let words = text.lowercased()
            .components(separatedBy: .punctuationCharacters)
            .joined()
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
        
        var emotionScores: [EmotionNode: Float] = [:]
        
        for word in words {
            if let emotion = wordEmotionMap[word] {
                emotionScores[emotion, default: 0] += 1.0
            }
            
            // Check for partial matches (prefix matching for compound words)
            for (key, emotion) in wordEmotionMap where word.hasPrefix(key) {
                emotionScores[emotion, default: 0] += 0.5
            }
        }
        
        // Find dominant emotion
        let dominantEmotion = emotionScores.max(by: { $0.value < $1.value })?.key ?? .neutral
        
        // Update state
        currentEmotion = dominantEmotion
        emotionHistory.append(dominantEmotion)
        if emotionHistory.count > 20 { emotionHistory.removeFirst() }
        
        // Get animation ID
        let animations = emotionToAnimation[dominantEmotion] ?? [0]
        currentAnimationID = animations.randomElement() ?? 0
        
        print("🌳 Semantic: '\(text.prefix(30))...' → \(dominantEmotion) → Animation \(currentAnimationID)")
        
        return currentAnimationID
    }
    
    // MARK: - Build Semantic Tree
    
    private func buildSemanticTree() {
        // JOY / HAPPINESS
        let joyWords = ["happy", "joy", "wonderful", "amazing", "great", "awesome", "fantastic",
                        "love", "lovely", "beautiful", "excellent", "perfect", "brilliant",
                        "delighted", "thrilled", "ecstatic", "cheerful", "merry", "glad",
                        "pleased", "satisfied", "content", "blissful", "euphoric", "elated",
                        "yay", "woohoo", "yes", "cool", "nice", "good", "best"]
        joyWords.forEach { wordEmotionMap[$0] = .joy }
        
        // SADNESS
        let sadWords = ["sad", "unhappy", "depressed", "down", "blue", "melancholy", "gloomy",
                        "miserable", "sorrowful", "dejected", "heartbroken", "grief", "mourn",
                        "cry", "crying", "tears", "weep", "lonely", "alone", "abandoned",
                        "hopeless", "despair", "regret", "sorry", "disappointed", "hurt"]
        sadWords.forEach { wordEmotionMap[$0] = .sadness }
        
        // ANGER
        let angerWords = ["angry", "mad", "furious", "rage", "hate", "irritated", "annoyed",
                          "frustrated", "outraged", "livid", "fuming", "hostile", "aggressive",
                          "bitter", "resentful", "damn", "hell", "stupid", "idiot", "awful",
                          "terrible", "horrible", "worst", "disgusting", "pathetic"]
        angerWords.forEach { wordEmotionMap[$0] = .anger }
        
        // FEAR / ANXIETY
        let fearWords = ["scared", "afraid", "fear", "terrified", "anxious", "worried", "nervous",
                         "panic", "dread", "horror", "frightened", "alarmed", "uneasy",
                         "apprehensive", "tense", "stressed", "concern", "threatening", "danger",
                         "scary", "creepy", "spooky", "nightmare", "phobia"]
        fearWords.forEach { wordEmotionMap[$0] = .fear }
        
        // SURPRISE
        let surpriseWords = ["surprised", "shocked", "amazed", "astonished", "wow", "whoa",
                             "unexpected", "sudden", "unbelievable", "incredible", "stunning",
                             "startled", "speechless", "omg", "what", "really", "seriously",
                             "no way", "impossible", "crazy", "wild", "insane"]
        surpriseWords.forEach { wordEmotionMap[$0] = .surprise }
        
        // CURIOSITY / INTEREST
        let curiosityWords = ["curious", "interesting", "wonder", "what", "how", "why", "who",
                              "when", "where", "tell", "explain", "show", "discover", "learn",
                              "understand", "question", "investigate", "explore", "seek",
                              "research", "study", "analyze", "think", "hmm", "perhaps"]
        curiosityWords.forEach { wordEmotionMap[$0] = .curiosity }
        
        // EXCITEMENT / ENERGY
        let excitementWords = ["excited", "thrilled", "energetic", "pumped", "hyped", "ready",
                               "can't wait", "eager", "enthusiastic", "passionate", "fired",
                               "motivated", "inspired", "determined", "go", "let's", "start",
                               "begin", "launch", "power", "boost", "charge", "activate"]
        excitementWords.forEach { wordEmotionMap[$0] = .excitement }
        
        // CALM / PEACE
        let calmWords = ["calm", "peaceful", "relaxed", "serene", "tranquil", "quiet", "still",
                         "gentle", "soft", "easy", "slow", "breathe", "meditation", "zen",
                         "harmony", "balance", "rest", "sleep", "comfort", "safe", "secure",
                         "okay", "fine", "alright", "chill", "cool down"]
        calmWords.forEach { wordEmotionMap[$0] = .calm }
        
        // LOVE / AFFECTION
        let loveWords = ["love", "adore", "cherish", "care", "heart", "dear", "sweetheart",
                         "darling", "honey", "beloved", "precious", "treasure", "hug", "kiss",
                         "embrace", "affection", "romance", "passion", "devotion", "fond",
                         "warm", "tender", "sweet", "kind", "gentle"]
        loveWords.forEach { wordEmotionMap[$0] = .love }
        
        // HEROIC / POWERFUL
        let heroicWords = ["hero", "power", "strong", "brave", "courage", "fearless", "might",
                           "warrior", "champion", "victory", "win", "conquer", "defeat",
                           "protect", "save", "rescue", "fight", "battle", "triumph",
                           "glory", "honor", "legend", "epic", "mighty", "unstoppable"]
        heroicWords.forEach { wordEmotionMap[$0] = .heroic }
        
        print("🌳 SemanticEmotionGraph: Built with \(wordEmotionMap.count) word mappings")
    }
    
    // MARK: - Animation Mappings
    
    private func buildAnimationMappings() {
        // Each emotion maps to multiple animation IDs for variety
        emotionToAnimation = [
            .joy: [1, 2, 3, 4, 5],          // Bouncy, sparkly animations
            .sadness: [10, 11, 12, 13],      // Slow, droopy animations
            .anger: [20, 21, 22, 23],        // Sharp, intense animations
            .fear: [30, 31, 32],             // Trembling, shrinking animations
            .surprise: [40, 41, 42, 43],     // Pop, expand animations
            .curiosity: [50, 51, 52],        // Tilt, look-around animations
            .excitement: [60, 61, 62, 63],   // Fast, energetic animations
            .calm: [70, 71, 72],             // Slow, breathing animations
            .love: [80, 81, 82, 83],         // Heart, warm animations
            .heroic: [90, 91, 92, 93, 94],   // Power-up, glow animations
            .neutral: [0]                     // Default idle
        ]
    }
    
    // MARK: - Emotion → SF Symbol Mapping
    
    func symbolsForEmotion(_ emotion: EmotionNode) -> [String] {
        switch emotion {
        case .joy:
            return ["sun.max.fill", "sparkles", "star.fill", "party.popper.fill", "face.smiling.fill"]
        case .sadness:
            return ["cloud.rain.fill", "drop.fill", "moon.fill", "heart.slash.fill"]
        case .anger:
            return ["bolt.fill", "flame.fill", "exclamationmark.triangle.fill", "burst.fill"]
        case .fear:
            return ["eye.fill", "exclamationmark.shield.fill", "hand.raised.fill", "lightbulb.slash.fill"]
        case .surprise:
            return ["exclamationmark.circle.fill", "eyes", "lightbulb.fill", "burst.fill"]
        case .curiosity:
            return ["magnifyingglass", "questionmark.circle.fill", "eye.circle.fill", "brain.head.profile"]
        case .excitement:
            return ["bolt.heart.fill", "figure.run", "flame.circle.fill", "waveform.path.ecg"]
        case .calm:
            return ["leaf.fill", "cloud.fill", "moon.stars.fill", "water.waves"]
        case .love:
            return ["heart.fill", "heart.circle.fill", "hand.thumbsup.fill", "sparkle.magnifyingglass"]
        case .heroic:
            return ["shield.fill", "star.circle.fill", "crown.fill", "bolt.shield.fill", "figure.martial.arts"]
        case .neutral:
            return ["circle.fill", "face.smiling", "person.fill"]
        }
    }
    
    // MARK: - Get Color for Emotion
    
    func colorForEmotion(_ emotion: EmotionNode) -> Color {
        switch emotion {
        case .joy: return .yellow
        case .sadness: return .blue
        case .anger: return .red
        case .fear: return .purple
        case .surprise: return .orange
        case .curiosity: return .cyan
        case .excitement: return .pink
        case .calm: return .mint
        case .love: return .pink
        case .heroic: return .indigo
        case .neutral: return .gray
        }
    }
}

// MARK: - Emotion Node Enum

enum EmotionNode: String, CaseIterable, Hashable {
    case joy
    case sadness
    case anger
    case fear
    case surprise
    case curiosity
    case excitement
    case calm
    case love
    case heroic
    case neutral
    
    var displayName: String {
        rawValue.capitalized
    }
    
    var emoji: String {
        switch self {
        case .joy: return "😊"
        case .sadness: return "😢"
        case .anger: return "😠"
        case .fear: return "😨"
        case .surprise: return "😲"
        case .curiosity: return "🤔"
        case .excitement: return "🤩"
        case .calm: return "😌"
        case .love: return "❤️"
        case .heroic: return "💪"
        case .neutral: return "😐"
        }
    }
    
    func toEmotionState() -> EmotionState {
        switch self {
        case .joy: return .happy
        case .sadness: return .sad
        case .anger: return .angry
        case .fear: return .sad // Map fear to sad (negative)
        case .surprise: return .surprised
        case .curiosity: return .curious
        case .excitement: return .excited
        case .calm: return .calm
        case .love: return .love
        case .heroic: return .heroic
        case .neutral: return .neutral
        }
    }
}
