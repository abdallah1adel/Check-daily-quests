import SwiftUI

// MARK: - Enrollment Flow (Protocol 22)
// Orchestrates the full initialization sequence

struct EnrollmentFlow: View {
    @Binding var isPresented: Bool
    @StateObject private var faceModel = PCPOSFaceModel()
    
    @State private var currentStep: Step = .intro
    
    enum Step {
        case intro
        case face
        case voice
        case complete
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            switch currentStep {
            case .intro:
                introView
                    .transition(.opacity)
            case .face:
                Protocol22EnrollmentView(
                    enrollmentManager: Protocol22EnrollmentManager(recognition: Protocol22Recognition())
                )
                .onAppear {
                    // Auto-advance after enrollment
                    DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
                        if KeychainManager.shared.load(key: "protocol22_face_template") != nil {
                            withAnimation { currentStep = .voice }
                        }
                    }
                }
                .transition(.move(edge: .trailing))
            case .voice:
                Protocol22EnrollmentView(
                    enrollmentManager: Protocol22EnrollmentManager(recognition: Protocol22Recognition())
                )
                .onAppear {
                    // Auto-advance after enrollment
                    DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
                        if KeychainManager.shared.load(key: "protocol22_voice_template") != nil {
                            withAnimation { currentStep = .complete }
                        }
                    }
                }
                .transition(.move(edge: .trailing))
            case .complete:
                completionView
                    .transition(.scale)
            }
        }
    }
    
    var introView: some View {
        VStack(spacing: 30) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            Text("Protocol 22")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Biometric Initialization Required.\nPlease prepare for face and voice scanning.")
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
                .padding()
            
            Button(action: { withAnimation { currentStep = .face } }) {
                Text("Initialize")
                    .font(.headline)
                    .foregroundColor(.black)
                    .padding()
                    .frame(width: 200)
                    .background(Color.blue)
                    .cornerRadius(30)
            }
        }
    }
    
    var completionView: some View {
        VStack(spacing: 30) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
            
            Text("Protocol Complete")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Neural Link Established.\nWelcome, Operator.")
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
                .padding()
            
            Button(action: { isPresented = false }) {
                Text("Enter System")
                    .font(.headline)
                    .foregroundColor(.black)
                    .padding()
                    .frame(width: 200)
                    .background(Color.green)
                    .cornerRadius(30)
            }
        }
    }
}
