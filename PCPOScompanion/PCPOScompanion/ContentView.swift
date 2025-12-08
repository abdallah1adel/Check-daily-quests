import SwiftUI
import Combine
import PhotosUI
import CoreMedia

struct ContentView: View {
    @StateObject private var camera = CameraManager()
    @StateObject private var visionEngine = VisionEmotionEngine()
    @StateObject private var coreMLEngine = CoreMLEmotionEngine() // NEW
    @StateObject private var personalityEngine = PersonalityEngine()
    @StateObject private var speechManager = SpeechManager()
    @StateObject private var riggingManager = RiggingManager()
    @ObservedObject private var storeManager = StoreManager.shared
    @StateObject private var movementEngine = AvatarMovementEngine()
    @StateObject private var faceModel = PCPOSFaceModel() // NEW: The Face Model
    @StateObject private var voiceProfileManager = VoiceProfileManager() // NEW: Voice Fingerprinting
    @StateObject private var protocol22 = Protocol22Integration() // NEW: Protocol 22 Creator Recognition
    @StateObject private var visionFaceDetector = VisionFaceDetector() // NEW: Vision Framework
    @StateObject private var godBrain = GodBrain.shared // NEW: The Central Nervous System
    @ObservedObject private var debugger = AppDebugger.shared // Debug & Performance Monitor
    
    // ... (Rest of properties)
    @State private var cancellables = Set<AnyCancellable>()
    @State private var chatLog: String = ""
    
    @State private var showRiggingSheet = false
    @State private var showSettingsSheet = false
    @State private var showPaywallSheet = false
    @State private var showWalletSheet = false
    @State private var showDiagnostics = false // SECRET: Triggers Protocol 22
    @State private var showDebugView = false // Debug console
    @State private var breathingScale: CGFloat = 1.0
    
    // Launch Animation State
    @AppStorage("isOnboardingComplete") private var isOnboardingComplete = false
    @AppStorage("avatar_mode") private var avatarMode = 1 // 0: Circle, 1: PCPOS, 2: FaceID, 3: Custom
    
    @State private var isLaunching = true
    @State private var launchedFromSiri = false
    @State private var floatingOffset: CGFloat = 0
    @State private var showImagePicker = false
    
    // Expandable View State
    enum ExpandableViewState {
        case collapsed  // In Dynamic Island
        case normal     // Center of screen
        case expanded   // Half screen with search results
        case searchOverlay // NEW: Half-screen search results (over content)
    }

    // Face ID Lock to Life Animation States
    enum FaceIDState {
        case locked      // Apple Padlock icon
        case scanning    // Scanning orb animation
        case unlocked    // PCPOS Face ID avatar
    }
    
    @State private var viewState: ExpandableViewState = .normal
    @State private var faceIDState: FaceIDState = .locked
    @State private var faceIDResetTimer: Timer?
    @State private var showSearchResults = false
    @State private var searchQuery = ""
    @State private var searchAnswer = ""
    @State private var searchSources: [String] = []
    
    // Camera Streaming State
    @State private var isStreamingCamera = false
    
    // Dynamic Island Border Glow
    @State private var isBorderGlowing = false
    @State private var borderGlowOpacity: Double = 0.0
    
    // Speech Bubble State
    @State private var showSpeechBubble = false
    @State private var speechBubbleText = ""
    @State private var isUserSpeech = false
    
