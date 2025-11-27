import Foundation
import Combine

struct ChatMessage: Identifiable, Codable {
    var id = UUID()
    let text: String
    let isUser: Bool
    let timestamp: Date
}

protocol ChatProvider {
    func sendMessage(_ text: String, history: [ChatMessage]) async throws -> (String, String?) // Response text, Emotion Tag
    func generateIdleMessage(history: [ChatMessage]) async throws -> (String, String?) // Idle text, Emotion Tag
}

class LocalChatService: ChatProvider {
    private let companionName: String
    
    init(companionName: String = "PCPOS") {
        self.companionName = companionName
    }
    
    func sendMessage(_ text: String, history: [ChatMessage]) async throws -> (String, String?) {
        // Simulate slight processing delay for realism
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        let lowerText = text.lowercased()
        
        // 1. Time & Date (Local Intelligence - SHORT)
        if lowerText.contains("time") {
            let time = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .short)
            return ("It's \(time).", "NEUTRAL")
        } else if lowerText.contains("date") || lowerText.contains("day") {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, MMM d"
            let date = formatter.string(from: Date())
            return ("\(date).", "NEUTRAL")
        }
        
        // 2. Basic Greetings & Small Talk (SHORT responses)
        if lowerText.contains("hello") || lowerText.contains("hi") {
            return ("Hey! What's up?", "HAPPY")
        } else if lowerText.contains("how are you") {
            return ("Doing great! You?", "HAPPY")
        } else if lowerText.contains("who are you") {
            return ("I'm \(companionName)! Your AI companion.", "HEROIC")
        }
        
        // 3. Emotional Reactions (Keyword based - SHORT)
        if lowerText.contains("sad") {
            return ("That's rough. I'm here.", "SAD")
        } else if lowerText.contains("angry") {
            return ("Take a breath. Let's talk.", "SURPRISED")
        } else if lowerText.contains("happy") {
            return ("Awesome! Love it!", "HAPPY")
        }
        
        // 4. Fallback / Upsell (SHORT)
        return ("Need Pro for that! Upgrade?", "NEUTRAL")
    }
    func generateIdleMessage(history: [ChatMessage]) async throws -> (String, String?) {
        // Simple random idle phrases for local mode
        let idlePhrases = [
            ("You're quiet... everything okay?", "curious"),
            ("I'm bored. Let's do something!", "energetic"),
            ("Did you know I can see you?", "happy"),
            ("Waiting for orders, Commander!", "heroic"),
            ("So... nice weather in the cyber world.", "neutral")
        ]
        return idlePhrases.randomElement() ?? ("Hello?", "neutral")
    }
}

@MainActor
class ChatService: ObservableObject {
    @Published var chatHistory: [ChatMessage] = []
    private let provider: ChatProvider
    private let companionName: String
    
    // DUAL-LAYER LLM
    private let localLLM = LocalLLMService.shared
    private let animationParser = AnimationParser.shared
    
    // Callbacks for animation updates
    var onAnimationUpdate: ((AnimationUpdate) -> Void)?
    var onQuickResponse: ((String) -> Void)?
    var onSearchIntent: (() -> Void)?
    
    // Default to Local Service
    init(provider: ChatProvider? = nil, companionName: String = "PCPOS") {
        self.companionName = companionName
        self.provider = provider ?? LocalChatService(companionName: companionName)
        loadHistory()
    }
    
