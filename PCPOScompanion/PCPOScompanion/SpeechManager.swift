import Foundation
import Speech
import AVFoundation
import Combine

@MainActor
class SpeechManager: NSObject, ObservableObject, SFSpeechRecognizerDelegate, AVSpeechSynthesizerDelegate {
    // STT
    private let speechRecognizer: SFSpeechRecognizer
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    @Published var recognizedText: String = ""
    @Published var isListening: Bool = false
    
    // TTS
    private let synthesizer = AVSpeechSynthesizer()
    private var audioPlayer: AVAudioPlayer?
    
    @Published var isSpeaking: Bool = false
    @Published var audioLevel: Float = 0.0 // For mouth animation
    @Published var selectedVoiceIdentifier: String? = nil
    @Published var speechRate: Float = 0.5
    
    // External TTS
    @Published var currentProvider: TTSProvider = .apple
    @Published var apiKey: String = ""
    
    private let elevenLabsService = ElevenLabsService()
    private let openAIService = OpenAITTSService()
    
    override init() {
        // Initialize speech recognizer safely - fallback to default locale if en-US not available
        // According to Apple docs, SFSpeechRecognizer(locale:) returns optional
        // Prefer en-US, fallback to current locale, then to any available locale
        if let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US")) {
            self.speechRecognizer = recognizer
        } else if let recognizer = SFSpeechRecognizer(locale: Locale.current) {
            // Fallback to current locale
            self.speechRecognizer = recognizer
        } else {
            // Last resort: find any available locale that supports speech recognition
            // This should be extremely rare, but we handle it gracefully
            let availableLocales = Locale.availableIdentifiers
            var foundRecognizer: SFSpeechRecognizer?
            for localeId in availableLocales {
                if let recognizer = SFSpeechRecognizer(locale: Locale(identifier: localeId)) {
                    foundRecognizer = recognizer
                    break
                }
            }
            // If we still can't find one, force unwrap en-US as absolute last resort
            // This should never happen in practice
            self.speechRecognizer = foundRecognizer ?? SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
        }
        
