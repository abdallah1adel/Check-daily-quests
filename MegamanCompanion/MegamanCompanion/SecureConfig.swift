import Foundation

/// Secure Configuration Manager
/// Handles environment variables and secure key management
/// This file is safe to commit - it only contains configuration logic, not actual keys
@MainActor
class SecureConfig {
    static let shared = SecureConfig()

    private init() {}

    // MARK: - Environment Variable Loading

    private func loadEnvironmentFile() -> [String: String] {
        var envVars: [String: String] = [:]

        // Try to load .env file from bundle (for development)
        if let envPath = Bundle.main.path(forResource: ".env", ofType: nil),
           let envContent = try? String(contentsOfFile: envPath, encoding: .utf8) {
            parseEnvironmentContent(envContent, into: &envVars)
        }

        return envVars
    }

    private func parseEnvironmentContent(_ content: String, into envVars: inout [String: String]) {
        let lines = content.components(separatedBy: .newlines)
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty, !trimmed.hasPrefix("#") else { continue }

            let components = trimmed.components(separatedBy: "=")
            guard components.count >= 2 else { continue }

            let key = components[0].trimmingCharacters(in: .whitespaces)
            let value = components[1...].joined(separator: "=").trimmingCharacters(in: .whitespaces)
            envVars[key] = value
        }
    }

    // MARK: - API Key Accessors

    var openAIAPIKey: String? {
        // Priority: Environment variable > Config struct (for backward compatibility)
        if let envKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] {
            return envKey
        }

        // Fallback to Config struct (will be removed in production)
        return Config.openAIAPIKey
    }

    var elevenLabsAPIKey: String? {
        // Check environment first
        if let envKey = ProcessInfo.processInfo.environment["ELEVENLABS_API_KEY"] {
            return envKey
        }

        // Fallback to user settings (stored securely in Keychain)
        return loadElevenLabsKeyFromKeychain()
    }

    var storeKitSharedSecret: String? {
        return ProcessInfo.processInfo.environment["STOREKIT_SHARED_SECRET"]
    }

    var isDevelopment: Bool {
        return ProcessInfo.processInfo.environment["APP_ENV"]?.lowercased() == "development" ||
               Config.openAIAPIKey != "your_openai_api_key_here" // Fallback check
    }

    // MARK: - Keychain Integration

    private func loadElevenLabsKeyFromKeychain() -> String? {
        // TODO: Implement proper Keychain storage
        // For now, return from UserDefaults (not secure!)
        return UserDefaults.standard.string(forKey: "elevenlabs_api_key")
    }

    func saveElevenLabsKeyToKeychain(_ key: String) {
        // TODO: Implement proper Keychain storage
        // For now, save to UserDefaults (not secure!)
        UserDefaults.standard.set(key, forKey: "elevenlabs_api_key")
    }

    // MARK: - Security Validation

    func validateAPIKeys() -> [String: Bool] {
        return [
            "OpenAI": openAIAPIKey?.hasPrefix("sk-") == true,
            "ElevenLabs": elevenLabsAPIKey?.count == 32, // ElevenLabs keys are 32 chars
            "StoreKit": storeKitSharedSecret?.isEmpty == false
        ]
    }

    func logSecurityStatus() {
        let validation = validateAPIKeys()
        print("🔐 Security Status:")
        print("  OpenAI API Key: \(validation["OpenAI"] == true ? "✅ Valid" : "❌ Invalid/Missing")")
        print("  ElevenLabs API Key: \(validation["ElevenLabs"] == true ? "✅ Valid" : "❌ Invalid/Missing")")
        print("  StoreKit Shared Secret: \(validation["StoreKit"] == true ? "✅ Set" : "❌ Missing")")
        print("  Environment: \(isDevelopment ? "🛠️ Development" : "🚀 Production")")
    }
}
