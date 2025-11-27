import Foundation
import Speech
import AVFoundation
import Combine

class SpeechManager: NSObject, ObservableObject, SFSpeechRecognizerDelegate, AVSpeechSynthesizerDelegate {
    // STT
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    @Published var recognizedText: String = ""
    @Published var isListening: Bool = false
    
    // TTS
    private let synthesizer = AVSpeechSynthesizer()
    @Published var isSpeaking: Bool = false
    @Published var audioLevel: Float = 0.0 // For mouth animation
    
    override init() {
        super.init()
        speechRecognizer.delegate = self
        synthesizer.delegate = self
        requestPermissions()
        // Don't configure session immediately to avoid blocking other audio
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
        configureAudioSession() // Activate only when needed
        
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        guard !audioEngine.isRunning else { return }
        
        // Cancel previous task
        // recognitionTask?.cancel() // Moved to the if block above
        // recognitionTask = nil // Moved to the if block above
        
        // Audio session setup moved to configureAudioSession()
        // let audioSession = AVAudioSession.sharedInstance()
        // do {
        //     try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        //     try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        // } catch {
        //     print("Audio session setup failed")
        // }
        
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
        audioEngine.stop()
        recognitionRequest?.endAudio()
        DispatchQueue.main.async { self.isListening = false }
    }
    
    // MARK: - Text to Speech
    
    // UPDATED SPEAK FUNCTION
    func speak(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5
        
        // We can't easily get buffers from AVSpeechSynthesizer for real-time analysis without saving to file first.
        // So we will simulate the "LipSync" by generating a fake waveform based on text length.
        
        isSpeaking = true
        synthesizer.speak(utterance)
        
        // Simulate Audio Levels for Animation
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            if !self.synthesizer.isSpeaking {
                timer.invalidate()
                self.isSpeaking = false
                self.audioLevel = 0
            } else {
                // Randomize slightly to look like talking
                self.audioLevel = Float.random(in: 0.2...0.8)
                
                // If we had LipSyncEngine working on output, we'd call:
                // self.lipSyncEngine?.processAudioBuffer(buffer)
            }
        }
    }
    
    // MARK: - AVSpeechSynthesizerDelegate
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { self.isSpeaking = true }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { self.isSpeaking = false }
        
        // Resume listening if needed? Or wait for user trigger.
    }
    // MARK: - Audio Level Simulation (for mouth animation)
    
    private var levelTimer: Timer?
    
    private func startAudioLevelMonitoring() {
        // Since AVSpeechSynthesizer doesn't give easy audio buffers, we simulate "talking" levels
        // In a real app, we might analyze the output buffer or use a viseme delegate if available (iOS 17+ has some support)
        // For now, random noise modulated by a sine wave looks okay.
        levelTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            let random = Float.random(in: 0.2...0.8)
            DispatchQueue.main.async {
                self?.audioLevel = random
            }
        }
    }
    
    private func stopAudioLevelMonitoring() {
        levelTimer?.invalidate()
        levelTimer = nil
        DispatchQueue.main.async { self.audioLevel = 0.0 }
    }
}
