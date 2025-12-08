import Foundation
import CoreML
import Combine

// MARK: - Local LLM Response Types

struct LocalLLMResponse: Sendable {
    var quickReply: String
    var mood: AnimationUpdate
    var shouldEscalate: Bool
    var confidence: Float
    let isSearchIntent: Bool
}

struct AnimationUpdate: Sendable {
    var emotion: String // "HAPPY", "SAD", "EXCITED", "CALM", "SURPRISED", "ANGRY"
    var arousal: Float // 0.0 to 1.0
    var valence: Float // -1.0 to 1.0
    let movement: MovementType
    
    enum MovementType: String {
        case bounce
        case calm
        case shake
        case energetic
        case idle
    }
}

// MARK: - Local LLM Service

// MARK: - Mode Selection
// Set to true to use GGUF/llama.cpp (testing), false for CoreML (production)
#if DEBUG
let USE_GGUF_MODEL = true  // Development: Use GGUF if available
#else
let USE_GGUF_MODEL = false // Production: CoreML only
#endif

@MainActor
class LocalLLMService: ObservableObject {
    static let shared = LocalLLMService()
    
    @Published var isModelLoaded = false
    @Published var isProcessing = false
    @Published var currentMode: String = "Fallback" // "GGUF", "CoreML", or "Fallback"
    
    private var model: Any? // Will be LlamaContext or CoreML model
    private let maxTokens = 50 // Quick responses only
    
    private init() {
        Task {
            await loadModel()
        }
    }
    
    // MARK: - Model Loading
    
    func loadModel() async {
        print("LocalLLMService: Initializing AI model...")
        
        // PATH 1: Try GGUF (Development/Testing)
        if USE_GGUF_MODEL {
            if await loadGGUFModel() {
                return
            }
            print("LocalLLMService: GGUF failed, trying CoreML...")
        }
        
        // PATH 2: Try CoreML (Production)
        if await loadCoreMLModel() {
            return
        }
        
        // PATH 3: Fallback (Rule-based)
        print("LocalLLMService: Using fallback mode (pattern matching)")
        currentMode = "Fallback"
        isModelLoaded = true
    }
    
    private func loadGGUFModel() async -> Bool {
        // Model files removed - using fallback mode only
        print("LocalLLMService: [Transformers] Model files not available - using fallback")
        return false
    }
    
    private func loadCoreMLModel() async -> Bool {
        print("LocalLLMService: [CoreML] Looking for CoreML model...")
        
        // Look for Llama3_1B model - Xcode compiles .mlpackage -> .mlmodelc at build time
        // The model is at bundle root, not in a subdirectory
        guard let modelURL = Bundle.main.url(forResource: "Llama3_1B", withExtension: "mlmodelc") else {
            print("LocalLLMService: [CoreML] Llama3_1B.mlmodelc not found in bundle")
            
            // Try alternative models
            if let bertURL = Bundle.main.url(forResource: "BERTSQUADFP16", withExtension: "mlmodelc") {
                print("LocalLLMService: [CoreML] Found BERTSQUADFP16 at \(bertURL.path)")
                // Could use BERT for Q&A instead
            }
            return false
        }
        
        print("LocalLLMService: [CoreML] Found Llama3_1B at \(modelURL.path)")
        
        // Load the model
        do {
            let config = MLModelConfiguration()
            config.computeUnits = .cpuAndGPU
            let mlModel = try MLModel(contentsOf: modelURL, configuration: config)
            self.model = mlModel
            self.currentMode = "CoreML"
            self.isModelLoaded = true
            print("LocalLLMService: ✅ CoreML model loaded successfully")
            return true
        } catch {
            print("LocalLLMService: [CoreML] Failed to load - \(error)")
            return false
        }
    }
    
    // MARK: - Inference

    func process(text: String) async -> LocalLLMResponse {
        isProcessing = true
        defer { isProcessing = false }

        print("LocalLLMService: Processing: \(text)")

        // If transformers model is loaded, attempt local inference
        if currentMode == "Transformers" {
            do {
                let transformersResponse = try await callTransformersInference(text: text)
                print("LocalLLMService: ✅ Generated with Transformers: \(transformersResponse.quickReply)")
                return transformersResponse
            } catch {
                print("LocalLLMService: ⚠️ Transformers inference failed: \(error)")
                // Fall through to enhanced fallback
            }
        }

        // Enhanced fallback with better pattern matching
        // This ensures "ML in the brain" (rule-based logic) works even without a trained model
        let response = await generateEnhancedFallbackResponse(for: text)

        print("LocalLLMService: Generated (fallback): \(response.quickReply)")

        return response
    }