    var body: some View {
        ZStack {
            if !isOnboardingComplete {
                OnboardingView(isCompleted: $isOnboardingComplete, personalityEngine: personalityEngine, riggingManager: riggingManager)
                    .zIndex(1)
            } else {
                    mainInterface
                        .zIndex(0)
                        .onTapGesture(count: 5) {
                            // SECRET TRIGGER: 5 Taps launches Protocol 22
                            showDiagnostics = true
                        }
                        .onLongPressGesture(minimumDuration: 3.0) {
                            // SECRET DEBUG: Long press (3s) opens debug console
                            showDebugView = true
                        }
            }
        }
        .onChange(of: isStreamingCamera) { newValue in
            #if os(iOS)
            if newValue {
                CameraStreamer.shared.startStreaming(from: camera)
            } else {
                CameraStreamer.shared.stopStreaming()
            }
            #endif
        }
        .onChange(of: godBrain.isCreatorPresent) { isCreator in
            if isCreator {
                // Trigger Protocol 22 if Creator is detected by the God Brain
                debugger.log("🧠 God Brain: Protocol 22 ACTIVATED", severity: .success)
                // We can auto-trigger diagnostics or unlock features
                withAnimation {
                    faceModel.profile.appearance.colors.primary = "#00FF00" // Green for Creator
                }
            }
        }
        .onAppear {
            // Wire PersonalityEngine to FaceModel
            personalityEngine.faceModel = faceModel
            
            if chatLog.isEmpty {
                chatLog = "\(personalityEngine.companionName): Hello Sir ! how was your day?"
            }
            setupPipeline()
            setupChatServiceCallbacks()
            setupProtocol22()
            
            // 🧠 CONNECT THE GOD BRAIN
            godBrain.connectSenses(vision: visionFaceDetector, hearing: voiceProfileManager)
            Task {
                await godBrain.loadCortex()
            }
            
            // Start Voice Listening
            voiceProfileManager.startListening()
            
            // Start Live Activity (PCPOS House)
            if #available(iOS 16.1, *) {
                LiveActivityManager.shared.startActivity(companionName: "PCPOS", color: "#00FFFF")
            }
        }
        .onChange(of: godBrain.currentThought) { thought in
            // Log God Brain thoughts to the debugger
            debugger.log("🧠 Thought: \(thought)", severity: .info)
        }
    }
    
    // MARK: - Chat Service Callbacks
    
    private func setupChatServiceCallbacks() {
        // Wire up dual-layer LLM callbacks
        personalityEngine.chatService.onAnimationUpdate = { [weak personalityEngine] update in
            personalityEngine?.applyLLMAnimation(update)
        }
        
        personalityEngine.chatService.onQuickResponse = { [weak speechManager] response in
            speechManager?.speak(response)
        }
        
        personalityEngine.chatService.onSearchIntent = {
            // Trigger search overlay
            DispatchQueue.main.async {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    self.viewState = .searchOverlay
                    self.showSearchResults = true
                }
            }
        }
    }
    
    // MARK: - UI Components

    private var backgroundBreathingEffect: some View {
            Circle()
                .fill(personalityEngine.animationParams.colorTint.opacity(0.1))
                .scaleEffect(breathingScale)
                .animation(Animation.easeInOut(duration: 4).repeatForever(autoreverses: true), value: breathingScale)
                .onAppear { breathingScale = 1.2 }
    }
            
    private var topButtonBar: some View {
                HStack {
                    // Settings Button (Left)
                    Button(action: { showSettingsSheet = true }) {
                        Image(systemName: "gearshape.fill")
                            .font(.title)
                            .foregroundColor(.gray.opacity(0.5))
                    }
                    .padding()
                    
                    // Protocol 22 is HIDDEN - no UI elements visible

            // Wallet Button (Center)
            Button(action: { showWalletSheet = true }) {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 40, height: 40)

                    Image(systemName: "wallet.pass.fill")
                        .foregroundColor(.blue)
                        .font(.system(size: 16))
                }
            }
            .padding(.horizontal, 8)
                    
                    Spacer()
                    
            // SHOP BUTTON (Right)
                    Button(action: { showPaywallSheet = true }) {
                        HStack(spacing: 5) {
                            Image(systemName: "cart.fill")
                            Text("PRO")
                                .fontWeight(.bold)
                        }
                        .font(.caption)
                        .padding(8)
                        .background(Color.yellow)
                        .foregroundColor(.black)
                        .clipShape(UnevenRoundedRectangle(cornerRadii: RectangleCornerRadii(topLeading: 20, bottomLeading: 20, bottomTrailing: 20, topTrailing: 20)))
                        .shadow(radius: 5)
                    }
                    
                    Spacer()
                    
                    // Rigging Button (Right) - Only show if Custom Mode
            if avatarMode == 3 {
                        Button(action: { showRiggingSheet = true }) {
                            Image(systemName: "pencil.circle.fill")
                                .font(.title)
                                .foregroundColor(.gray.opacity(0.5))
                        }
                        .padding()
            }
                    }
                }
                
    private var avatarDisplay: some View {
        Group {
        Group {
            // Unified Face View (PCPOS Model is the Truth)
            PCPOSFaceView(model: faceModel)
                .frame(width: 150, height: 150)
                .overlay(
                    // Optional: Add Face ID brackets if we want to "merge" that style
                    Group {
                        if avatarMode == 2 { // Face ID Mode
                            FaceIDBrackets()
                                .stroke(Color.white.opacity(0.3), lineWidth: 2)
                        }
                    }
                )
        }
        }
    }
    
    // MARK: - Face View Selection
    @ViewBuilder
    private var faceView: some View {
        // Face ID Style PCPOS (The Correct One)
        RefinedPCPOSFaceIDView(faceModel: faceModel, speechManager: speechManager)
            .frame(width: 180, height: 180)
    }

    private var statusIndicator: some View {
        Text(storeManager.isProAccess ? "PRO" : "FREE")
            .font(.caption2)
            .fontWeight(.bold)
            .foregroundColor(storeManager.isProAccess ? .green : .orange)
            .padding(6)
            .background(Color.black.opacity(0.5))
            .clipShape(
                UnevenRoundedRectangle(
                    cornerRadii: RectangleCornerRadii(
                        topLeading: 10,
                        bottomLeading: 10,
                        bottomTrailing: 10,
                        topTrailing: 10
                    )
                )
            )
    }
                
    private var chatDisplay: some View {
                ScrollView {
                    Text(chatLog)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                }
                .frame(height: 100)
                .background(Color.black.opacity(0.3))
                .clipShape(UnevenRoundedRectangle(cornerRadii: RectangleCornerRadii(topLeading: 10, bottomLeading: 10, bottomTrailing: 10, topTrailing: 10)))
                .padding(.horizontal)
    }
                
    private var controlButtons: some View {
                HStack(spacing: 40) {
                    // Camera Toggle
                    // Camera Toggle (Control Center Style)
                    Button(action: {
                        if camera.isRunning {
                            camera.stop()
                            debugger.updateCameraStatus(false)
                            debugger.log("Camera stopped", severity: .info)
                        } else {
                            camera.start()
                            debugger.updateCameraStatus(true)
                            debugger.log("Camera started", severity: .info)
                        }
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: camera.isRunning ? "video.fill" : "video.slash.fill")
                                .font(.title2)
                            Text(camera.isRunning ? "On" : "Off")
                                .font(.caption2)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.white)
                        .frame(width: 70, height: 70)
                        .background(Material.regular)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
                    }
                    
                    // Talk Button (Ripple Effect)
                    Button(action: {
                        PCPOSHaptics.shared.playHeartbeat() // Feedback on tap
                        if speechManager.isListening {
                            speechManager.stopListening()
                            sendToChat(speechManager.recognizedText)
                    // Disney Principle: Follow-through - Gentle conclusion
                    if viewState == .collapsed && faceIDState == .unlocked {
                        scheduleFaceIDReset()
                    }
                        } else {
                            speechManager.startListening()
                    // Disney Principle: Cause & Effect - Action triggers reaction
                    if viewState == .collapsed && faceIDState == .locked {
                        startFaceIDScanning()
                    }
                        }
                    }) {
                        ZStack {
                            if speechManager.isListening {
                                Circle()
                                    .stroke(Color.red.opacity(0.5), lineWidth: 4)
                                    .scaleEffect(1.5)
                                    .opacity(0)
                                    .animation(Animation.easeOut(duration: 1).repeatForever(autoreverses: false), value: speechManager.isListening)
                            }
                            
                            Image(systemName: speechManager.isListening ? "mic.fill" : "mic.slash.fill")
                                .font(.largeTitle)
                                .foregroundColor(.white)
                                .padding(30)
                                .background(Circle().fill(speechManager.isListening ? Color.red : Color.blue))
                                .shadow(color: speechManager.isListening ? Color.red : Color.blue, radius: 10)
                        }
                    }
                }
                .padding(.bottom, 40)
            }
    
    // MARK: - Dynamic Island Container
    
    private var dynamicIslandContainer: some View {
        ZStack {
            if viewState == .collapsed {
                // Face ID "Lock to Life" Transformation
                faceIDCompactView
            } else {
                // Expanded state - show Face ID avatar
                VStack(spacing: 10) {
                    // Avatar at top
                    avatarDisplay
                        .frame(width: 100, height: 100)
                        .onAppear {
                            animateLaunch()
                        }
                        .onTapGesture {
                            playBotheredReaction()
                        }
                    
                    // Status
                    if viewState == .normal {
                        statusIndicator
                            .scaleEffect(0.8)
                        
                        // Mini chat display
                        Text(chatLog.components(separatedBy: "\n").suffix(2).joined(separator: "\n"))
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundColor(.gray)
                            .lineLimit(2)
                            .padding(.horizontal, 8)
                    }
                }
                .padding(.vertical, 10)
            }
        }
    }

    // MARK: - Face ID Lock to Life Animation (Disney Principles)
    private var faceIDCompactView: some View {
        // Always capsule-shaped container - the constant form
        Capsule()
            .fill(Color.white.opacity(0.1))
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            .frame(height: 36) // iOS Dynamic Island height
            .overlay(
                // PCPOS Face ID Content - The Perfect, Constant Face
                PCPOSFaceIDContent()
                    .frame(height: 32)
            )
            .contentShape(Capsule()) // Make entire capsule tappable
            .onTapGesture {
                if faceIDState == .locked {
                    startFaceIDScanning()
                }
            }
    }

    // MARK: - PCPOS Face ID Content (Disney Animation Principles)
    private struct PCPOSFaceIDContent: View {
        @StateObject private var personalityEngine = PersonalityEngine.shared
        @State private var faceIDState: ContentView.FaceIDState = .locked
        @State private var animationPhase: Double = 0
        @State private var eyeSquint: Double = 0
        @State private var mouthStretch: Double = 0
        @State private var headRotation: Angle = .zero
        @State private var bracketExpansion: Double = 0

        var body: some View {
            GeometryReader { geo in
                ZStack {
                    switch faceIDState {
                    case .locked:
                        // Apple-Style Padlock Icon (Perfect Authenticity)
                        HStack(spacing: 6) {
                            // Padlock body - perfectly proportioned
                            ZStack {
                                UnevenRoundedRectangle(cornerRadii: RectangleCornerRadii(topLeading: 3, bottomLeading: 3, bottomTrailing: 3, topTrailing: 3))
                                    .fill(Color.white.opacity(0.9))
                                    .frame(width: 12, height: 10)
                                Circle()
                                    .fill(Color.white.opacity(0.9))
                                    .frame(width: 8, height: 8)
                                    .offset(y: -2)
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 2, height: 2)
                                    .offset(y: -2)
                            }
                            .shadow(color: Color.black.opacity(0.2), radius: 1, x: 0, y: 1)

                            Text("Face ID")
                                .font(.system(size: 11, weight: .medium, design: .default))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .offset(y: 1) // Perfect vertical centering

                    case .scanning:
                        // Disney-Style Scanning Animation (Anticipation → Action → Follow-through)
                        ZStack {
                            // Bracket Animation (Expanding Brackets - Disney Squash & Stretch)
                            PCPOSFaceIDBrackets(expansion: bracketExpansion)
                                .frame(width: geo.size.width * 0.9, height: geo.size.height * 0.8)

                            // PCPOS Face Core (Constant Perfect Face)
                            PCPOSFaceIDCore(
                                eyeSquint: eyeSquint,
                                mouthStretch: mouthStretch,
                                headRotation: headRotation,
                                scale: 1.0 + sin(animationPhase * .pi * 2) * 0.05 // Subtle breathing
                            )
                            .frame(width: 24, height: 24)
                            .scaleEffect(0.8 + bracketExpansion * 0.2) // Grow with brackets
                        }
                        .onAppear {
                            startScanningAnimation()
                        }

                    case .unlocked:
                        // PCPOS Face ID Success (Disney Timing & Appeal)
                        PCPOSFaceIDCore(
                            eyeSquint: 0.3, // Happy squint
                            mouthStretch: 0.8, // Big smile
                            headRotation: .zero,
                            scale: 1.1 // Slightly larger for celebration
                        )
                        .frame(width: 28, height: 28)
                        .transition(.scale.combined(with: .opacity))
                        .onAppear {
                            // Success animation with haptic
#if os(iOS)
                            PCPOSHaptics.shared.playSuccess()
#endif

                            // Auto-transition to normal view
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                // This will be handled by parent view
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }

        private func startScanningAnimation() {
            // Disney Animation Principles Implementation
            withAnimation(.easeInOut(duration: 0.3)) {
                bracketExpansion = 0.2 // Anticipation
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                    bracketExpansion = 0.8 // Action - expand brackets
                    eyeSquint = 0.2 // Focus eyes
                }
            }

            // Continuous animation loop
            Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { timer in
                animationPhase += 0.1

                // Disney Secondary Action - subtle movements
                eyeSquint = 0.1 + sin(animationPhase) * 0.1
                mouthStretch = 0.2 + cos(animationPhase * 1.3) * 0.1
                headRotation = .degrees(sin(animationPhase * 0.7) * 2)

                if animationPhase > .pi * 4 { // Complete cycle
                    timer.invalidate()
                    // Transition to unlocked
                    DispatchQueue.main.async {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                            faceIDState = .unlocked
                        }
                    }
                }
            }
        }
    }

    // MARK: - PCPOS Face ID Core (The Perfect Constant Face)
    private struct PCPOSFaceIDCore: View {
        let eyeSquint: Double
        let mouthStretch: Double
        let headRotation: Angle
        let scale: Double

        var body: some View {
            ZStack {
                // PCPOS Body (Circular with subtle animation)
                PCPOSBody()
                    .fill(Color.blue.opacity(0.15))
                    .overlay(
                        PCPOSBody()
                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                    )
                    .scaleEffect(scale)
                    .rotationEffect(headRotation)

                // PCPOS Face Features (Disney Appeal - Exaggerated but Believable)
                ZStack {
                    // Left Eye (Disney Principle: Appeal through exaggeration)
                    PCPOSLeftEye()
                        .fill(Color.green.opacity(0.9))
                        .scaleEffect(1.0 + eyeSquint * 0.3) // Squint effect
                        .offset(x: -0.5, y: -eyeSquint) // Follow-through

                    // Right Eye
                    PCPOSRightEye()
                        .fill(Color.green.opacity(0.9))
                        .scaleEffect(1.0 + eyeSquint * 0.3)
                        .offset(x: 0.5, y: -eyeSquint)

                    // Mouth (Disney Timing - Delayed reaction)
                    PCPOSDisneyMouth()
                    .fill(Color.green.opacity(0.9))
                    .scaleEffect(1.0 + mouthStretch * 0.2) // Stretch effect
                }
                .scaleEffect(scale)
                .rotationEffect(headRotation * 0.5) // Secondary action
            }
            .frame(width: 24, height: 24)
        }
    }

    // MARK: - PCPOS Face ID Brackets (Disney Squash & Stretch)
    private struct PCPOSFaceIDBrackets: View {
        let expansion: Double

        var body: some View {
            GeometryReader { geo in
                let width = geo.size.width
                let height = geo.size.height

                Path { path in
                    let bracketWidth = width * (0.15 + expansion * 0.3) // Expand brackets
                    let bracketHeight = height * (0.2 + expansion * 0.4)

                    // Top-left bracket (Disney exaggeration)
                    path.move(to: CGPoint(x: 0, y: bracketHeight))
                    path.addLine(to: CGPoint(x: 0, y: 4))
                    path.addLine(to: CGPoint(x: bracketWidth, y: 4))

                    // Top-right bracket
                    path.move(to: CGPoint(x: width - bracketWidth, y: 4))
                    path.addLine(to: CGPoint(x: width, y: 4))
                    path.addLine(to: CGPoint(x: width, y: bracketHeight))

                    // Bottom-right bracket
                    path.move(to: CGPoint(x: width, y: height - bracketHeight))
                    path.addLine(to: CGPoint(x: width, y: height - 4))
                    path.addLine(to: CGPoint(x: width - bracketWidth, y: height - 4))

                    // Bottom-left bracket
                    path.move(to: CGPoint(x: bracketWidth, y: height - 4))
                    path.addLine(to: CGPoint(x: 0, y: height - 4))
                    path.addLine(to: CGPoint(x: 0, y: height - bracketHeight))
                }
                .stroke(Color.blue.opacity(0.6), lineWidth: 2)
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: expansion)
            }
        }
    }

    // MARK: - Face ID Disney Animation Helpers
    private func startFaceIDScanning() {
        // Cancel any existing reset timer
        faceIDResetTimer?.invalidate()
        faceIDResetTimer = nil

        // Disney Principle: Anticipation - Prepare for action
        withAnimation(.easeInOut(duration: 0.2)) {
            faceIDState = .scanning
        }

        // Disney Principle: Timing - Perfect pacing for drama
        // The PCPOSFaceIDContent handles its own animation timing with Disney principles
        // We just set the state and let the magic happen
    }

    private func sendToChat(_ message: String, isUser: Bool = true) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .short)
        let sender = isUser ? "USER" : "PCPOS"
        let logEntry = "[\(timestamp)] \(sender): \(message)"
        
        DispatchQueue.main.async {
            self.chatLog += "\n\(logEntry)"
            
            // Trigger Speech Bubble
            self.speechBubbleText = message
            self.isUserSpeech = isUser
            withAnimation {
                self.showSpeechBubble = true
            }
            
            // Trigger AI Processing if it's a user message
            if isUser {
                self.personalityEngine.process(text: message)
            }
        }
    }

    private func scheduleFaceIDReset() {
        faceIDResetTimer?.invalidate()
        faceIDResetTimer = Timer.scheduledTimer(withTimeInterval: 8.0, repeats: false) { _ in
            DispatchQueue.main.async {
                // Disney Principle: Slow in/out - Gentle return to rest
                withAnimation(.easeInOut(duration: 0.8)) {
                    self.faceIDState = .locked
                }
            }
        }
    }

    private func resetFaceIDState() {
        faceIDResetTimer?.invalidate()
        faceIDResetTimer = nil
        // Disney Principle: Appeal - Return gracefully
        withAnimation(.easeInOut(duration: 0.6)) {
            faceIDState = .locked
        }
    }

    // MARK: - Disney Animation Helper Functions (Legacy - kept for compatibility)
    private func scanningScale(for index: Int) -> CGFloat {
        // Disney Principle: Staging - Direct attention to the important action
        return 1.0 + CGFloat(index) * 0.2 // Expanding rings
    }

    private func scanningLineOpacity(for index: Int) -> Double {
        // Disney Principle: Appeal - Make it interesting to watch
        return 0.6 + Double(index) * 0.1 // Varying opacity for visual interest
    }

    var mainInterface: some View {
        ZStack(alignment: .top) {
            // Background - full screen
            Color.black
                .ignoresSafeArea(.all) // Ignore ALL safe areas
            backgroundBreathingEffect
            
            VStack(spacing: 0) {
                // TOP BUTTON BAR (Settings, Wallet, Shop)
                if viewState != .collapsed {
                    topButtonBar
                        .padding(.top, 60)
                        .transition(.opacity)
                }
                
                Spacer()
                
                // Dynamic Island Container - anchored at top, expands DOWN
                dynamicIslandContainer
                    .frame(
                        width: viewState == .collapsed ? dynamicIslandWidth : 
                               (viewState == .searchOverlay || viewState == .expanded) ? UIScreen.main.bounds.width : 
                               dynamicIslandWidth, // Vertical expansion only for .normal
                        height: viewState == .collapsed ? dynamicIslandHeight : 
                                (viewState == .searchOverlay || viewState == .expanded) ? UIScreen.main.bounds.height : 
                                240 // Square box height for .normal state
                    )
                    .background(
                        ZStack {
                            // Main Background
                            UnevenRoundedRectangle(cornerRadii: RectangleCornerRadii(topLeading: dynamicIslandRadius, bottomLeading: dynamicIslandRadius, bottomTrailing: dynamicIslandRadius, topTrailing: dynamicIslandRadius))
                                .fill(Color.black)
                                .shadow(color: personalityEngine.animationParams.colorTint.opacity(0.3), radius: 15)
                            
                            // Glowing Border (FaceID Style)
                            UnevenRoundedRectangle(cornerRadii: RectangleCornerRadii(topLeading: dynamicIslandRadius, bottomLeading: dynamicIslandRadius, bottomTrailing: dynamicIslandRadius, topTrailing: dynamicIslandRadius))
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.white.opacity(0.8),
                                            Color.cyan.opacity(0.8),
                                            Color.white.opacity(0.8)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                                .opacity(borderGlowOpacity)
                                
                            // Render the selected Face View
                            faceView
                                .scaleEffect(viewState == .collapsed ? 0.3 : 1.0)
                                .offset(y: viewState == .collapsed ? -10 : 0)
                        }
                    )
                    .padding(.top, viewState == .collapsed ? 11 : 0) // Dynamic Island top safe area
                
                Spacer() // Push everything else down
                
                // Speech Bubble (Liquid Glass Capsule)
                if viewState != .collapsed {
                    SpeechBubbleView(
                        text: speechBubbleText,
                        isUser: isUserSpeech,
                        isVisible: $showSpeechBubble
                    )
                    .frame(maxWidth: 300)
                    .padding(.top, 20)
                    .zIndex(10)
                }
                
                Spacer()
                
                // Floating controls at bottom
                if viewState != .collapsed {
                    controlButtons
                        .transition(.opacity)
                }
            }
            .onChange(of: viewState) { newState in
                triggerBorderGlow()
            }
            .onChange(of: showSearchResults) { isShowing in
                if !isShowing {
                    triggerBorderGlow()
                }
            }
        }
        .overlay(
            SearchResultsOverlay(
                viewState: $viewState,
                showSearchResults: $showSearchResults,
                searchQuery: searchQuery,
                searchAnswer: searchAnswer,
                searchSources: searchSources
            )
        )
        .sheet(isPresented: $showRiggingSheet) {
            RiggingView(manager: riggingManager, isStreamingCamera: $isStreamingCamera)
        }
        .sheet(isPresented: $showSettingsSheet) {
            SettingsView(personalityEngine: personalityEngine, speechManager: speechManager)
        }
        .sheet(isPresented: $showPaywallSheet) {
            PaywallView()
        }
        .ignoresSafeArea(.all)
        .sheet(isPresented: $showWalletSheet) {
            WalletView()
        }
        .sheet(isPresented: $showDiagnostics) {
            EnrollmentFlow(isPresented: $showDiagnostics)
        }
        .sheet(isPresented: $showDebugView) {
            DebugView()
        }
        // Protocol 22 enrollment is HIDDEN - automatic background enrollment
        .onOpenURL { url in
            if url.scheme == "PCPOScompanion" && url.host == "talk" {
                // Auto-start listening and Face ID scanning
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    speechManager.startListening()
                    if viewState == .collapsed {
                        startFaceIDScanning()
                    }
                }
            }
        }
        .onChange(of: speechManager.isListening) { isListening in
            if viewState == .collapsed {
                if isListening && faceIDState == .locked {
                    // Disney Principle: Cause & Effect - Speech triggers Face ID
                    startFaceIDScanning()
                } else if !isListening && faceIDState == .unlocked {
                    // Disney Principle: Follow-through - Graceful return after action
                    scheduleFaceIDReset()
                }
            }
        }
        .onAppear {
            setupPipeline()
        }
    }

    // MARK: - View State Properties

    var avatarYOffset: CGFloat {
        switch viewState {
        case .collapsed:
            return launchAnimationOffset + (-UIScreen.main.bounds.height / 2 + 60) // Dynamic Island position
        case .normal:
            return launchAnimationOffset + floatingOffset + movementEngine.offsetY
        case .expanded:
            return launchAnimationOffset + (-UIScreen.main.bounds.height / 2 + 60) // Keep at top
        case .searchOverlay:
            return launchAnimationOffset + (-UIScreen.main.bounds.height / 2 + 60)
        }
    }

    var avatarScale: CGFloat {
        let baseScale = launchAnimationScale * movementEngine.scaleMultiplier
        switch viewState {
        case .collapsed:
            return baseScale * 0.3 // Small in Dynamic Island
        case .normal:
            return baseScale
        case .expanded:
            return baseScale * 0.4 // Medium size when expanded
        case .searchOverlay:
            return baseScale * 0.4
        }
    }
    
    // Dynamic Island Dimensions
    var dynamicIslandWidth: CGFloat {
        // Always fixed width - Dynamic Island width
        return 130
    }
    
    var dynamicIslandHeight: CGFloat {
        switch viewState {
        case .collapsed:
            return 37 // Compact pill height
        case .normal:
            return 220 // Square expanded (Face ID container)
        case .expanded:
            return 400 // Taller for search results
        case .searchOverlay:
            return 400
        }
    }
    
    var dynamicIslandRadius: CGFloat {
        switch viewState {
        case .collapsed:
            return 18 // Pill shape
        case .normal, .expanded:
            return 40 // Rounded square
        case .searchOverlay:
            return 40
        }
    }

    // Launch Animation Modifier
    var launchAnimationOffset: CGFloat {
        isLaunching ? -UIScreen.main.bounds.height / 2 + 60 : 0 // Start from top (Island area)
    }

    var launchAnimationScale: CGFloat {
        isLaunching ? 0.1 : 1.0
    }

    // MARK: - Interaction Methods

    func playBotheredReaction() {
        // Avatar reacts to being touched - annoyed/playful
        PCPOSHaptics.shared.playHeartbeat()

        // Trigger shake animation via movement engine
        movementEngine.triggerShake()

        // Trigger annoyed emotion briefly
        personalityEngine.setEmotionOverride(tag: "SURPRISED")

        // Speak a bothered phrase
        let botheredPhrases = [
            "Hey! That tickles!",
            "Stop fucking poking me!",
            "I'm trying to focus here!",
            "Personal space, please!",
            "Ouch!"
        ]
        if let phrase = botheredPhrases.randomElement() {
            speechManager.speak(phrase)
        }
    }
    
    func triggerBorderGlow() {
        // FaceID-style border glow animation
        // 1. Flash in
        withAnimation(.easeOut(duration: 0.2)) {
            borderGlowOpacity = 1.0
        }
        
        // 2. Fade out slowly
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.easeIn(duration: 0.6)) {
                borderGlowOpacity = 0.0
            }
        }
    }

    func autoExpandWithResults() {
        // Expand from collapsed state when results ready
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            viewState = .expanded
            showSearchResults = true
        }
        PCPOSHaptics.shared.playZoomIn()
    }

    func returnToNormal() {
        // Return to normal state
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            viewState = .normal
            showSearchResults = false
        }
    }

    // MARK: - Animation Methods

    func animateLaunch() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7, blendDuration: 0)) {
            isLaunching = false
        }

        // Start Live Activity
        personalityEngine.startActivity()
    }

    func startFloatingAnimation() {
        withAnimation(Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            floatingOffset = -10
        }
    }
    
    // MARK: - Frame Counter (moved to class scope)
    @State private var frameCount = 0
    
    // MARK: - Setup Camera Pipeline
    private func setupPipeline() {
        // Update debugger
        debugger.updateCameraStatus(camera.isRunning)
        debugger.updateMicrophoneStatus(speechManager.isListening)
        debugger.updateFaceModelStatus(true)
        debugger.updateSpeechRecognitionStatus(true)
        
        // 1. Camera -> Vision & CoreML & Protocol 22
        camera.sampleBufferHandler = { buffer in
            let startTime = Date()
            
            // We can run both or switch. Let's run CoreML if available, else Vision.
            // For now, we run both to test.
            visionEngine.process(sampleBuffer: buffer)

            // Extract pixel buffer from sample buffer for CoreML
            if let pixelBuffer = CMSampleBufferGetImageBuffer(buffer) {
                coreMLEngine.process(pixelBuffer: pixelBuffer)
                
                // Protocol 22: Face recognition (every 5th frame for performance)
                // Note: frameCount increment moved outside this closure for struct compatibility
                let faceStartTime = Date()
                protocol22.recognition.processFace(from: pixelBuffer)
                let faceTime = Date().timeIntervalSince(faceStartTime) * 1000 // ms
                debugger.trackFaceRecognitionTime(faceTime)
            }
            
            // Track frame processing time
            let frameTime = Date().timeIntervalSince(startTime) * 1000 // ms
            if frameTime > 20.0 { // Warn if frame takes too long
                debugger.log("Slow frame processing: \(String(format: "%.2f", frameTime))ms", severity: .warning)
            }
        }
        
        // 2. Vision/CoreML -> Personality
        // Prioritize CoreML if it returns results (not implemented fully yet without model), 
        // so we merge or just listen to Vision for now as fallback.
        
        // Merging logic:
        visionEngine.$currentPulse
            .receive(on: RunLoop.main)
            .sink { pulse in
                personalityEngine.updateEmotion(pulse: pulse)
            }
            .store(in: &cancellables)
            
        // If CoreML engine updates, it overrides
        coreMLEngine.$currentPulse
            .receive(on: RunLoop.main)
            .sink { pulse in
                // Only override if non-zero (meaning model detected something)
                if pulse.valence != 0 || pulse.arousal != 0 {
                    personalityEngine.updateEmotion(pulse: pulse)
                }
            }
            .store(in: &cancellables)
            
        // ... (Speech logic)
        speechManager.$recognizedText
            .receive(on: RunLoop.main)
            .sink { text in
                if !text.isEmpty {
                    // Update chat log with recognized speech
                    // This is just for display, actual processing happens when speech stops
                }
            }
            .store(in: &cancellables)
        
        speechManager.$isListening
            .receive(on: RunLoop.main)
            .sink { isListening in
                debugger.updateMicrophoneStatus(isListening)
                
                // Live Activity: Listening State
                if #available(iOS 16.1, *) {
                    if isListening {
                        let currentEmotion = SemanticEmotionGraph.shared.currentEmotion.rawValue
                        LiveActivityManager.shared.updateActivity(
                            emotion: currentEmotion,
                            intensity: 0.5,
                            aiState: .listening,
                            message: "Listening..."
                        )
                    } else if speechManager.recognizedText.isEmpty {
                        // If stopped listening and no text, go to idle
                        let currentEmotion = SemanticEmotionGraph.shared.currentEmotion.rawValue
                        LiveActivityManager.shared.updateActivity(
                            emotion: currentEmotion,
                            intensity: 0.3,
                            aiState: .idle,
                            message: ""
                        )
                    }
                }
                
                if !isListening && !speechManager.recognizedText.isEmpty {
                    // Speech has stopped, and we have recognized text
                    sendToChat(speechManager.recognizedText)
                }
            }
            .store(in: &cancellables)
        
        personalityEngine.$response
            .receive(on: RunLoop.main)
            .sink { response in
                if !response.isEmpty {
                    chatLog += "\nAI: \(response)"
                    speechManager.speak(response)
                }
            }
            .store(in: &cancellables)
    }
    
    private func sendToChat(_ message: String) {
        chatLog += "\nYou: \(message)"
        
        // Check if Protocol 22 should handle this message
        if protocol22.processMessage(message) {
            // Protocol 22 handled it
            speechManager.clearRecognizedText()
            return
        }
        
        // Normal flow - 🧠 Route through God Brain
        Task {
            // Live Activity: Thinking State
            if #available(iOS 16.1, *) {
                await MainActor.run {
                     let currentEmotion = SemanticEmotionGraph.shared.currentEmotion.rawValue
                     LiveActivityManager.shared.updateActivity(
                         emotion: currentEmotion,
                         intensity: 0.6,
                         aiState: .thinking,
                         message: "Thinking..."
                     )
                }
            }
            
            let response = await godBrain.ponder(input: message)
            
            // Speak and log response
            await MainActor.run {
                chatLog += "\nPCPOS: \(response)"
                speechManager.speak(response)
                
                // Also trigger Live Activity update for "Speaking" state
                 if #available(iOS 16.1, *) {
                    let currentEmotion = SemanticEmotionGraph.shared.currentEmotion.rawValue
                    LiveActivityManager.shared.updateActivity(
                        emotion: currentEmotion,
                        intensity: 0.8,
                        aiState: .speaking,
                        message: response
                    )
                }
            }
        }
        
        speechManager.clearRecognizedText()
    }
    
    // MARK: - Protocol 22 Setup
    
    private func setupProtocol22() {
        // Connect Protocol 22 to all systems
        protocol22.connect(
            cameraManager: camera,
            speechManager: speechManager,
            personalityEngine: personalityEngine,
            chatService: personalityEngine.chatService
        )
        
        // Monitor Protocol 22 activation
        protocol22.handler.$isProtocolActive
            .receive(on: RunLoop.main)
            .sink { isActive in
                if isActive {
                    debugger.log("Protocol 22 ACTIVATED - Creator detected!", severity: .info)
                    debugger.updateProtocol22Status(enrolled: true, active: true)
                    // Protocol 22 is now handling conversations
                } else {
                    debugger.updateProtocol22Status(enrolled: true, active: false)
                }
            }
            .store(in: &cancellables)
        
        // Update debugger with Protocol 22 enrollment status
        let isEnrolled = KeychainManager.shared.load(key: "protocol22_face_template") != nil &&
                        KeychainManager.shared.load(key: "protocol22_voice_template") != nil
        debugger.updateProtocol22Status(enrolled: isEnrolled, active: false)
    }
}

