import SwiftUI

struct OnboardingView: View {
    @Binding var isCompleted: Bool
    @ObservedObject var personalityEngine: PersonalityEngine
    @ObservedObject var riggingManager: RiggingManager
    
    @State private var step = 0
    @State private var selectedAvatarMode = 0 // 0: Circle, 1: PCPOS, 2: Custom
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea(.all)
            
            VStack {
                Spacer()
                
                if step == 0 {
                    WelcomeStep()
                } else if step == 1 {
                    PersonalityStep(engine: personalityEngine)
                } else if step == 2 {
                    AvatarSelectionStep(selectedMode: $selectedAvatarMode, engine: personalityEngine, riggingManager: riggingManager)
                } else {
                    CompletionStep {
                        completeOnboarding()
                    }
                }
                
                Spacer()
                
                // Navigation Buttons
                HStack {
                    if step > 0 {
                        Button("Back") { withAnimation { step -= 1 } }
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    if step < 3 {
                        Button("Next") { withAnimation { step += 1 } }
                            .font(.headline)
                            .foregroundColor(.cyan)
                            .padding()
                            .background(Capsule().stroke(Color.cyan, lineWidth: 2))
                    }
                }
                .padding()
            }
            .padding()
        }
        .transition(.opacity)
    }
    
    func completeOnboarding() {
        // Save Avatar Preference
        UserDefaults.standard.set(selectedAvatarMode, forKey: "avatar_mode")
        withAnimation {
            isCompleted = true
        }
    }
}

struct WelcomeStep: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "cpu")
                .font(.system(size: 80))
                .foregroundColor(.cyan)
                .shadow(color: .cyan, radius: 10)
            
            Text("Initialize PCPOS")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Welcome to your personal AI companion. Let's set up your system.")
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
                .padding()
        }
    }
}

struct PersonalityStep: View {
    @ObservedObject var engine: PersonalityEngine
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Core Personality")
                .font(.title2)
                .foregroundColor(.white)
            
            ScrollView {
                VStack(spacing: 30) {
                    PersonalitySlider(label: "Cheerfulness", value: $engine.personality.cheerfulness, color: .yellow)
                    PersonalitySlider(label: "Empathy", value: $engine.personality.empathy, color: .green)
                    PersonalitySlider(label: "Curiosity", value: $engine.personality.curiosity, color: .blue)
                    PersonalitySlider(label: "Confidence", value: $engine.personality.confidence, color: .orange)
                }
                .padding()
            }
        }
    }
}

struct AvatarSelectionStep: View {
    @Binding var selectedMode: Int
    @ObservedObject var engine: PersonalityEngine
    @ObservedObject var riggingManager: RiggingManager
    @State private var showImagePicker = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Select Avatar Form")
                .font(.title2)
                .foregroundColor(.white)
            
            TabView(selection: $selectedMode) {
                // Mode 0: Dynamic Circle
                VStack {
                    AvatarCanvasView(params: engine.animationParams)
                        .frame(width: 200, height: 200)
                    Text("Dynamic Core")
                        .font(.headline)
                        .foregroundColor(.cyan)
                }
                .tag(0)
                
                // Mode 1: Face ID
                VStack {
                    FaceIDAvatarView(params: engine.animationParams)
                        .frame(width: 200, height: 200)
                        .foregroundColor(.white)
                    Text("Face ID Style")
                        .font(.headline)
                        .foregroundColor(.green)
                }
                .tag(1)

                // Mode 2: PCPOS
                VStack {
                    NetNaviView(params: engine.animationParams)
                        .frame(width: 200, height: 200)
                    Text("PCPOS Model")
                        .font(.headline)
                        .foregroundColor(.blue)
                }
                .tag(2)
                
                // Mode 3: Custom
                VStack {
                    if let image = riggingManager.selectedImage, let landmarks = riggingManager.landmarks {
                        RiggedAvatarView(image: image, landmarks: landmarks, params: engine.animationParams)
                            .frame(width: 200, height: 200)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 200, height: 200)
                            .overlay(Text("Tap to Upload").foregroundColor(.white))
                    }
                    
                    Button("Upload Image") {
                        showImagePicker = true
                    }
                    .padding(.top)
                }
                .tag(3)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
            .frame(height: 350)
            
            Text("Swipe to choose")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $riggingManager.selectedImage)
        }
    }
}

struct CompletionStep: View {
    var onComplete: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
            
            Text("System Ready")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Button(action: onComplete) {
                Text("JACK IN!!")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(LinearGradient(gradient: Gradient(colors: [.blue, .purple]), startPoint: .leading, endPoint: .trailing))
                    .clipShape(UnevenRoundedRectangle(cornerRadii: RectangleCornerRadii(topLeading: 15, bottomLeading: 15, bottomTrailing: 15, topTrailing: 15)))
                    .shadow(color: .blue.opacity(0.5), radius: 10)
            }
            .padding(.horizontal, 40)
            .padding(.top, 40)
        }
    }
}

