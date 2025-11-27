import Foundation
import AVFoundation

enum TTSProvider: String, CaseIterable, Codable {
    case apple = "Apple (Device)"
    case elevenLabs = "ElevenLabs"
    case openAI = "OpenAI"
    case xtts = "Coqui XTTS (Local)"
}

protocol TTSServiceProtocol {
    func generateAudio(text: String, voiceId: String?, apiKey: String, completion: @escaping (Result<Data, Error>) -> Void)
}

// MARK: - ElevenLabs Service
class ElevenLabsService: TTSServiceProtocol {
    private let baseURL = "https://api.elevenlabs.io/v1/text-to-speech"
    
    func generateAudio(text: String, voiceId: String?, apiKey: String, completion: @escaping (Result<Data, Error>) -> Void) {
        // Default voice ID (Rachel) if none provided
        let voice = voiceId ?? "21m00Tcm4TlvDq8ikWAM"
        
        guard let url = URL(string: "\(baseURL)/\(voice)") else {
            completion(.failure(NSError(domain: "ElevenLabs", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue(apiKey, forHTTPHeaderField: "xi-api-key")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let body: [String: Any] = [
            "text": text,
            "model_id": "eleven_monolingual_v1",
            "voice_settings": [
                "stability": 0.5,
                "similarity_boost": 0.75
            ]
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(NSError(domain: "ElevenLabs", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])))
                return
            }
            
            if httpResponse.statusCode != 200 {
                let message = String(data: data ?? Data(), encoding: .utf8) ?? "Unknown error"
                completion(.failure(NSError(domain: "ElevenLabs", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: message])))
                return
            }
            
            if let data = data {
                completion(.success(data))
            } else {
                completion(.failure(NSError(domain: "ElevenLabs", code: -3, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
            }
        }.resume()
    }
}

// MARK: - OpenAI Service
class OpenAITTSService: TTSServiceProtocol {
    private let baseURL = "https://api.openai.com/v1/audio/speech"
    
    func generateAudio(text: String, voiceId: String?, apiKey: String, completion: @escaping (Result<Data, Error>) -> Void) {
        guard let url = URL(string: baseURL) else {
            completion(.failure(NSError(domain: "OpenAI", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Default to "alloy" if no voice provided
        let voice = voiceId?.lowercased() ?? "alloy"
        
        let body: [String: Any] = [
            "model": "tts-1",
            "input": text,
            "voice": voice
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(NSError(domain: "OpenAI", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])))
                return
            }
            
            if httpResponse.statusCode != 200 {
                let message = String(data: data ?? Data(), encoding: .utf8) ?? "Unknown error"
                completion(.failure(NSError(domain: "OpenAI", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: message])))
                return
            }
            
            if let data = data {
                completion(.success(data))
            } else {
                completion(.failure(NSError(domain: "OpenAI", code: -3, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
            }
        }.resume()
    }
}

// MARK: - Local XTTS Service (Python Bridge)
class LocalXTTSService: TTSServiceProtocol {
    private let baseURL = "http://localhost:5000/tts"
    
    func generateAudio(text: String, voiceId: String?, apiKey: String, completion: @escaping (Result<Data, Error>) -> Void) {
        guard let url = URL(string: baseURL) else {
            completion(.failure(NSError(domain: "XTTS", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // XTTS doesn't need an API key, but we pass language/speaker if needed
        let body: [String: Any] = [
            "text": text,
            "language": "en",
            "speaker_wav": "reference_audio/pcpos_ref.wav" // Ensure this file exists in Python script dir
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(NSError(domain: "XTTS", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])))
                return
            }
            
            if httpResponse.statusCode != 200 {
                let message = String(data: data ?? Data(), encoding: .utf8) ?? "Unknown error"
                completion(.failure(NSError(domain: "XTTS", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: message])))
                return
            }
            
            if let data = data {
                completion(.success(data))
            } else {
                completion(.failure(NSError(domain: "XTTS", code: -3, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
            }
        }.resume()
    }
}
