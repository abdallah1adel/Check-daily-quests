import SwiftUI
import AVFoundation
import CoreML

// MARK: - Voice Profile Manager
// Handles voice fingerprinting, user identification, and profile switching

class VoiceProfileManager: NSObject, ObservableObject {
    
    // MARK: - Published State
    @Published var isListening: Bool = false
    @Published var identifiedUser: String? = nil
    @Published var confidence: Double = 0.0
    
    // MARK: - Audio Engine
    private let audioEngine = AVAudioEngine()
    private var recognitionTask: Task<Void, Never>?
    
    // MARK: - Profile Storage
    struct UserVoiceProfile: Codable {
        let id: String
        let name: String
        let embedding: [Float] // 512-dim vector
        let themeColor: String // Hex color
    }
    
    @Published var profiles: [UserVoiceProfile] = []
    
    // MARK: - Initialization
    override init() {
        super.init()
        loadProfiles()
        setupAudioSession()
    }
    
    // MARK: - Audio Setup
    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .measurement, options: .duckOthers)
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    // MARK: - Recording & Recognition
    
    func startListening() {
        guard !isListening else { return }
        isListening = true
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] (buffer, time) in
            self?.processAudioBuffer(buffer)
        }
        
        do {
            try audioEngine.start()
        } catch {
            print("Audio engine failed to start: \(error)")
            isListening = false
        }
    }
    
    func stopListening() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        isListening = false
    }
    
    // MARK: - Audio Processing
    
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        // Real-time ML Inference
        // This uses the SpeakerEncoder class (currently a wrapper, later the real model)
        
        guard let inputInfo = buffer.toMLMultiArray() else { return }
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            do {
                let model = try SpeakerEncoder()
                let input = SpeakerEncoderInput(audio: inputInfo)
                let output = try model.prediction(input: input)
                
                // Convert MLMultiArray to [Float]
                let embedding = self.convertMultiArrayToFloat(output.embedding)
                self.matchProfile(embedding: embedding)
                
            } catch {
                print("Voice ID Inference Error: \(error)")
            }
        }
    }
    
    private func convertMultiArrayToFloat(_ array: MLMultiArray) -> [Float] {
        var result: [Float] = []
        let count = array.count
        for i in 0..<count {
            result.append(array[i].floatValue)
        }
        return result
    }
    
    // MARK: - Profile Matching
    
    private func matchProfile(embedding: [Float]) {
        var bestMatch: UserVoiceProfile?
        var bestScore: Float = -1.0
        
        for profile in profiles {
            let score = cosineSimilarity(embedding, profile.embedding)
            if score > bestScore {
                bestScore = score
                bestMatch = profile
            }
        }
        
        DispatchQueue.main.async {
            if bestScore > 0.85 {
                self.identifiedUser = bestMatch?.name
                self.confidence = Double(bestScore)
                // Trigger profile switch
            } else {
                self.identifiedUser = nil
                self.confidence = 0.0
            }
        }
    }
    
    // MARK: - Math Helpers
    
    private func cosineSimilarity(_ a: [Float], _ b: [Float]) -> Float {
        guard a.count == b.count else { return 0 }
        
        var dotProduct: Float = 0
        var normA: Float = 0
        var normB: Float = 0
        
        for i in 0..<a.count {
            dotProduct += a[i] * b[i]
            normA += a[i] * a[i]
            normB += b[i] * b[i]
        }
        
        return dotProduct / (sqrt(normA) * sqrt(normB))
    }
    
    // MARK: - Profile Management
    
    func enrollUser(name: String, themeColor: String) {
        // Capture 5 seconds of audio
        // Generate average embedding
        // Save profile
        
        let newProfile = UserVoiceProfile(
            id: UUID().uuidString,
            name: name,
            embedding: (0..<512).map { _ in Float.random(in: -1...1) }, // Placeholder
            themeColor: themeColor
        )
        
        profiles.append(newProfile)
        saveProfiles()
    }
    
    private func saveProfiles() {
        if let data = try? JSONEncoder().encode(profiles) {
            UserDefaults.standard.set(data, forKey: "VoiceProfiles")
        }
    }
    
    private func loadProfiles() {
        if let data = UserDefaults.standard.data(forKey: "VoiceProfiles"),
           let loaded = try? JSONDecoder().decode([UserVoiceProfile].self, from: data) {
            profiles = loaded
        }
    }
}