// Simple Rigging UI
struct RiggingView: View {
    @ObservedObject var manager: RiggingManager
    @Binding var isStreamingCamera: Bool
    @State private var isPickerPresented = false
    
    var body: some View {
        NavigationView {
            VStack {
                if let image = manager.selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .onTapGesture {
                            // Simple tap to set landmarks logic would go here
                            // For prototype: Just set default landmarks
                            manager.saveLandmarks(RiggingLandmarks(
                                leftEye: CGPoint(x: 0.35, y: 0.4),
                                rightEye: CGPoint(x: 0.65, y: 0.4),
                                mouth: CGPoint(x: 0.5, y: 0.6)
                            ))
                        }
                        .overlay(Text("Tap to Auto-Rig").foregroundColor(.white).padding().background(Color.black.opacity(0.5)))
                } else {
                    Text("No Image Selected")
                }
                
                Section(header: Text("Vision Pro Link")) {
                    Toggle("Stream Camera to Vision Pro", isOn: $isStreamingCamera)
                        .tint(.blue)
                }
                
                Section(header: Text("Advanced")) {
                    Button("Select Image") {
                        isPickerPresented = true
                    }
                    .padding()
                }
            }
            .navigationTitle("Customize Avatar")
            .sheet(isPresented: $isPickerPresented) {
                ImagePicker(image: $manager.selectedImage)
            }
        }
    }
}

// Minimal Image Picker Wrapper
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            
            guard let provider = results.first?.itemProvider else { return }
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { image, _ in
                    DispatchQueue.main.async {
                        if let uiImage = image as? UIImage {
                            self.parent.image = uiImage
                            // Auto-save
                            RiggingManager().saveImage(uiImage)
                        }
                    }
                }
            }
        }
    }
}

