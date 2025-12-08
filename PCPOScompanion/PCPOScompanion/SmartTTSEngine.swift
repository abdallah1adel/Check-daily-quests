import Foundation
import AVFoundation
import Combine

// MARK: - Smart TTS Engine (Uses Apple's AVSpeechSynthesizer)
// Replaces ElevenLabs with device-native TTS for no API cost

@MainActor
class SmartTTSEngine: ObservableObject {
    static let shared = SmartTTSEngine()
    
    private let synthesizer = AVSpeechSynthesizer()
    private var speechDelegate: SpeechDelegate?
    
    @Published var isSpeaking = false
    @Published var currentText = ""
    
    // Voice configuration
    var voiceIdentifier: String = "com.apple.voice.compact.en-US.Samantha"
    var rate: Float = AVSpeechUtteranceDefaultSpeechRate
    var pitch: Float = 1.0
    var volume: Float = 1.0
    
    init() {
        speechDelegate = SpeechDelegate(engine: self)
        synthesizer.delegate = speechDelegate
        
        // List available voices for debugging
        #if DEBUG
        let voices = AVSpeechSynthesisVoice.speechVoices()
        let englishVoices = voices.filter { $0.language.starts(with: "en") }
        print("🔊 Available English voices: \(englishVoices.map { $0.identifier })")
        #endif
    }
    
    // MARK: - Speak Methods
    
    func speak(_ text: String, emotion: TTSEmotion = .neutral) {
        guard !text.isEmpty else { return }
        
        // Stop any current speech
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        currentText = text
        isSpeaking = true
        
        // Create utterance
        let utterance = AVSpeechUtterance(string: text)
        
        // Apply emotion-based modifications
        applyEmotion(emotion, to: utterance)
        
        // Set voice
        if let voice = AVSpeechSynthesisVoice(identifier: voiceIdentifier) {
            utterance.voice = voice
        } else {
            // Fallback to default English voice
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        }
        
        utterance.volume = volume
        
        // Speak
        synthesizer.speak(utterance)
        print("🔊 Speaking: '\(text.prefix(50))...' with emotion: \(emotion)")
    }
    
    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
    }
    
    // MARK: - Emotion Application
    
    private func applyEmotion(_ emotion: TTSEmotion, to utterance: AVSpeechUtterance) {
        switch emotion {
        case .neutral:
            utterance.rate = rate
            utterance.pitchMultiplier = pitch
            
        case .happy:
            utterance.rate = rate * 1.1  // Slightly faster
            utterance.pitchMultiplier = pitch * 1.15  // Higher pitch
            
        case .sad:
            utterance.rate = rate * 0.85  // Slower
            utterance.pitchMultiplier = pitch * 0.9  // Lower pitch
            
        case .excited:
            utterance.rate = rate * 1.25  // Much faster
            utterance.pitchMultiplier = pitch * 1.2  // Higher pitch
            
        case .calm:
            utterance.rate = rate * 0.8  // Slower
            utterance.pitchMultiplier = pitch * 0.95  // Slightly lower
            
        case .heroic:
            utterance.rate = rate * 0.9  // Slightly slower, more deliberate
            utterance.pitchMultiplier = pitch * 0.85  // Deeper voice
            
        case .curious:
            utterance.rate = rate
            utterance.pitchMultiplier = pitch * 1.1  // Slightly higher
            
        case .angry:
            utterance.rate = rate * 1.15  // Faster
            utterance.pitchMultiplier = pitch * 0.95  // Slightly lower
        }
    }
    
    // MARK: - Voice Selection
    
    func setVoice(identifier: String) {
        voiceIdentifier = identifier
    }
    
    func availableVoices(language: String = "en") -> [AVSpeechSynthesisVoice] {
        return AVSpeechSynthesisVoice.speechVoices().filter { 
            $0.language.starts(with: language) 
        }
    }
    
    // MARK: - Delegate Handler
    
    fileprivate func didFinishSpeaking() {
        isSpeaking = false
        currentText = ""
    }
}

// MARK: - TTS Emotion Enum

enum TTSEmotion: String, CaseIterable {
    case neutral
    case happy
    case sad
    case excited
    case calm
    case heroic
    case curious
    case angry
    
    // Map from EmotionNode
    init(from emotionNode: EmotionNode) {
        switch emotionNode {
        case .joy: self = .happy
        case .sadness: self = .sad
        case .anger: self = .angry
        case .fear: self = .calm  // Speak calmly about fear
        case .surprise: self = .excited
        case .curiosity: self = .curious
        case .excitement: self = .excited
        case .calm: self = .calm
        case .love: self = .happy
        case .heroic: self = .heroic
        case .neutral: self = .neutral
        }
    }
}

// MARK: - Speech Delegate

private class SpeechDelegate: NSObject, AVSpeechSynthesizerDelegate {
    weak var engine: SmartTTSEngine?
    
    init(engine: SmartTTSEngine) {
        self.engine = engine
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            engine?.didFinishSpeaking()
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            engine?.didFinishSpeaking()
        }
    }
}
