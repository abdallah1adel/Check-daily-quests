import SwiftUI
import Combine

struct ContentView: View {
    @StateObject private var camera = CameraManager()
    @StateObject private var visionEngine = VisionEmotionEngine()
    @StateObject private var coreMLEngine = CoreMLEmotionEngine() // NEW
    @StateObject private var personalityEngine = PersonalityEngine()
    @StateObject private var speechManager = SpeechManager()
    @StateObject private var riggingManager = RiggingManager()
    
    // ... (Rest of properties)
    @State private var cancellables = Set<AnyCancellable>()
    @State private var chatLog: String = "Hello! How can I help you today?"
    
    @State private var showRiggingSheet = false
    @State private var showSettingsSheet = false
    @State private var breathingScale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            // Background Breathing Effect
            Circle()
                .fill(personalityEngine.animationParams.colorTint.opacity(0.1))
                .scaleEffect(breathingScale)
                .animation(Animation.easeInOut(duration: 4).repeatForever(autoreverses: true), value: breathingScale)
                .onAppear { breathingScale = 1.2 }
            
            VStack {
                HStack {
                    // Settings Button (Left)
                    Button(action: { showSettingsSheet = true }) {
                        Image(systemName: "gearshape.fill")
                            .font(.title)
                            .foregroundColor(.gray.opacity(0.5))
                    }
                    .padding()
                    
                    Spacer()
                    
                    // Rigging Button (Right)
                    Button(action: { showRiggingSheet = true }) {
                        Image(systemName: "pencil.circle.fill")
                            .font(.title)
                            .foregroundColor(.gray.opacity(0.5))
                    }
                    .padding()
                }
                
                Spacer()
                
                // Avatar Display
                Group {
                    if let image = riggingManager.selectedImage, let landmarks = riggingManager.landmarks {
                        // Rigged Mode
                        RiggedAvatarView(image: image, landmarks: landmarks, params: personalityEngine.animationParams)
                            .frame(width: 250, height: 250)
                            .clipShape(RoundedRectangle(cornerRadius: 40))
                            .overlay(RoundedRectangle(cornerRadius: 40).stroke(personalityEngine.animationParams.colorTint, lineWidth: 4))
                            .shadow(color: personalityEngine.animationParams.colorTint.opacity(0.5), radius: 20)
                    } else {
                        // Vector Mode
                        AvatarCanvasView(params: personalityEngine.animationParams)
                            .frame(width: 250, height: 250)
                            .shadow(color: personalityEngine.animationParams.colorTint.opacity(0.5), radius: 20)
                    }
                }
                .padding()
                .offset(y: launchAnimationOffset)
                .scaleEffect(launchAnimationScale)
                .onAppear {
                    // Trigger animation slightly after appear
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        animateLaunch()
                    }
                }
                
                // Chat Log
                ScrollView {
                    Text(chatLog)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                }
                .frame(height: 100)
                .background(Color.black.opacity(0.3))
                .cornerRadius(10)
                .padding(.horizontal)
                
                Spacer()
                
                // Controls
                HStack(spacing: 40) {
                    // Camera Toggle
                    Button(action: {
                        if camera.isRunning { camera.stop() } else { camera.start() }
                    }) {
                        Image(systemName: camera.isRunning ? "video.fill" : "video.slash.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(20)
                            .background(Circle().fill(Color.gray.opacity(0.3)))
                    }
                    
                    // Talk Button (Ripple Effect)
                    Button(action: {
                        HapticsManager.shared.playHeartbeat() // Feedback on tap
                        if speechManager.isListening {
                            speechManager.stopListening()
                            sendToChat(speechManager.recognizedText)
                        } else {
                            speechManager.startListening()
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
        }
        .background(Color.black.edgesIgnoringSafeArea(.all))
        .sheet(isPresented: $showRiggingSheet) {
            RiggingView(manager: riggingManager)
        }
        .sheet(isPresented: $showSettingsSheet) {
            SettingsView(personalityEngine: personalityEngine, speechManager: speechManager)
        }
        .onOpenURL { url in
            if url.scheme == "PCPOScompanion" && url.host == "talk" {
                // Auto-start listening
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    speechManager.startListening()
                }
            }
        }
        .onAppear {
            setupPipeline()
        }
    }
    
    private func setupPipeline() {
        // 1. Camera -> Vision & CoreML
        camera.sampleBufferHandler = { buffer in
            // We can run both or switch. Let's run CoreML if available, else Vision.
            // For now, we run both to test.
            visionEngine.process(sampleBuffer: buffer)
            coreMLEngine.process(pixelBuffer: buffer)
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
    
    // Launch Animation State
    @State private var isLaunching = true
    
    private func sendToChat(_ message: String) {
        chatLog += "\nYou: \(message)"
        personalityEngine.process(text: message)
        speechManager.clearRecognizedText()
    }
    
    // Launch Animation Modifier
    var launchAnimationOffset: CGFloat {
        isLaunching ? -UIScreen.main.bounds.height / 2 + 60 : 0 // Start from top (Island area)
    }
    
    var launchAnimationScale: CGFloat {
        isLaunching ? 0.1 : 1.0
    }
}

// Extension to wrap the avatar in the animation
extension ContentView {
    func animateLaunch() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7, blendDuration: 0)) {
            isLaunching = false
        }
        
        // Start Live Activity
        personalityEngine.startActivity()
    }
}

// Simple Rigging UI
struct RiggingView: View {
    @ObservedObject var manager: RiggingManager
    @State private var isPickerPresented = false
    
    var body: some View {
        NavigationView {
            VStack {
                if let image = manager.selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .onTapGesture { loc in
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
                
                Button("Select Image") {
                    isPickerPresented = true
                }
                .padding()
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