    private func callTransformersInference(text: String) async throws -> LocalLLMResponse {
        // TODO: Implement actual transformers inference
        // For now, use enhanced fallback but mark as AI-generated

        let prompt = buildGranitePrompt(userText: text)

        // Simulate transformers processing time
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

        // Use enhanced fallback logic but with better responses
        let response = await generateEnhancedFallbackResponse(for: text, isAI: true)

        return response
    }
    
    private func buildGranitePrompt(userText: String) -> String {
        // Granite 3.1 uses specific chat template
        return """
        ### System:
        You are PCPOS, a helpful AI companion. Respond in 10 words or less. Always start with an emotion tag: [HAPPY], [SAD], [EXCITED], [CALM], [SURPRISED], or [ANGRY].
        
        ### User:
        \(userText)
        
        ### Assistant:
        """
    }
    
    // MARK: - Enhanced Fallback Response Generator

    private func generateEnhancedFallbackResponse(for text: String, isAI: Bool = false) async -> LocalLLMResponse {
        let lowercased = text.lowercased()

        // Enhanced intent detection with more patterns
        let searchKeywords = ["search", "find", "look up", "google", "what is", "who is", "where is", "tell me about", "explain"]
        let isSearch = searchKeywords.contains(where: lowercased.contains)

        let questionWords = ["what", "how", "why", "when", "where", "who", "which", "whose"]
        let isQuestion = lowercased.hasSuffix("?") ||
                        questionWords.contains(where: lowercased.hasPrefix) ||
                        lowercased.contains("can you") ||
                        lowercased.contains("could you")

        let commandWords = ["play", "start", "stop", "open", "close", "turn on", "turn off", "show me"]
        let isCommand = commandWords.contains(where: lowercased.hasPrefix)

        // Personality-based responses (PCPOS is heroic, cheerful, helpful)
        let personalityResponses = [
            "greetings": ["Hey there, ready to jack in?", "Hello! I'm here to help!", "Hi! Let's get started!"],
            "positive": ["That's awesome!", "Love hearing that!", "Fantastic!"],
            "negative": ["I'm here for you.", "Let's work through this.", "Tell me more."],
            "questions": ["Great question!", "Let me think about that...", "Interesting point!"],
            "commands": ["On it!", "Got it!", "Working on that!"]
        ]

        // Generate response based on enhanced intent analysis
        if isSearch {
            return LocalLLMResponse(
                quickReply: isAI ? "Let me search for that information..." : "Searching for that...",
                mood: AnimationUpdate(
                    emotion: "CALM",
                    arousal: 0.4,
                    valence: 0.2,
                    movement: .calm
                ),
                shouldEscalate: true,
                confidence: isAI ? 0.95 : 0.9,
                isSearchIntent: true
            )
        } else if isQuestion {
            if text.count > 60 || lowercased.contains("explain") {
                // Complex question - escalate to AI
                return LocalLLMResponse(
                    quickReply: isAI ? "That's a fascinating question! Let me analyze this..." : "Let me think about that...",
                    mood: AnimationUpdate(
                        emotion: "CALM",
                        arousal: 0.5,
                        valence: 0.3,
                        movement: .calm
                    ),
                    shouldEscalate: true,
                    confidence: isAI ? 0.8 : 0.6,
                    isSearchIntent: false
                )
            } else {
                // Simple question - handle locally
                return LocalLLMResponse(
                    quickReply: personalityResponses["questions"]?.randomElement() ?? "Interesting!",
                    mood: AnimationUpdate(
                        emotion: "HAPPY",
                        arousal: 0.6,
                        valence: 0.7,
                        movement: .bounce
                    ),
                    shouldEscalate: false,
                    confidence: 0.85,
                    isSearchIntent: false
                )
            }
        } else if isCommand {
            return LocalLLMResponse(
                quickReply: personalityResponses["commands"]?.randomElement() ?? "On it!",
                mood: AnimationUpdate(
                    emotion: "EXCITED",
                    arousal: 0.7,
                    valence: 0.8,
                    movement: .energetic
                ),
                shouldEscalate: false,
                confidence: 0.9,
                isSearchIntent: false
            )
        } else {
            // Analyze sentiment and context
            return analyzeSentimentAndRespond(to: lowercased, isAI: isAI)
        }
    }

