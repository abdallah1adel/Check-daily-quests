import Foundation
import Combine

/// Privacy-First Orchestrator
/// Coordinates local AI with OpenAI guidance without exposing raw data
@MainActor
class PrivacyOrchestrator: ObservableObject {
    static let shared = PrivacyOrchestrator()
    
    @Published var lastSync: Date?
    @Published var syncInterval: TimeInterval = 2.0 // Every 2 seconds
    
    private var syncTimer: Timer?
    private var metadataCache: [MetadataGraph] = []
    private let maxCacheSize = 10
    
    private init() {
        startPeriodicSync()
    }
    
    // MARK: - Privacy-Preserving Processing
    
    /// Process user input without sending raw text to cloud
    func processLocally(
        text: String,
        emotion: PADEmotion,
        history: [ChatMessage]
    ) async -> (response: String, emotion: String?) {
        
        print("PrivacyOrchestrator: Processing locally (text NEVER leaves device)")
        
        // 1. Extract metadata graph (no raw text)
        let metadata = MetadataGraph.extract(from: text, emotion: emotion, history: history)
        cacheMetadata(metadata)
        
        // 2. "Think hard" - Learn from user behavior
        let observation = UserTraitsEngine.UserObservation(
            text: text,
            emotion: emotion,
            timestamp: Date(),
            intent: metadata.intent,
            responseTime: metadata.conversationState.avgResponseTime
        )
        UserTraitsEngine.shared.think(about: observation)
        
        // 3. Get local AI response
        let localResponse = await LocalLLMService.shared.process(text: text)
        
        // 4. Get tuning guidance from OpenAI (only metadata sent)
        let tuning = await fetchTuningGuidance(metadata: metadata)
        
        // 5. Re-orchestrate with tuning AND user traits
        let finalResponse = await applyTuning(
            localResponse: localResponse,
            tuning: tuning,
            originalText: text,
            userEmotion: emotion
        )
        
        return (finalResponse.quickReply, finalResponse.mood.emotion)
    }
    
    // MARK: - Periodic Metadata Sync
    
    private func startPeriodicSync() {
        syncTimer?.invalidate()
        
        syncTimer = Timer.scheduledTimer(withTimeInterval: syncInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.syncMetadataToCloud()
            }
        }
    }
    
    private func syncMetadataToCloud() async {
        guard !metadataCache.isEmpty else { return }
        
        print("PrivacyOrchestrator: Syncing \(metadataCache.count) metadata entries (NO RAW TEXT)")
        
        // Send only metadata graph to OpenAI
        await sendMetadataBatch(metadataCache)
        
        lastSync = Date()
        
        // Clear cache after sync
        if metadataCache.count > maxCacheSize {
            metadataCache.removeFirst(metadataCache.count - maxCacheSize)
        }
    }
    
    private func cacheMetadata(_ metadata: MetadataGraph) {
        metadataCache.append(metadata)
        
        if metadataCache.count >= maxCacheSize {
            // Trigger immediate sync if cache is full
            Task {
                await syncMetadataToCloud()
            }
        }
    }
    
    // MARK: - OpenAI Tuning (Metadata Only)
    
    private func fetchTuningGuidance(metadata: MetadataGraph) async -> TuningGuidance? {
        // TODO: Send ONLY metadata to OpenAI
        // OpenAI analyzes patterns and returns tuning parameters
        
        print("PrivacyOrchestrator: Requesting tuning from OpenAI (metadata only)")
        
        /*
        let payload = try? JSONEncoder().encode(metadata)
        
        // Call OpenAI with metadata-only request
        let tuning = await cloudService.getTuning(metadata: payload)
        return tuning
        */
        
        // Simulated tuning response
        return TuningGuidance(
            suggestedEmotion: "HAPPY",
            responseStrategy: .empathetic,
            confidenceBoost: 0.2,
            suggestedTopics: ["wellbeing", "support"]
        )
    }
    
    private func sendMetadataBatch(_ batch: [MetadataGraph]) async {
        // TODO: Batch send metadata for pattern analysis
        print("PrivacyOrchestrator: Batch sync \(batch.count) entries")
        
        /*
        let payload = try? JSONEncoder().encode(batch)
        await cloudService.syncMetadata(payload)
        */
    }
    
    // MARK: - Local Re-Orchestration
    
    private func applyTuning(
        localResponse: LocalLLMResponse,
        tuning: TuningGuidance?,
        originalText: String,
        userEmotion: PADEmotion
    ) async -> LocalLLMResponse {
        
        guard let tuning = tuning else {
            // No tuning, but still adapt to user traits
            var adapted = localResponse
            adapted.quickReply = UserTraitsEngine.shared.adaptResponse(adapted.quickReply)
            return adapted
        }
        
        print("PrivacyOrchestrator: Applying cloud tuning + user traits")
        
        // Adjust local response based on tuning
        var adjustedResponse = localResponse
        
        // Update emotion if suggested (or use learned preference)
        if let suggestedEmotion = tuning.suggestedEmotion {
            adjustedResponse.mood.emotion = suggestedEmotion
        } else {
            // Use learned user preference
            adjustedResponse.mood.emotion = UserTraitsEngine.shared.suggestEmotionResponse(to: userEmotion)
        }
        
        // Boost confidence
        adjustedResponse.confidence = min(1.0, adjustedResponse.confidence + tuning.confidenceBoost)
        
        // Adjust response strategy
        switch tuning.responseStrategy {
        case .empathetic:
            adjustedResponse.mood.valence = max(adjustedResponse.mood.valence, 0.5)
        case .playful:
            adjustedResponse.mood.arousal = max(adjustedResponse.mood.arousal, 0.7)
        case .brief:
            // Keep response short
            break
        case .detailed:
            adjustedResponse.shouldEscalate = true // Escalate for more detail
        default:
            break
        }
        
        // MIMIC USER: Adapt response to match user's communication style
        adjustedResponse.quickReply = UserTraitsEngine.shared.adaptResponse(adjustedResponse.quickReply)
        
        return adjustedResponse
    }
    
    deinit {
        syncTimer?.invalidate()
    }
}
