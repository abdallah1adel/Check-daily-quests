import SwiftUI
import ActivityKit

// MARK: - Dynamic Island Compact View (44×44pt Square)

@available(iOS 16.1, *)
struct DynamicIslandCompactView: View {
    @ObservedObject var faceModel: PCPOSFaceModel
    @ObservedObject var speechManager: SpeechManager
    
    private let size: CGFloat = 44
    
    var body: some View {
        ZStack {
            // Background
            Circle()
                .fill(Color.black)
                .frame(width: size, height: size)
            
            // Minimal bracket circle
            Circle()
                .stroke(emotionColor, lineWidth: 1.5)
                .frame(width: size - 4, height: size - 4)
                .opacity(speechManager.isSpeaking ? 1.0 : 0.7)
            
            // Mini face (3 features only)
            VStack(spacing: 2) {
                // Eyes (2 dots)
                HStack(spacing: 6) {
                    Circle()
                        .fill(emotionColor)
                        .frame(width: 3, height: 3)
                    Circle()
                        .fill(emotionColor)
                        .frame(width: 3, height: 3)
                }
                
                // Mouth (simple line)
                mouthShape
                    .stroke(emotionColor, lineWidth: 1.5)
                    .frame(width: 12, height: 4)
            }
            .offset(y: -2)
            
            // Speaking indicator (waveform pulse)
            if speechManager.isSpeaking {
                Circle()
                    .fill(emotionColor.opacity(0.3))
                    .frame(width: size, height: size)
                    .scaleEffect(1.0 + CGFloat(speechManager.audioLevel) * 0.3)
                    .animation(.easeInOut(duration: 0.1), value: speechManager.audioLevel)
            }
        }
        .frame(width: size, height: size)
    }
    
    private var emotionColor: Color {
        let smile = faceModel.profile.geometry.mouth.smile
        if smile > 0.5 {
            return .green  // Happy
        } else if smile < -0.5 {
            return .blue  // Sad
        } else {
            return Color(hex: faceModel.profile.appearance.colors.primary)
        }
    }
    
    @ViewBuilder
    private var mouthShape: some View {
        let smile = faceModel.profile.geometry.mouth.smile
        let openAmount = CGFloat(speechManager.audioLevel)
        
        if openAmount > 0.2 {
            // Open (talking)
            Ellipse()
                .frame(width: 8, height: 3 * (0.5 + openAmount))
        } else {
            // Smile/frown
            Path { path in
                let width: CGFloat = 12
                let curvature = smile * 2
                path.move(to: CGPoint(x: 0, y: 0))
                path.addQuadCurve(
                    to: CGPoint(x: width, y: 0),
                    control: CGPoint(x: width/2, y: curvature)
                )
            }
        }
    }
}

// MARK: - Live Activity Attributes

@available(iOS 16.1, *)
struct PCPOSFaceActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var emotion: String
        var isSpeaking: Bool
        var audioLevel: Double
        var timestamp: Date
    }
    
    var sessionID: String
}

// MARK: - Live Activity Manager

@available(iOS 16.1, *)
class LiveActivityManager: ObservableObject {
    @Published var currentActivity: Activity<PCPOSFaceActivityAttributes>?
    
    func startActivity(emotion: String) {
        let attributes = PCPOSFaceActivityAttributes(sessionID: UUID().uuidString)
        let initialState = PCPOSFaceActivityAttributes.ContentState(
            emotion: emotion,
            isSpeaking: false,
            audioLevel: 0.0,
            timestamp: Date()
        )
        
        do {
            currentActivity = try Activity.request(
                attributes: attributes,
                contentState: initialState,
                pushType: nil
            )
        } catch {
            print("Error starting Live Activity: \(error)")
        }
    }
    
    func updateActivity(emotion: String, isSpeaking: Bool, audioLevel: Double) {
        guard let activity = currentActivity else { return }
        
        Task {
            let newState = PCPOSFaceActivityAttributes.ContentState(
                emotion: emotion,
                isSpeaking: isSpeaking,
                audioLevel: audioLevel,
                timestamp: Date()
            )
            
            await activity.update(using: newState)
        }
    }
    
    func endActivity() {
        guard let activity = currentActivity else { return }
        
        Task {
            await activity.end(dismissalPolicy: .immediate)
            currentActivity = nil
        }
    }
}
