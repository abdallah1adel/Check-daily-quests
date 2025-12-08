import Foundation

/// ⚠️  DEPRECATED: This file should NOT be committed to version control
/// ⚠️  Use SecureConfig.swift and environment variables instead
/// ⚠️  This file is kept for backward compatibility only
///
/// Configuration for API keys and secrets (DEPRECATED)
/// IMPORTANT: Add this file to .gitignore to keep keys private
/// TODO: Remove this file once SecureConfig is fully implemented
struct Config {
    /// ⚠️  DEPRECATED: Use SecureConfig.shared.openAIAPIKey instead
    /// OpenAI API Key for Pro features
    static let openAIAPIKey = ""
    
    /// HuggingFace Token for model downloads
    static let huggingFaceToken = ""
}
