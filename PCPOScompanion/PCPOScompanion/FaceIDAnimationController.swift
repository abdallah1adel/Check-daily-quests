import SwiftUI
import Combine

// MARK: - Face ID Animation Controller
/// Orchestrates all Face ID animations, rigging, and Disney principles

@MainActor
class FaceIDAnimationController: ObservableObject {
    @Published var rig: FaceIDRig
    @Published var isAnimating: Bool = false
    @Published var currentAnimation: AnimationType = .idle
    
    // Animation state
    private var animationTimer: Timer?
    private var lastUpdateTime: Date = Date()
    
    // Input sources
    private var personalityEngine: PersonalityEngine?
    private var speechManager: SpeechManager?
    private var emotionPulse: EmotionPulse = EmotionPulse()
    
    // Cancellables
    private var cancellables = Set<AnyCancellable>()
    
    enum AnimationType {
        case idle
        case speaking
        case listening
        case thinking
        case happy
        case sad
        case surprised
        case angry
        case lockToLife // The Face ID unlock sequence
    }
    
    init() {
        self.rig = FaceIDRig()
        startAnimationLoop()
    }
    
    // MARK: - Setup
    
    func connect(personalityEngine: PersonalityEngine, speechManager: SpeechManager) {
        self.personalityEngine = personalityEngine
        self.speechManager = speechManager
        
        // Subscribe to personality updates
        personalityEngine.$currentPAD
            .sink { [weak self] pad in
                self?.updateFromPAD(pad)
            }
            .store(in: &cancellables)
        
        personalityEngine.$isSpeaking
            .sink { [weak self] speaking in
                self?.handleSpeaking(speaking)
            }
            .store(in: &cancellables)
        
        personalityEngine.$audioLevel
            .sink { [weak self] level in
                self?.updateLipSync(audioLevel: level)
            }
            .store(in: &cancellables)
        
        // Subscribe to speech manager
        speechManager.$isSpeaking
            .sink { [weak self] speaking in
                self?.handleSpeaking(speaking)
            }
            .store(in: &cancellables)
        
        speechManager.$audioLevel
            .sink { [weak self] level in
                self?.updateLipSync(audioLevel: level)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Animation Loop
    
    private func startAnimationLoop() {
        animationTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            let now = Date()
            let deltaTime = now.timeIntervalSince(self.lastUpdateTime)
            self.lastUpdateTime = now
            
            self.rig.update(deltaTime: deltaTime)
        }
    }
    
    // MARK: - Emotion Mapping
    
    private func updateFromPAD(_ pad: PADEmotion) {
        // Map PAD to animation layers (using pleasure/valence, arousal, dominance)
        let valence = pad.pleasure // Alias for compatibility
        let emotionPose = FaceIDRig.FacePose(
            headRotation: .degrees(Double(valence) * 10), // Happy = slight tilt up
            headTilt: .degrees(Double(pad.arousal) * 5), // Excited = more tilt
            eyeOpenness: 0.7 + CGFloat(pad.arousal) * 0.3, // Excited = wider eyes
            eyeSquint: CGFloat(max(0, -valence) * 0.5), // Sad = squint
            mouthSmile: CGFloat((valence + 1) / 2), // -1 to 1 -> 0 to 1
            mouthOpen: 0.0,
            browRaise: CGFloat(pad.arousal) * 0.5
        )
        
        rig.emotionLayer = emotionPose
        
        // Update blend shapes
        if valence > 0.5 {
            rig.setBlendShape(.happy, value: CGFloat(valence))
            currentAnimation = .happy
        } else if valence < -0.5 {
            rig.setBlendShape(.sad, value: CGFloat(-valence))
            currentAnimation = .sad
        } else if pad.arousal > 0.7 {
            rig.setBlendShape(.surprised, value: CGFloat(pad.arousal))
            currentAnimation = .surprised
        } else {
            rig.setBlendShape(.neutral, value: 1.0)
            currentAnimation = .idle
        }
    }
    
    // MARK: - Lip Sync
    
    private func updateLipSync(audioLevel: Float) {
        let level = CGFloat(audioLevel)
        
        // Map audio level to mouth openness
        let mouthOpen = min(1.0, level * 2.0)
        
        rig.lipSyncLayer = FaceIDRig.FacePose(
            headRotation: .zero,
            headTilt: .zero,
            eyeOpenness: 1.0,
            eyeSquint: 0.0,
            mouthSmile: 0.5, // Slight smile when speaking
            mouthOpen: mouthOpen,
            browRaise: 0.0
        )
        
        // Apply squash & stretch to mouth based on audio
        if var mouth = rig.bones["mouth"] {
            mouth.stretchAmount = mouthOpen * 0.3
            mouth.squashAmount = (1.0 - mouthOpen) * 0.2
            rig.bones["mouth"] = mouth
        }
    }
    
    // MARK: - Speaking Animation
    
    private func handleSpeaking(_ speaking: Bool) {
        if speaking {
            startSpeakingAnimation()
        } else {
            stopSpeakingAnimation()
        }
    }
    
    private func startSpeakingAnimation() {
        currentAnimation = .speaking
        
        // Eyes widen slightly when speaking
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            rig.setBlendShape(.eyeWide, value: 0.3)
        }
        
        // Subtle head nod
        rig.applyAnticipation(direction: .down, amount: 0.1)
        
        // Continuous subtle movement
        startIdleMicroAnimations()
    }
    
