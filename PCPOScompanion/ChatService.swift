import Foundation
import Combine

struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
}

protocol ChatProvider {
    func sendMessage(_ text: String) async throws -> (String, String?) // Response text, Emotion Tag
}

class MockChatService: ChatProvider {
    func sendMessage(_ text: String) async throws -> (String, String?) {
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        let lowerText = text.lowercased()
        
        if lowerText.contains("hello") || lowerText.contains("hi") {
            return ("Hello there! I am online and ready.", "HAPPY")
        } else if lowerText.contains("sad") || lowerText.contains("bad") {
            return ("I'm sorry to hear that. I'm here for you.", "SAD")
        } else if lowerText.contains("joke") {
            return ("Why did the robot go to the doctor? Because it had a virus!", "HAPPY")
        } else if lowerText.contains("angry") {
            return ("Whoa, take it easy! Let's calm down.", "SURPRISED")
        } else {
            return ("I see. Tell me more about that.", "NEUTRAL")
        }
    }
}

// Real Implementation
class OpenAIChatService: ChatProvider {
    private let apiKey: String
    private let systemPrompt = """
    You are a helpful, emotional companion inside a PCPOScompanion-style NetNavi.
    Your personality is Heroic, Cheerful, and Helpful.
    
    IMPORTANT: You must start EVERY response with an emotion tag in brackets.
    Available tags: [HAPPY], [SAD], [SURPRISED], [NEUTRAL], [ANGRY].
    
    Example: "[HAPPY] Hello! It's great to see you!"
    Example: "[SAD] Oh no, that sounds terrible."
    
    Keep responses short and conversational (1-2 sentences).
    """
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    func sendMessage(_ text: String) async throws -> (String, String?) {
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "model": "gpt-4o", // or gpt-3.5-turbo
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": text]
            ],
            "max_tokens": 100
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
}