        super.init()
        speechRecognizer.delegate = self
        synthesizer.delegate = self
        loadVoiceSettings()
        requestPermissions()
        // Don't configure session immediately to avoid blocking other audio
    }
    
    private func loadVoiceSettings() {
        selectedVoiceIdentifier = PersistenceManager.shared.loadVoiceIdentifier()
        speechRate = PersistenceManager.shared.loadSpeechRate()
        currentProvider = PersistenceManager.shared.loadTTSProvider()
        apiKey = PersistenceManager.shared.loadTTSApiKey()
    }
    
    func updateVoice(identifier: String?) {
        selectedVoiceIdentifier = identifier
        PersistenceManager.shared.saveVoiceIdentifier(identifier ?? "")
    }
    
    func updateSpeechRate(_ rate: Float) {
        speechRate = rate
        PersistenceManager.shared.saveSpeechRate(rate)
    }
    
    func updateProvider(_ provider: TTSProvider) {
        currentProvider = provider
        PersistenceManager.shared.saveTTSProvider(provider)
    }
    
    func updateApiKey(_ key: String) {
        apiKey = key
        PersistenceManager.shared.saveTTSApiKey(key)
    }
    
    private func requestPermissions() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    print("Speech authorized")
                case .denied, .restricted, .notDetermined:
                    print("Speech not authorized")
                @unknown default:
                    break
                }
            }
        }
    }
    
    private func configureAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Audio Session Error: \(error)")
        }
    }
    
    // MARK: - Speech to Text
    
    func startListening() {
        PCPOSHaptics.shared.playListeningStart()
        
        configureAudioSession() // Activate only when needed
        
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        guard !audioEngine.isRunning else { return }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return }
        recognitionRequest.shouldReportPartialResults = true
        
        let inputNode = audioEngine.inputNode
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            if let result = result {
                DispatchQueue.main.async {
                    self.recognizedText = result.bestTranscription.formattedString
                }
            }
            
            if error != nil || (result?.isFinal ?? false) {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                self.recognitionRequest = nil
                self.recognitionTask = nil
                DispatchQueue.main.async {
                    self.isListening = false
                }
            }
        }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        do {
            try audioEngine.start()
            DispatchQueue.main.async { self.isListening = true }
        } catch {
            print("Audio engine start failed")
        }
    }
    
    func stopListening() {
        PCPOSHaptics.shared.playListeningStop()
        
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        isListening = false
    }
    
    func clearRecognizedText() {
        recognizedText = ""
    }
    
    // MARK: - Text to Speech
    
    // UPDATED SPEAK FUNCTION
    func speak(_ text: String) {
        PCPOSHaptics.shared.playSpeakingStart()
        
        // Check provider
        // We allow empty API key here because speakExternal handles the system key fallback for OpenAI
        if currentProvider != .apple {
            speakExternal(text: text)
        } else {
            speakApple(text: text)
        }
    }
    
    private func speakExternal(text: String) {
        let service: TTSServiceProtocol
        let voiceId: String? = nil // Use default for now, or map from settings
        
        // Determine API Key
        var effectiveApiKey = apiKey
        if effectiveApiKey.isEmpty {
            if currentProvider == .openAI {
                effectiveApiKey = SecureConfig.shared.openAIAPIKey ?? ""
            }
        }
        
        // If still empty, fallback
        if effectiveApiKey.isEmpty {
            print("SpeechManager: No API Key found for \(currentProvider). Falling back to Apple TTS.")
            speakApple(text: text)
            return
        }
        
        switch currentProvider {
        case .elevenLabs:
            service = elevenLabsService
        case .openAI:
            service = openAIService
        case .xtts: // NEW: Local XTTS
            print("SpeechManager: Requesting local XTTS...")
            DispatchQueue.main.async { self.isSpeaking = true }
            
            PythonBridge.shared.generateSpeech(text: text) { [weak self] data in
                guard let self = self else { return }
                if let data = data {
                    print("SpeechManager: Received local audio (\(data.count) bytes).")
                    self.playAudio(data: data)
                } else {
                    print("SpeechManager: Local TTS failed. Fallback to Apple.")
                    DispatchQueue.main.async { self.speakApple(text: text) }
                }
            }
            return
        default:
            speakApple(text: text)
            return
        }
        
        print("SpeechManager: Requesting external TTS from \(currentProvider)...")
        DispatchQueue.main.async { self.isSpeaking = true }
        
        service.generateAudio(text: text, voiceId: voiceId, apiKey: effectiveApiKey) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let data):
                print("SpeechManager: Received audio data (\(data.count) bytes). Playing...")
                self.playAudio(data: data)
            case .failure(let error):
                print("SpeechManager: External TTS Error: \(error). Falling back to Apple TTS.")
                // Fallback to Apple
                DispatchQueue.main.async {
                    self.speakApple(text: text)
                }
            }
        }
    }
    
    private func playAudio(data: Data) {
        DispatchQueue.main.async {
            do {
                self.audioPlayer = try AVAudioPlayer(data: data)
                self.audioPlayer?.delegate = self // We need to conform to AVAudioPlayerDelegate
                self.audioPlayer?.prepareToPlay()
                self.audioPlayer?.play()
                self.startAudioLevelMonitoring()
            } catch {
                print("Audio Player Error: \(error)")
                self.isSpeaking = false
            }
        }
    }
    
    private func speakApple(text: String) {
        let utterance = AVSpeechUtterance(string: text)
        
        // Use selected voice or default to enhanced voice
        if let identifier = selectedVoiceIdentifier,
           let voice = AVSpeechSynthesisVoice(identifier: identifier) {
            utterance.voice = voice
            } else {
            // Default to enhanced quality voice if available, otherwise default en-US
            // According to Apple docs, AVSpeechSynthesisVoice(language:) returns optional
            var defaultVoice: AVSpeechSynthesisVoice?
            
            if #available(iOS 13.0, *) {
                // Try to find enhanced quality voice (Siri/Samantha/Enhanced)
                let allVoices = AVSpeechSynthesisVoice.speechVoices()
                
                // First try: Siri/Samantha/Enhanced voices
                defaultVoice = allVoices.first(where: { 
                    $0.language == "en-US" && 
                    $0.quality == .enhanced && 
                    ($0.name.localizedCaseInsensitiveContains("Siri") || 
                     $0.name.localizedCaseInsensitiveContains("Samantha") || 
                     $0.name.localizedCaseInsensitiveContains("Enhanced"))
                })
                
                // Second try: Any enhanced quality voice
                if defaultVoice == nil {
                    defaultVoice = allVoices.first(where: { 
                        $0.language == "en-US" && $0.quality == .enhanced 
                    })
                }
            }
            
            // Final fallback: standard en-US voice (handles optional properly)
            if defaultVoice == nil {
                defaultVoice = AVSpeechSynthesisVoice(language: "en-US")
            }
            
            utterance.voice = defaultVoice
        }
        
        utterance.rate = speechRate
        
        DispatchQueue.main.async { self.isSpeaking = true }
        synthesizer.speak(utterance)
        
        // Simulate Audio Levels for Animation (Lip Sync)
        startAudioLevelMonitoring()
    }
    
    // MARK: - AVSpeechSynthesizerDelegate
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { self.isSpeaking = true }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { self.isSpeaking = false }
        stopAudioLevelMonitoring()
    }
    
    // MARK: - Audio Level Simulation (for mouth animation)
    
    private var levelTimer: Timer?
    
    private func startAudioLevelMonitoring() {
        // Since AVSpeechSynthesizer doesn't give easy audio buffers, we simulate "talking" levels
        // In a real app, we might analyze the output buffer or use a viseme delegate if available (iOS 17+ has some support)
        // For now, random noise modulated by a sine wave looks okay.
        
        // If using AVAudioPlayer, we can get metering!
        if let player = audioPlayer, player.isPlaying {
            player.isMeteringEnabled = true
        }
        
        levelTimer?.invalidate()
        levelTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            var level: Float = 0.0
            
            if let player = self.audioPlayer, player.isPlaying {
                player.updateMeters()
                let power = player.averagePower(forChannel: 0) // -160 to 0 dB
                // Normalize to 0-1
                let normalized = max(0, (power + 30) / 30) // Clip below -30dB
                level = normalized
            } else {
                // Simulation for AVSpeechSynthesizer
            let random = Float.random(in: 0.2...0.8)
                level = random
            }
            
            DispatchQueue.main.async {
                self.audioLevel = level
                // Directly drive PersonalityEngine
                PersonalityEngine.shared.animationParams.mouthOpen = CGFloat(level) * 0.8
            }
        }
    }
    
    private func stopAudioLevelMonitoring() {
        levelTimer?.invalidate()
        levelTimer = nil
        DispatchQueue.main.async { 
            self.audioLevel = 0.0 
            PersonalityEngine.shared.animationParams.mouthOpen = 0
        }
    }
}

extension SpeechManager: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async { self.isSpeaking = false }
        stopAudioLevelMonitoring()
    }
}



