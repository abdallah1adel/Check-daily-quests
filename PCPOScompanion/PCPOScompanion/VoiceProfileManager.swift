import SwiftUI
import AVFoundation
import CoreML
import Combine

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
    
    // SpeakerEncoder CoreML model for voice embeddings
    private var speakerEncoderModel: MLModel?
    private var modelLoaded = false
    
    private func loadSpeakerEncoderModel() {
        guard !modelLoaded else { return }
        
        if let modelURL = Bundle.main.url(forResource: "SpeakerEncoder", withExtension: "mlmodelc") {
            do {
                let config = MLModelConfiguration()
                config.computeUnits = .cpuAndGPU
                speakerEncoderModel = try MLModel(contentsOf: modelURL, configuration: config)
                modelLoaded = true
                print("VoiceProfileManager: ✅ Loaded SpeakerEncoder CoreML Model")
            } catch {
                print("VoiceProfileManager: SpeakerEncoder load failed - \(error)")
            }
        } else {
            print("VoiceProfileManager: ⚠️ SpeakerEncoder.mlmodelc not found in bundle")
        }
    }
    
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        // Ensure model is loaded
        if !modelLoaded {
            loadSpeakerEncoderModel()
        }
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            var embedding: [Float]
            
            if let model = self.speakerEncoderModel {
                // Use real model inference
                // Note: Actual implementation depends on model input format
                // For now, using placeholder until input format is verified
                embedding = self.generateEmbeddingFromModel(buffer: buffer, model: model)
            } else {
                // Fallback: Generate random embedding for testing
                embedding = (0..<512).map { _ in Float.random(in: -1...1) }
            }
            
            self.matchProfile(embedding: embedding)
        }
    }
    
    private func generateEmbeddingFromModel(buffer: AVAudioPCMBuffer, model: MLModel) -> [Float] {
        // TODO: Implement actual audio preprocessing and model inference
        // This requires knowing the model's input specification
        // For now, return normalized audio features as placeholder
        
        guard let channelData = buffer.floatChannelData?[0] else {
            return (0..<512).map { _ in Float.random(in: -1...1) }
        }
        
        let frameCount = Int(buffer.frameLength)
        var features: [Float] = []
        
        // Simple feature extraction: take 512 evenly spaced samples
        let step = max(1, frameCount / 512)
        for i in stride(from: 0, to: min(frameCount, 512 * step), by: step) {
            features.append(channelData[i])
        }
        
        // Pad if needed
        while features.count < 512 {
            features.append(0.0)
        }
        
        return Array(features.prefix(512))
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
