import Foundation
import SwiftUI
import ActivityKit
import Combine

class PersonalityEngine: ObservableObject {

    
    static let shared = PersonalityEngine()

    @Published var personality: Personality {
        didSet { PersistenceManager.shared.savePersonality(personality) }
    }
    @Published var mood: CompanionMood = CompanionMood() {
        didSet { PersistenceManager.shared.saveMood(mood) }
    }
    @Published var companionName: String = "PCPOS" {
        didSet { 
            PersistenceManager.shared.saveCompanionName(companionName)
            // Restart activity with new name if active
            if activity != nil {
                endActivity()
                startActivity()
            }
            // Recreate chat service with new name
            chatService = ChatService(companionName: companionName)
        }
    }
    @Published var currentPulse: EmotionPulse = EmotionPulse()
    
    // Output for the renderer
    @Published var animationParams: AnimationParams = AnimationParams()
    @Published var exaggeratedExpressions: Bool = false // New Toggle
    @Published var currentPAD: PADEmotion = .neutral // NEW: PAD State
    
    private var targetPAD: PADEmotion = .neutral // Target for interpolation
    
    private var timer: Timer?
    private var lastBlinkTime: Date = Date()
    private var isBlinking: Bool = false
    private let blinkInterval: TimeInterval = 3.0 // Blink every 3 seconds on average
    private let blinkDuration: TimeInterval = 0.15 // Blink lasts 150ms
    
    // Gaze / Saccade Timer
    private var saccadeTimer: Timer?
    private var targetGazeX: CGFloat = 0.0
    private var targetGazeY: CGFloat = 0.0
    
    // Idle Talk Timer
    private var idleTimer: Timer?
    private let idleInterval: TimeInterval = 5.0
    private var lastInteractionTime: Date = Date()
    
    init() {
        self.personality = PersistenceManager.shared.loadPersonality()
        self.mood = PersistenceManager.shared.loadMood()
        self.companionName = PersistenceManager.shared.loadCompanionName()
        startLoop()
        startSaccades()
        resetIdleTimer()
    }
    