    private func stopSpeakingAnimation() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            rig.setBlendShape(.eyeWide, value: 0.0)
        }
        
        // Return to neutral
        rig.lipSyncLayer = .neutral
    }
    
    // MARK: - Lock to Life Animation
    
    func playLockToLifeSequence() {
        currentAnimation = .lockToLife
        isAnimating = true
        
        // Sequence: Locked -> Scanning -> Unlocked
        
        // 1. Start locked (padlock icon)
        rig.baseLayer = FaceIDRig.FacePose(
            headRotation: .zero,
            headTilt: .zero,
            eyeOpenness: 0.0, // Closed
            eyeSquint: 0.0,
            mouthSmile: 0.0,
            mouthOpen: 0.0,
            browRaise: 0.0
        )
        
        // 2. Transition to scanning (after 0.5s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }
            
            withAnimation(.easeInOut(duration: 0.3)) {
                // Scanning orb animation
                self.rig.setBlendShape(.eyeWide, value: 0.5)
                
                // Rotate brackets
                if var head = self.rig.bones["head"] {
                    head.rotation = .degrees(360)
                    self.rig.bones["head"] = head
                }
            }
        }
        
        // 3. Unlock to face (after 1.5s total)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            guard let self = self else { return }
            
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                // Spring into face
                self.rig.baseLayer = FaceIDRig.FacePose(
                    headRotation: .zero,
                    headTilt: .zero,
                    eyeOpenness: 1.0, // Open
                    eyeSquint: 0.0,
                    mouthSmile: 0.3, // Slight smile
                    mouthOpen: 0.0,
                    browRaise: 0.2
                )
                
                // Apply anticipation and follow-through
                self.rig.applyAnticipation(direction: .up, amount: 0.2)
                
                // Overshoot then settle
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.rig.applyFollowThrough(boneID: "head", velocity: CGPoint(x: 0, y: -5), damping: 0.9)
                }
            }
            
            self.isAnimating = false
            self.currentAnimation = .idle
        }
    }
    
    // MARK: - Idle Animations
    
    private func startIdleMicroAnimations() {
        // Subtle breathing
        Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] timer in
            guard let self = self, self.currentAnimation == .idle || self.currentAnimation == .speaking else {
                timer.invalidate()
                return
            }
            
            // Subtle scale pulse (breathing)
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                if var head = self.rig.bones["head"] {
                    head.scale = CGSize(width: 1.02, height: 1.02)
                    self.rig.bones["head"] = head
                }
            }
        }
        
        // Random eye movements (saccades)
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] timer in
            guard let self = self, self.currentAnimation == .idle else {
                timer.invalidate()
                return
            }
            
            let randomTarget = CGPoint(
                x: CGFloat.random(in: -20...20),
                y: CGFloat.random(in: -10...10)
            )
            
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                self.rig.gazeTarget = randomTarget
            }
        }
    }
    
    // MARK: - Gesture Animations
    
    func playGesture(_ gesture: Gesture) {
        switch gesture {
        case .nod:
            // Nod animation
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                rig.gestureLayer = FaceIDRig.FacePose(
                    headRotation: .zero,
                    headTilt: .degrees(15),
                    eyeOpenness: 1.0,
                    eyeSquint: 0.0,
                    mouthSmile: 0.5,
                    mouthOpen: 0.0,
                    browRaise: 0.0
                )
            }
            
            // Return to neutral
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    self.rig.gestureLayer = .neutral
                }
            }
            
        case .shake:
            // Shake head animation
            withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
                rig.gestureLayer = FaceIDRig.FacePose(
                    headRotation: .degrees(-20),
                    headTilt: .zero,
                    eyeOpenness: 0.8,
                    eyeSquint: 0.3,
                    mouthSmile: -0.3,
                    mouthOpen: 0.0,
                    browRaise: 0.0
                )
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
                    self.rig.gestureLayer = FaceIDRig.FacePose(
                        headRotation: .degrees(20),
                        headTilt: .zero,
                        eyeOpenness: 0.8,
                        eyeSquint: 0.3,
                        mouthSmile: -0.3,
                        mouthOpen: 0.0,
                        browRaise: 0.0
                    )
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    self.rig.gestureLayer = .neutral
                }
            }
            
        case .winkLeft, .winkRight:
            // Wink animation
            let eyeID = gesture == .winkLeft ? "leftEye" : "rightEye"
            
            withAnimation(.easeOut(duration: 0.1)) {
                if var eye = rig.bones[eyeID] {
                    eye.scale.height = 0.1
                    rig.bones[eyeID] = eye
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.easeIn(duration: 0.1)) {
                    if var eye = self.rig.bones[eyeID] {
                        eye.scale.height = 1.0
                        self.rig.bones[eyeID] = eye
                    }
                }
            }
            
        default:
            break
        }
    }
    
    // MARK: - Expression Overrides
    
    func playExpression(_ expression: ExpressionType, intensity: CGFloat = 1.0) {
        switch expression {
        case .happy:
            rig.setBlendShape(.happy, value: intensity)
            rig.emotionLayer = FaceIDRig.FacePose(
                headRotation: .degrees(5),
                headTilt: .zero,
                eyeOpenness: 1.0,
                eyeSquint: 0.0,
                mouthSmile: intensity,
                mouthOpen: 0.0,
                browRaise: 0.0
            )
            
        case .sad:
            rig.setBlendShape(.sad, value: intensity)
            rig.emotionLayer = FaceIDRig.FacePose(
                headRotation: .degrees(-5),
                headTilt: .degrees(-10),
                eyeOpenness: 0.7,
                eyeSquint: intensity * 0.5,
                mouthSmile: -intensity,
                mouthOpen: 0.0,
                browRaise: 0.0
            )
            
        case .surprised:
            rig.setBlendShape(.surprised, value: intensity)
            rig.emotionLayer = FaceIDRig.FacePose(
                headRotation: .zero,
                headTilt: .zero,
                eyeOpenness: 1.0,
                eyeSquint: 0.0,
                mouthSmile: 0.0,
                mouthOpen: intensity * 0.8,
                browRaise: intensity
            )
            
            // Apply pop animation
            rig.applyExaggeration(factor: intensity)
            
        case .angry:
            rig.setBlendShape(.angry, value: intensity)
            rig.emotionLayer = FaceIDRig.FacePose(
                headRotation: .zero,
                headTilt: .zero,
                eyeOpenness: 0.6,
                eyeSquint: intensity,
                mouthSmile: -intensity * 0.5,
                mouthOpen: 0.0,
                browRaise: 0.0
            )
        }
    }
    
    enum ExpressionType {
        case happy, sad, surprised, angry
    }
    
    // MARK: - Cleanup
    
    deinit {
        animationTimer?.invalidate()
        cancellables.removeAll()
    }
}

