import Foundation
import Combine

class PythonBridge: ObservableObject {
    static let shared = PythonBridge()
    
    // Configuration
    private let pythonPath: String = {
        #if os(macOS)
        // Try to find python in the user's home directory ml_env (macOS only)
        let home = NSHomeDirectory()
        let envPath = "\(home)/ml_env/bin/python3"
        if FileManager.default.fileExists(atPath: envPath) {
            return envPath
        }
        // Fallback to system python or brew python
        return "/usr/bin/python3"
        #else
        // iOS does not support launching external Python processes; use a placeholder
        return "/usr/bin/python3"
        #endif
    }()
    
    private let graniteScriptPath = Bundle.main.path(forResource: "granite_server", ofType: "py", inDirectory: "PythonScripts") 
        ?? "/Users/pcpos/Desktop/PCPOScompanion/PCPOScompanion/PythonScripts/granite_server.py"
        
    private let ttsScriptPath = Bundle.main.path(forResource: "tts_server", ofType: "py", inDirectory: "PythonScripts")
        ?? "/Users/pcpos/Desktop/PCPOScompanion/PCPOScompanion/PythonScripts/tts_server.py"
    
    #if os(macOS)
    private var graniteProcess: Process?
    private var ttsProcess: Process?
    #endif
    
    @Published var isGraniteRunning = false
    @Published var isTTSRunning = false
    
    private init() {}
    
    func startServers() {
        startGraniteServer()
        startTTSServer()
    }
    
    private func startGraniteServer() {
        #if os(macOS)
        guard !isGraniteRunning else { return }
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: pythonPath)
        process.arguments = [graniteScriptPath]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        do {
            try process.run()
            graniteProcess = process
            isGraniteRunning = true
            print("PythonBridge: Granite Server started.")
            
            Task {
                for try await line in pipe.fileHandleForReading.bytes.lines {
                    print("Granite: \(line)")
                }
            }
        } catch {
            print("PythonBridge Error: Failed to start Granite server - \(error)")
        }
        #else
        print("PythonBridge: startGraniteServer is unavailable on iOS.")
        #endif
    }
    
    private func startTTSServer() {
        #if os(macOS)
        guard !isTTSRunning else { return }
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: pythonPath)
        process.arguments = [ttsScriptPath]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        do {
            try process.run()
            ttsProcess = process
            isTTSRunning = true
            print("PythonBridge: TTS Server started.")
            
            Task {
                for try await line in pipe.fileHandleForReading.bytes.lines {
                    print("TTS: \(line)")
                }
            }
        } catch {
            print("PythonBridge Error: Failed to start TTS server - \(error)")
        }
        #else
        print("PythonBridge: startTTSServer is unavailable on iOS.")
        #endif
    }
    
    func stopServers() {
        #if os(macOS)
        graniteProcess?.terminate()
        graniteProcess = nil
        isGraniteRunning = false
        
        ttsProcess?.terminate()
        ttsProcess = nil
        isTTSRunning = false
        
        print("PythonBridge: All servers stopped.")
        #else
        isGraniteRunning = false
        isTTSRunning = false
        print("PythonBridge: stopServers has no effect on iOS.")
        #endif
    }
    
    func generateSpeech(text: String, completion: @escaping (Data?) -> Void) {
        guard let url = URL(string: "http://127.0.0.1:5002/tts") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "text": text,
            "language": "en",
            "speaker_wav": "/Users/pcpos/Desktop/PCPOScompanion/PCPOScompanion/PythonScripts/reference_audio/pcpos_ref.wav" // Hardcoded for now
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("PythonBridge Error: TTS Request failed - \(error)")
                completion(nil)
                return
            }
            
            completion(data)
        }.resume()
    }
    
    // MARK: - Granite LLM Integration
    
    /// Call Granite 3.1 LLM via Python server
    func callGranite(prompt: String, maxTokens: Int = 100, temperature: Float = 0.7) async throws -> String {
        let url = URL(string: "http://127.0.0.1:5001/generate")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30  // 30 second timeout
        
        let body: [String: Any] = [
            "prompt": prompt,
            "max_tokens": maxTokens,
            "temperature": temperature,
            "system_prompt": "You are PCPOS, a helpful AI companion. Respond with emotion tags like [HAPPY], [SAD], [EXCITED] when appropriate."
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "PythonBridge", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        guard httpResponse.statusCode == 200 else {
            throw NSError(domain: "PythonBridge", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP \(httpResponse.statusCode)"])
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let responseText = json?["response"] as? String else {
            throw NSError(domain: "PythonBridge", code: -1, userInfo: [NSLocalizedDescriptionKey: "No response field"])
        }
        
        return responseText
    }
    
    /// Check if Granite server is running
    func isGraniteServerRunning() async -> Bool {
        guard let url = URL(string: "http://127.0.0.1:5001/health") else {
            return false
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            return json?["status"] as? String == "healthy"
        } catch {
            return false
        }
    }
}