    private func startSaccades() {
        // Hyper Active: Faster eye movements (0.5 - 1.5 seconds)
        saccadeTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.triggerSaccade()
        }
    }
    
    private func triggerSaccade() {
        // 70% chance to look at center (user), 30% chance to look around (more active)
        if Double.random(in: 0...1) < 0.7 {
            targetGazeX = 0
            targetGazeY = 0
        } else {
            // Wider range for hyper active look
            targetGazeX = CGFloat.random(in: -0.8...0.8)
            targetGazeY = CGFloat.random(in: -0.4...0.4)
        }
        
        // Reset timer to random interval (faster)
        saccadeTimer?.invalidate()
        let nextInterval = Double.random(in: 0.3...2.0)
        saccadeTimer = Timer.scheduledTimer(withTimeInterval: nextInterval, repeats: true) { [weak self] _ in
            self?.triggerSaccade()
        }
    }
    
    func resetIdleTimer() {
        lastInteractionTime = Date()
        
        idleTimer?.invalidate()
        idleTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.checkIdle()
        }
    }
    
    private func checkIdle() {
        guard !isSpeaking else { 
            lastInteractionTime = Date() // Reset if speaking
            return 
        }
        
        if Date().timeIntervalSince(lastInteractionTime) > idleInterval {
            triggerIdleTalk()
            lastInteractionTime = Date() // Reset to avoid spamming
        }
    }
    
    private func triggerIdleTalk() {
        print("PersonalityEngine: Triggering Idle Talk")
        Task {
            let (response, emotionTag) = await chatService.generateIdleMessage()
            print("PersonalityEngine: Idle response generated: \(response.prefix(20))... Tag: \(String(describing: emotionTag))")
            
            DispatchQueue.main.async {
                if let tag = emotionTag {
                    self.setEmotionOverride(tag: tag)
                }
                self.response = response
            }
        }
    }
    
    func updateEmotion(pulse: EmotionPulse) {
        // Debug print for significant changes
        if abs(pulse.valence - currentPulse.valence) > 0.2 || pulse.detectedGesture != .none {
            print("PersonalityEngine: Update Emotion - Valence: \(pulse.valence), Gesture: \(pulse.detectedGesture)")
        }
        
        // Smooth transition
        let smoothing: CGFloat = 0.1
        currentPulse.valence = currentPulse.valence * (1 - smoothing) + pulse.valence * smoothing
        currentPulse.arousal = currentPulse.arousal * (1 - smoothing) + pulse.arousal * smoothing
        currentPulse.focus = currentPulse.focus * (1 - smoothing) + pulse.focus * smoothing
        
        // Update Mood (Long-term)
        // If arousal is high, energy goes up. If valence is high, mood goes up.
        mood.energy = min(max(mood.energy + (pulse.arousal * 0.01), 0), 1)
        mood.mood = min(max(mood.mood + (pulse.valence * 0.01), -1), 1)
        
        // Trigger Haptics if emotion is strong
        if abs(pulse.valence) > 0.8 || pulse.arousal > 0.8 {
            HapticsManager.shared.playEmotionHaptic(valence: pulse.valence, arousal: pulse.arousal)
        }
        
        // Handle Detected Gestures
        if pulse.detectedGesture != .none {
            handleGesture(pulse.detectedGesture)
        }
        
        updateAnimationParams()
    }
    
    private func handleGesture(_ gesture: Gesture) {
        switch gesture {
        case .nod:
            // User nodded -> Avatar nods back / Agrees
            setEmotionOverride(tag: "HAPPY")
            HapticsManager.shared.playSuccess()
            // Could trigger a "Yes!" speech if we wanted
        case .shake:
            // User shook head -> Avatar looks concerned / Disagrees
            setEmotionOverride(tag: "SAD") // Or concerned
            HapticsManager.shared.playError()
        case .winkLeft, .winkRight:
            // User winked -> Avatar smirks / Winks back
            // We don't have a wink animation yet, but we can smirk strongly
            setEmotionOverride(tag: "HAPPY")
            // Force a smirk in next update
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.animationParams.smirk = 0.8
            }
            HapticsManager.shared.playEnergetic()
        default:
            break
        }
    }
    
    private func startLoop() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            self?.updateAnimationParams()
            
            // Random Heartbeat if Trust is high
            if let mood = self?.mood, mood.trust > 0.8 && Double.random(in: 0...1) < 0.01 {
                HapticsManager.shared.playHeartbeat()
            }
            
            // Eye blink logic
            self?.checkBlink()
        }
    }
    
    private func checkBlink() {
        let now = Date()
        let timeSinceLastBlink = now.timeIntervalSince(lastBlinkTime)
        
        if !isBlinking {
            // Random chance to start a blink (roughly every 3-5 seconds)
            if timeSinceLastBlink > blinkInterval && Double.random(in: 0...1) < 0.02 {
                isBlinking = true
                lastBlinkTime = now
            }
        } else {
            // Check if blink should end
            if timeSinceLastBlink > blinkDuration {
                isBlinking = false
                lastBlinkTime = now
            }
        }
    }
    
    // Speaking State
    var isSpeaking: Bool = false
    var audioLevel: Float = 0.0
    
    // Emotion Override (from Chat)
    var emotionOverride: EmotionPulse?
    var overrideTimer: Timer?

    private func updateAnimationParams() {
        // 1. Interpolate PAD State
        let interpolationSpeed: Float = 0.05 // Smooth transition
        currentPAD = EmotionMapper.interpolate(from: currentPAD, to: targetPAD, progress: interpolationSpeed)
        
        // 2. Map PAD to Base Animation Params
        let padParams = EmotionMapper.map(currentPAD)
        
        // 3. Apply Smooth Transitions to Params
        let smoothFactor: CGFloat = 0.1
        
        animationParams.mouthSmile = lerp(animationParams.mouthSmile, padParams.mouthSmile, smoothFactor)
        animationParams.browRaise = lerp(animationParams.browRaise, padParams.browRaise, smoothFactor)
        animationParams.headTilt = lerp(animationParams.headTilt, padParams.headTilt, smoothFactor)
        
        // Color & Glow (PAD driven)
        animationParams.colorTint = padParams.colorTint
        
        // 4. Breathing Effect (Arousal driven)
        // Higher arousal = faster, shallower breathing
        let breathingRate = 0.5 + Double(currentPAD.arousal + 1.0) * 0.5 // 0.5 to 1.5 Hz
        let breathingDepth = 0.05 + CGFloat(currentPAD.arousal + 1.0) * 0.05 // 0.05 to 0.15 scale
        let time = Date().timeIntervalSince1970
        let breath = sin(time * breathingRate * .pi * 2) * breathingDepth
        
        animationParams.glow = lerp(animationParams.glow, padParams.glow + CGFloat(breath), smoothFactor)
        
        // 5. Eye Openness (PAD + Blink)
        if isBlinking {
            animationParams.eyeOpen = lerp(animationParams.eyeOpen, 0.0, 0.5)
        } else {
            animationParams.eyeOpen = lerp(animationParams.eyeOpen, padParams.eyeOpen, smoothFactor)
        }
        
        // 6. Gaze (Saccades)
        // Dominance affects gaze stability (High dominance = steady gaze)
        let stability = CGFloat(currentPAD.dominance + 1.0) * 0.5 // 0 to 1
        let finalTargetGazeX = targetGazeX * (1.0 - stability * 0.5)
        let finalTargetGazeY = targetGazeY * (1.0 - stability * 0.5)
        
        animationParams.gazeX = lerp(animationParams.gazeX, finalTargetGazeX, 0.2)
        animationParams.gazeY = lerp(animationParams.gazeY, finalTargetGazeY, 0.2)
        
        // 7. Lip Sync (Speaking Override)
        if isSpeaking {
            let targetMouthOpen = CGFloat(audioLevel) * 0.8
            animationParams.mouthOpen = lerp(animationParams.mouthOpen, targetMouthOpen, 0.3)
        } else {
            animationParams.mouthOpen = lerp(animationParams.mouthOpen, 0.0, 0.1)
        }
        
        // 8. Morph Factor (Always Circle for Face ID)
        animationParams.morphFactor = 1.0
        
        updateActivity()
    }
    
    // MARK: - LLM Animation Control
    
    // MARK: - LLM Animation Control
    
    // Removed the first applyLLMAnimation definition as per instructions
    
    // Retained second applyLLMAnimation definition
    func applyLLMAnimation(_ update: AnimationUpdate) {
        print("PersonalityEngine: Applying LLM animation - Emotion: \(update.emotion)")
        
        // Map Emotion Tag to PAD Target
        switch update.emotion {
        case "HAPPY": targetPAD = .happy
        case "SAD": targetPAD = .sad
        case "ANGRY": targetPAD = .angry
        case "SURPRISED": targetPAD = .surprised
        case "EXCITED": targetPAD = .excited
        case "CALM": targetPAD = .relaxed
        case "NEUTRAL": targetPAD = .neutral
        default: targetPAD = .neutral
        }
        
        // Trigger Haptic for Mood Change
        HapticsManager.shared.playMoodHaptic(pad: targetPAD)
        
        // Handle Movement Types
        switch update.movement {
        case .bounce:
            animationParams.headTilt = 0.3 
        case .shake:
            animationParams.headTilt = -0.3
        case .energetic:
            targetPAD.arousal = 1.0
        case .calm:
            targetPAD.arousal = -0.5
        case .idle:
            break
        }
    }

    func setEmotionOverride(tag: String) {
        var pulse = EmotionPulse()
        switch tag {
        case "HAPPY":
            pulse.valence = 0.8
            pulse.arousal = 0.5
        case "SAD":
            pulse.valence = -0.6
            pulse.arousal = -0.2
        case "SURPRISED":
            pulse.valence = 0.2
            pulse.arousal = 0.8
        case "NEUTRAL":
            pulse.valence = 0.0
            pulse.arousal = 0.0
        default:
            return
        }
        
        self.emotionOverride = pulse
        
        // Reset after 3 seconds
        overrideTimer?.invalidate()
        overrideTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            self?.emotionOverride = nil
        }
    }
    
    func lerp(_ a: CGFloat, _ b: CGFloat, _ t: CGFloat) -> CGFloat {
        return a + (b - a) * t
    }
    
    // MARK: - Live Activity Management
    
    private var activity: Activity<AvatarAttributes>?
    private var lastActivityUpdate: Date = Date()
    
    func startActivity() {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        
        let attributes = AvatarAttributes(companionName: companionName)
        let contentState = AvatarAttributes.ContentState(
            eyeOpen: animationParams.eyeOpen,
            mouthOpen: animationParams.mouthOpen,
            smile: animationParams.mouthSmile,
            browRaise: animationParams.browRaise,
            headTilt: animationParams.headTilt,
            glow: animationParams.glow,
            hue: 0.55 // Approximate
        )
        
        do {
            activity = try Activity.request(attributes: attributes, contentState: contentState, pushType: nil)
        } catch {
            print("Error starting activity: \(error)")
        }
    }
    
    func updateActivity() {
        guard let activity = activity else { return }
        
        // Throttle updates to avoid system limits (e.g. max 1 per second usually, but we'll try 0.5s)
        guard Date().timeIntervalSince(lastActivityUpdate) > 0.5 else { return }
        lastActivityUpdate = Date()
        
        let contentState = AvatarAttributes.ContentState(
            eyeOpen: animationParams.eyeOpen,
            mouthOpen: animationParams.mouthOpen,
            smile: animationParams.mouthSmile,
            browRaise: animationParams.browRaise,
            headTilt: animationParams.headTilt,
            glow: animationParams.glow,
            hue: 0.55 // We could calculate this from colorTint if we had the logic here
        )
        
        Task {
            await activity.update(using: contentState)
        }
    }
    
    func endActivity() {
        Task {
            await activity?.end(dismissalPolicy: .immediate)
            activity = nil
        }
    }
    
    // MARK: - Tag MappingProcessing
    lazy var chatService: ChatService = {
        ChatService(companionName: companionName)
    }()
    
    func process(text: String) {
        Task {
            // PRIVACY-FIRST: Raw text stays on device
            // Only metadata sent to OpenAI for tuning
            let (response, emotionTag) = await PrivacyOrchestrator.shared.processLocally(
                text: text,
                emotion: currentPAD,
                history: chatService.chatHistory
            )
            
            DispatchQueue.main.async {
                // 1. Set Emotion
                if let tag = emotionTag {
                    self.setEmotionOverride(tag: tag)
                }
                
                // 2. Update Response (which triggers Speech in ContentView)
                self.response = response
                self.resetIdleTimer() // Reset timer on AI response
            }
        }
    }
    
    @Published var response: String = "" // To trigger UI updates

}