    func sendMessage(_ text: String) async -> (String, String?) {
        let userMsg = ChatMessage(id: UUID(), text: text, isUser: true, timestamp: Date())
        DispatchQueue.main.async {
            self.chatHistory.append(userMsg)
            self.saveHistory()
        }
        
        // DUAL-LAYER FLOW:
        // 1. Local LLM responds instantly (0-500ms)
        // 2. Apply animation immediately
        // 3. Speak quick response
        // 4. If complex, wait 2s and escalate to online LLM
        
        print("ChatService: Processing with dual-layer LLM...")
        
        // Step 1: Local LLM (instant)
        let localResponse = await localLLM.process(text: text)
        print("ChatService: Local response: \(localResponse.quickReply)")
        
        // Step 2: Apply animation immediately
        onAnimationUpdate?(localResponse.mood)
        
        // Step 3: Quick response
        onQuickResponse?(localResponse.quickReply)
        
        // Handle search intent
        if localResponse.isSearchIntent {
            onSearchIntent?()
        }
        
        // Add local response to history
        let localMsg = ChatMessage(id: UUID(), text: localResponse.quickReply, isUser: false, timestamp: Date())
        DispatchQueue.main.async {
            self.chatHistory.append(localMsg)
            self.saveHistory()
        }
        
        // Step 4: Escalate to online if needed
        if localResponse.shouldEscalate && StoreManager.shared.isProAccess {
            // Wait 2 seconds before escalating to online
            print("ChatService: Escalating to online LLM in 2 seconds...")
            try? await Task.sleep(for: .seconds(2))
            
            // Build context with local response
            let contextText = "User asked: \"\(text)\". I initially responded: \"\(localResponse.quickReply)\". Provide a more detailed, enriched response."
            
            let openAIProvider = OpenAIChatService(apiKey: SecureConfig.shared.openAIAPIKey ?? "", companionName: companionName)
            
            do {
                let (onlineResponse, emotion) = try await openAIProvider.sendMessage(contextText, history: chatHistory)
                
                print("ChatService: Online response: \(onlineResponse)")
                
                // Parse and apply animation from online response  
                let (cleanText, animUpdate) = animationParser.parse(onlineResponse)
                if let anim = animUpdate {
                    onAnimationUpdate?(anim)
                }
                
                // Add online response to history
                let onlineMsg = ChatMessage(id: UUID(), text: cleanText, isUser: false, timestamp: Date())
                DispatchQueue.main.async {
                    self.chatHistory.append(onlineMsg)
                    self.saveHistory()
                }
                
                return (cleanText, emotion)
            } catch {
                print("ChatService: Online LLM error: \(error)")
                // Already have local response, so just return that
                return (localResponse.quickReply, localResponse.mood.emotion)
            }
        } else {
            // Not escalating - just use local response
            return (localResponse.quickReply, localResponse.mood.emotion)
        }
    }
    
    func generateIdleMessage() async -> (String, String?) {
        // STRICT GATING: Check Pro Access
        if !StoreManager.shared.isProAccess {
            let localProvider = LocalChatService(companionName: companionName)
            do {
                return try await localProvider.generateIdleMessage(history: chatHistory)
            } catch {
                return ("Hello?", "neutral")
            }
        }
        
        // Pro Mode: Use OpenAI
        guard let apiKey = SecureConfig.shared.openAIAPIKey else {
            // No API key: gracefully fall back to local idle message
            let localProvider = LocalChatService(companionName: companionName)
            do {
                return try await localProvider.generateIdleMessage(history: chatHistory)
            } catch {
                return ("Hello?", "neutral")
            }
        }
        let openAIProvider = OpenAIChatService(apiKey: apiKey, companionName: companionName)
        
        do {
            let (response, emotion) = try await openAIProvider.generateIdleMessage(history: chatHistory)
            
            let aiMsg = ChatMessage(id: UUID(), text: response, isUser: false, timestamp: Date())
            DispatchQueue.main.async {
                self.chatHistory.append(aiMsg)
                self.saveHistory()
            }
            return (response, emotion)
        } catch {
            return ("Lost in thought...", "neutral")
        }
    }
    
    // MARK: - Persistence
    private func saveHistory() {
        if let data = try? JSONEncoder().encode(chatHistory) {
            UserDefaults.standard.set(data, forKey: "chatHistory")
        }
    }
    