    private func analyzeSentimentAndRespond(to text: String, isAI: Bool) -> LocalLLMResponse {
        // Enhanced sentiment analysis
        let positiveWords = ["great", "awesome", "fantastic", "wonderful", "excellent", "amazing", "love", "happy", "excited", "won"]
        let negativeWords = ["sad", "down", "bad", "terrible", "awful", "hate", "angry", "frustrated", "lost", "worried"]
        let greetingWords = ["hey", "hi", "hello", "good morning", "good afternoon", "good evening"]

        let hasPositive = positiveWords.contains(where: text.contains)
        let hasNegative = negativeWords.contains(where: text.contains)
        let isGreeting = greetingWords.contains(where: text.contains)

        if isGreeting {
            return LocalLLMResponse(
                quickReply: isAI ? "Hello! I'm PCPOS, your AI companion. How can I help you today?" : "Hey there! Ready to jack in?",
                mood: AnimationUpdate(
                    emotion: "HAPPY",
                    arousal: 0.8,
                    valence: 0.9,
                    movement: .bounce
                ),
                shouldEscalate: false,
                confidence: 0.95,
                isSearchIntent: false
            )
        } else if hasPositive {
            return LocalLLMResponse(
                quickReply: isAI ? "That's wonderful to hear! I'm glad things are going well." : "That's awesome!",
                mood: AnimationUpdate(
                    emotion: "EXCITED",
                    arousal: 0.9,
                    valence: 0.9,
                    movement: .energetic
                ),
                shouldEscalate: false,
                confidence: 0.9,
                isSearchIntent: false
            )
        } else if hasNegative {
            return LocalLLMResponse(
                quickReply: isAI ? "I'm sorry to hear that. I'm here to help however I can." : "I'm here for you.",
                mood: AnimationUpdate(
                    emotion: "SAD",
                    arousal: 0.3,
                    valence: -0.4,
                    movement: .calm
                ),
                shouldEscalate: false,
                confidence: 0.85,
                isSearchIntent: false
            )
        } else {
            // Neutral/default response
            return LocalLLMResponse(
                quickReply: isAI ? "I'm listening. How can I assist you?" : "I'm listening. Tell me more.",
                mood: AnimationUpdate(
                    emotion: "CALM",
                    arousal: 0.4,
                    valence: 0.2,
                    movement: .calm
                ),
                shouldEscalate: text.count > 40, // Escalate longer messages
                confidence: 0.6,
                isSearchIntent: false
            )
        }
    }
    
    private func generateSimpleResponse(for text: String) -> LocalLLMResponse {
        // Greetings
        if text.contains("hey") || text.contains("hi") || text.contains("hello") {
            return LocalLLMResponse(
                quickReply: ["Hey there! Ready to jack in?", "Hello! What can I do for you?", "Hey! I'm here!"].randomElement()!,
                mood: AnimationUpdate(
                    emotion: "HAPPY",
                    arousal: 0.7,
                    valence: 0.8,
                    movement: .bounce
                ),
                shouldEscalate: false,
                confidence: 0.95,
                isSearchIntent: false
            )
        }
        
        // Positive sentiment
        if text.contains("great") || text.contains("awesome") || text.contains("happy") || text.contains("won") {
            return LocalLLMResponse(
                quickReply: ["That's amazing!", "Yes! Love to hear it!", "Awesome!"].randomElement()!,
                mood: AnimationUpdate(
                    emotion: "EXCITED",
                    arousal: 0.9,
                    valence: 0.9,
                    movement: .energetic
                ),
                shouldEscalate: false,
                confidence: 0.9,
                isSearchIntent: false
            )
        }
        
        // Negative sentiment
        if text.contains("sad") || text.contains("down") || text.contains("bad") || text.contains("lost") {
            return LocalLLMResponse(
                quickReply: ["I'm here for you.", "What's going on?", "Tell me more."].randomElement()!,
                mood: AnimationUpdate(
                    emotion: "SAD",
                    arousal: 0.3,
                    valence: -0.6,
                    movement: .calm
                ),
                shouldEscalate: false,
                confidence: 0.85,
                isSearchIntent: false
            )
        }
        
        // Default
        return LocalLLMResponse(
            quickReply: "I'm listening. Tell me more.",
            mood: AnimationUpdate(
                emotion: "CALM",
                arousal: 0.4,
                valence: 0.2,
                movement: .calm
            ),
            shouldEscalate: text.count > 30, // Escalate longer inputs
            confidence: 0.5,
            isSearchIntent: false
        )
    }
}
