import Foundation
import SwiftUI
import ActivityKit

    @Published var personality: Personality {
        didSet { PersistenceManager.shared.savePersonality(personality) }
    }
    @Published var mood: CompanionMood = CompanionMood() {
        didSet { PersistenceManager.shared.saveMood(mood) }
    }
    @Published var currentPulse: EmotionPulse = EmotionPulse()
    
    // Output for the renderer
    @Published var animationParams: AnimationParams = AnimationParams()
    @Published var exaggeratedExpressions: Bool = false // New Toggle
    
    private var timer: Timer?
    
    init() {
        self.personality = PersistenceManager.shared.loadPersonality()
        self.mood = PersistenceManager.shared.loadMood()
        startLoop()
    }
    
    func updateEmotion(pulse: EmotionPulse) {
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
        
        updateAnimationParams()
    }
    
    private func startLoop() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            self?.updateAnimationParams()
            
            // Random Heartbeat if Trust is high
            if let mood = self?.mood, mood.trust > 0.8 && Double.random(in: 0...1) < 0.01 {
                HapticsManager.shared.playHeartbeat()
            }
        }
    }
    
    // Speaking State
    var isSpeaking: Bool = false
    var audioLevel: Float = 0.0
    
    // Emotion Override (from Chat)
    var emotionOverride: EmotionPulse?
    var overrideTimer: Timer?

        // 5. Aura/Glow
        let targetGlow = personality.confidence * (0.3 + activePulse.arousal)
        
        // 6. Color Calculation
        let baseHue: CGFloat = 0.55 + mood.mood * 0.1
        let arousalShift = activePulse.arousal * 0.2
        let finalHue = baseHue + arousalShift
        let targetColor = Color(hue: finalHue, saturation: 0.8, brightness: 1.0)
        
        // Smoothly interpolate
        let smoothFactor: CGFloat = 0.1
        
        animationParams.headTilt = lerp(animationParams.headTilt, targetHeadTilt, smoothFactor)
        animationParams.mouthSmile = lerp(animationParams.mouthSmile, targetSmile, smoothFactor)
        animationParams.glow = lerp(animationParams.glow, targetGlow + breathing, smoothFactor)
        animationParams.colorTint = targetColor
        
        // 7. Mouth Open (Speaking Override)
        if isSpeaking {
            // Map audio level (0..1) to mouth open (0..1)
            // Simple mapping
            let targetMouthOpen = CGFloat(audioLevel) * 0.8
            // Faster interpolation for lip sync
            animationParams.mouthOpen = lerp(animationParams.mouthOpen, targetMouthOpen, 0.3)
        } else {
            // Default to vision or closed
            // If vision engine says mouth open, we use it, otherwise 0
            // For now, let's assume vision engine drives it if not speaking
            // But we don't have direct access to vision params here unless we passed them.
            // Let's assume currentPulse doesn't carry mouthOpen (it carries valence/arousal).
            // We need to decide if we want vision-mouth-open to pass through.
            // For this implementation, let's just close it if not speaking, or keep it slight if breathing?
            animationParams.mouthOpen = lerp(animationParams.mouthOpen, 0.0, 0.1)
        }
        
        updateActivity()
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
            browRaise: animationParams.browRaise,
            smile: animationParams.mouthSmile,
            mouthOpen: animationParams.mouthOpen,
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
            browRaise: animationParams.browRaise,
            smile: animationParams.mouthSmile,
            mouthOpen: animationParams.mouthOpen,
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
}