    private func loadHistory() {
        if let data = UserDefaults.standard.data(forKey: "chatHistory"),
           let history = try? JSONDecoder().decode([ChatMessage].self, from: data) {
            self.chatHistory = history
            
    // MARK: - Testing
    
    /// Test OpenAI API connectivity and response
    func testOpenAIConnection() async -> (success: Bool, message: String) {
        print("ChatService: Testing OpenAI connection...")
        
        // Check if using OpenAI provider
        guard let openAIProvider = provider as? OpenAIChatService else {
            return (false, "Not using OpenAI provider. Switch to OpenAI in settings.")
        }
        
        do {
            let (response, emotion) = try await openAIProvider.sendMessage(
                "Say 'Hello' in one word.",
                history: []
            )
            
            print("ChatService: ✅ OpenAI test successful")
            print("  Response: \(response)")
            print("  Emotion: \(emotion ?? "none")")
            
            return (true, "✅ Connected! Response: '\(response)'")
        } catch {
            print("ChatService: ❌ OpenAI test failed - \(error)")
            return (false, "❌ Failed: \(error.localizedDescription)")
        }
    }
}
        }
    }

// MARK: - OpenAI Implementation
class OpenAIChatService: ChatProvider {
    private let apiKey: String
    private let companionName: String
    
    private var systemPrompt: String {
        """
        You are a helpful, emotional companion inside a PCPOScompanion-style \(companionName).
    Your personality is Heroic, Cheerful, and Helpful.
    
        CRITICAL RULES:
        1. You must start EVERY response with an emotion tag in brackets: [HAPPY], [SAD], [SURPRISED], [NEUTRAL], [ANGRY].
        2. Keep responses EXTREMELY SHORT - maximum 10-15 words. Be concise and punchy.
        3. Think like a quick-witted AI companion, not a verbose assistant.
        
        Examples:
        "[HAPPY] Hey! What's up?"
        "[SAD] That's rough. I'm here."
        "[SURPRISED] Whoa! Really?"
        
        Never exceed 15 words. Be brief and impactful.
    """
    }
    
    init(apiKey: String, companionName: String = "PCPOS") {
        self.apiKey = apiKey
        self.companionName = companionName
    }
    
    func sendMessage(_ text: String, history: [ChatMessage]) async throws -> (String, String?) {
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Build Context from History (Last 10 messages)
        var messages: [[String: String]] = [
            ["role": "system", "content": systemPrompt]
        ]
        
        let recentHistory = history.suffix(10)
        for msg in recentHistory {
            messages.append(["role": msg.isUser ? "user" : "assistant", "content": msg.text])
        }
        messages.append(["role": "user", "content": text])
        
        let body: [String: Any] = [
            "model": "gpt-4o", // or gpt-3.5-turbo
            "messages": messages,
            "max_tokens": 50, // Reduced for shorter, quicker responses
            "temperature": 0.8 // Slightly higher for more personality
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        // Parse Response
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let choices = json["choices"] as? [[String: Any]],
           let firstChoice = choices.first,
           let message = firstChoice["message"] as? [String: Any],
           let content = message["content"] as? String {
            
            return parseEmotion(from: content)
        }
        
        throw NSError(domain: "OpenAIError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse response"])
    }
    
    private func parseEmotion(from text: String) -> (String, String?) {
        // Regex to find [TAG]
        let pattern = "\\[(HAPPY|SAD|SURPRISED|NEUTRAL|ANGRY)\\]"
        
        var emotionTag: String? = nil
        var cleanText = text
        
        if let range = text.range(of: pattern, options: .regularExpression) {
            let tagWithBrackets = String(text[range])
            emotionTag = tagWithBrackets.replacingOccurrences(of: "[", with: "").replacingOccurrences(of: "]", with: "")
            cleanText = text.replacingCharacters(in: range, with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        return (cleanText, emotionTag)
    }
    func generateIdleMessage(history: [ChatMessage]) async throws -> (String, String?) {
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let idlePrompt = """
        The user has been silent for a while. Generate a SHORT (max 10 words) idle remark to start a conversation.
        Be \(companionName). Use the emotion tag format [TAG] at the start.
        Context: Last message was "\(history.last?.text ?? "None")".
        """
        
        let body: [String: Any] = [
            "model": "gpt-4o",
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": idlePrompt]
            ],
            "max_tokens": 30,
            "temperature": 0.9
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let choices = json["choices"] as? [[String: Any]],
           let firstChoice = choices.first,
           let message = firstChoice["message"] as? [String: Any],
           let content = message["content"] as? String {
            return parseEmotion(from: content)
        }
        
        throw NSError(domain: "OpenAIError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse response"])
    }
}

