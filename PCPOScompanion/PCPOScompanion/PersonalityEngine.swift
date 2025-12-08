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
    
    // NEW: Phase 2 - 374 Mood System
    @Published var currentMoodState: MoodState = MoodState() {
        didSet { updateAnimationFromMood() }
    }
    private var targetMoodState: MoodState = MoodState()
    private var moodTransitionProgress: Float = 0.0
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
    
    var targetPAD: PADEmotion = .neutral // Target for interpolation
    
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
    
    
    // MARK: - Mood Transition System (Phase 2)
    
    func setMood(_ newMood: MoodState, duration: TimeInterval = 2.0) {
        targetMoodState = newMood
        moodTransitionProgress = 0.0
        
        // Smooth transition over duration
        let steps = Int(duration / 0.016) // 60fps
        var currentStep = 0
        
        Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            currentStep += 1
            self.moodTransitionProgress = Float(currentStep) / Float(steps)
            
            if self.moodTransitionProgress >= 1.0 {
                self.currentMoodState = newMood
                timer.invalidate()
            } else {
                // Interpolate
                self.currentMoodState = MoodState.transition(
                    from: self.currentMoodState,
                    to: self.targetMoodState,
                    progress: self.moodTransitionProgress
                )
            }
        }
    }
    
    private func updateAnimationFromMood() {
        // Map MoodState to animation parameters
        let energyMultiplier = Float(currentMoodState.energy.rawValue) / 8.0 // 0.0 to 2.0
        
        // Update animation speed based on energy
        animationParams.speed = CGFloat(0.5 + (energyMultiplier * 0.5))
        
        // Update color based on emotion
        animationParams.primaryColor = colorForEmotion(currentMoodState.primary)
        
        // Update expression intensity
        animationParams.expressionIntensity = energyMultiplier
    }
    
    private func colorForEmotion(_ emotion: PrimaryEmotion) -> Color {
        switch emotion {
        case .joy, .excitement, .gratitude: return .yellow
        case .love, .contentment: return .pink
        case .curiosity, .interest, .anticipation: return .cyan
        case .pride, .hope: return .green
        case .surprise: return .orange
        case .sadness, .disappointment, .loneliness: return .blue
        case .grief: return Color(red: 0.3, green: 0.3, blue: 0.5)
        case .anger, .frustration, .irritation: return .red
        case .disgust, .contempt: return Color(red: 0.5, green: 0.3, blue: 0.0)
        case .fear, .anxiety: return .purple
        case .guilt: return Color(red: 0.4, green: 0.4, blue: 0.4)
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
            PCPOSHaptics.shared.playEmotionHaptic(valence: pulse.valence, arousal: pulse.arousal)
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
            PCPOSHaptics.shared.playSuccess()
            // Could trigger a "Yes!" speech if we wanted
        case .shake:
            // User shook head -> Avatar looks concerned / Disagrees
            setEmotionOverride(tag: "SAD") // Or concerned
            PCPOSHaptics.shared.playError()
        case .winkLeft, .winkRight:
            // User winked -> Avatar smirks / Winks back
            // We don't have a wink animation yet, but we can smirk strongly
            setEmotionOverride(tag: "HAPPY")
            // Force a smirk in next update
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.animationParams.smirk = 0.8
            }
            PCPOSHaptics.shared.playEnergetic()
        default:
            break
        }
    }
    
    private func startLoop() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            self?.updateAnimationParams()
            
            // Random Heartbeat if Trust is high
            if let mood = self?.mood, mood.trust > 0.8 && Double.random(in: 0...1) < 0.01 {
                PCPOSHaptics.shared.playHeartbeat()
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
    @Published var isSpeaking: Bool = false
    @Published var audioLevel: Float = 0.0
    
    // Emotion Override (from Chat)
    var emotionOverride: EmotionPulse?
    var overrideTimer: Timer?

    // Reference to the Face Model (The Visual Truth)
    var faceModel: PCPOSFaceModel?
    
    private func updateAnimationParams() {
        // 1. Interpolate PAD State
        let interpolationSpeed: Float = 0.05 // Smooth transition
        currentPAD = EmotionMapper.interpolate(from: currentPAD, to: targetPAD, progress: interpolationSpeed)
        
        // 2. Map PAD to Base Animation Params
        let padParams = EmotionMapper.map(currentPAD)
        
        // 3. Update PCPOSFaceModel (The New Way)
        if let faceModel = faceModel {
            DispatchQueue.main.async {
                // Mood Color
                faceModel.updateMoodColor(valence: Double(self.currentPAD.valence), arousal: Double(self.currentPAD.arousal))
                
                // Smile & Mouth
                faceModel.updateSmile(padParams.mouthSmile)
                
                // Eyes
                if !self.isBlinking {
                    faceModel.updateEyeOpenness(padParams.eyeOpen)
                }
                
                // Head Rotation (Base pose from emotion)
                // We add some noise/breathing to rotation
                let time = Date().timeIntervalSince1970
                let breathe = CGFloat(sin(time * 1.5)) * 2.0
                faceModel.updateHeadRotation(
                    pitch: padParams.headTilt * 10 + breathe,
                    yaw: 0, // Yaw controlled by gaze/tracking usually
                    roll: padParams.headTilt * 5
                )
                
                // Lip Sync Override
                if self.isSpeaking {
                    let targetMouthOpen = CGFloat(self.audioLevel) * 0.8
                    faceModel.updateMouthOpenness(targetMouthOpen)
                } else {
                    faceModel.updateMouthOpenness(0)
                }
            }
        }
        
        // ... (Legacy params update for backward compatibility if needed)
        
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
        PCPOSHaptics.shared.playMoodHaptic(pad: targetPAD)
        
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
    
    // MARK: - Live Activity Management (DISABLED - Handled by LiveActivityManager)
    
    private var activity: Activity<AvatarAttributes>?
    private var lastActivityUpdate: Date = Date()
    
    func startActivity() {
        // Disabled to avoid conflict with PCPOSLiveActivity (House)
        // LiveActivityManager.shared.startActivity(...)
    }
    
    func updateActivity() {
        // Disabled
    }
    
    func endActivity() {
        // Disabled
    }
    
    // MARK: - Emotion Sync
    
    func updateEmotion(from state: EmotionState) {
        setEmotionOverride(tag: state.rawValue)
        
        // Also update PAD state directly based on EmotionState
        switch state {
        case .happy: targetPAD = .happy
        case .sad: targetPAD = .sad
        case .angry: targetPAD = .angry
        case .excited: targetPAD = .excited
        case .calm: targetPAD = .relaxed
        case .surprised: targetPAD = .surprised
        case .heroic: targetPAD = .heroic
        case .curious: targetPAD = .curious // Map to interest/curiosity
        case .love: targetPAD = .happy // Saturated happy
        default: targetPAD = .neutral
        }
    }
    
    // MARK: - Tag MappingProcessing
    lazy var chatService: ChatService = {
        ChatService(companionName: companionName)
    }()
    
    func process(text: String) {
        Task {
            // DIRECT LLM CALL (temporary fix to ensure speech works)
            // TODO: Re-enable PrivacyOrchestrator once speech is confirmed working
            let (response, emotionTag) = await chatService.sendMessage(text)
            
            DispatchQueue.main.async {
                // 1. Set Emotion
                if let tag = emotionTag {
                    self.setEmotionOverride(tag: tag)
                }
                
                // 2. Update Response (which triggers Speech in ContentView)
                self.response = response
                // Speech is already triggered by chatService.onQuickResponse
                self.resetIdleTimer() // Reset timer on AI response
            }
        }
    }
    
    @Published var response: String = "" // To trigger UI updates

}
