import SwiftUI
import AVFoundation

// MARK: - Voice Enrollment View (Protocol 22)
// Captures user voice to train the speaker recognition system

struct VoiceEnrollmentView: View {
    @StateObject private var voiceManager = VoiceProfileManager()
    @Binding var isComplete: Bool
    
    @State private var recordingState: RecordingState = .idle
    @State private var progress: Double = 0.0
    @State private var waveform: [CGFloat] = Array(repeating: 0.1, count: 30)
    
    enum RecordingState {
        case idle
        case recording
        case processing
        case complete
        case error
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 40) {
                // Header
                Text("Voice Protocol")
                    .font(.system(size: 32, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .padding(.top, 60)
                
                Spacer()
                
                // Visualization
                HStack(spacing: 4) {
                    ForEach(0..<30, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(barColor)
                            .frame(width: 6, height: 40 * waveform[index])
                            .animation(.spring(response: 0.2), value: waveform[index])
                    }
                }
                .frame(height: 100)
                
                // Instruction
                Text(instructionText)
                    .font(.title2)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.horizontal)
                
                if recordingState == .idle {
                    Text("\"System check. Authorization Alpha-Nine. This is [Your Name].\"")
                        .font(.body)
                        .italic()
                        .foregroundColor(.gray)
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                }
                
                Spacer()
                
                // Control Button
                Button(action: handleButtonPress) {
                    ZStack {
                        Circle()
                            .fill(buttonColor)
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: buttonIcon)
                            .font(.title)
                            .foregroundColor(.white)
                    }
                }
                .disabled(recordingState == .processing)
                .padding(.bottom, 50)
            }
        }
        .onReceive(voiceManager.$isListening) { listening in
            if listening && recordingState == .recording {
                updateWaveform()
            }
        }
    }
    
    private var barColor: Color {
        switch recordingState {
        case .recording: return .red
        case .processing: return .purple
        case .complete: return .green
        default: return .gray
        }
    }
    
    private var buttonColor: Color {
        switch recordingState {
        case .recording: return .red.opacity(0.8)
        case .complete: return .green
        default: return .blue
        }
    }
    
    private var buttonIcon: String {
        switch recordingState {
        case .idle: return "mic.fill"
        case .recording: return "stop.fill"
        case .processing: return "gear"
        case .complete: return "checkmark"
        case .error: return "exclamationmark.triangle"
        }
    }
    
    private var instructionText: String {
        switch recordingState {
        case .idle: return "Tap mic and read the phrase below"
        case .recording: return "Listening..."
        case .processing: return "Generating Voice Vector..."
        case .complete: return "Voice Identity Confirmed"
        case .error: return "Error. Try Again."
        }
    }
    
    private func handleButtonPress() {
        switch recordingState {
        case .idle:
            startRecording()
        case .recording:
            stopRecording()
        case .complete:
            isComplete = true
        default:
            break
        }
    }
    
    private func startRecording() {
        recordingState = .recording
        voiceManager.startListening()
        
        // Simulate progress
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            if recordingState != .recording {
                timer.invalidate()
            } else {
                updateWaveform()
            }
        }
    }
    
    private func stopRecording() {
        voiceManager.stopListening()
        recordingState = .processing
        
        // Simulate processing
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            voiceManager.enrollUser(name: "Operator", themeColor: "#00FF00")
            recordingState = .complete
        }
    }
    
    private func updateWaveform() {
        // Simulate audio levels
        for i in 0..<30 {
            waveform[i] = CGFloat.random(in: 0.1...1.0)
        }
    }
}
