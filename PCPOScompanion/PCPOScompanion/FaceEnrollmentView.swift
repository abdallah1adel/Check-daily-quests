import SwiftUI
import AVFoundation

// MARK: - Face Enrollment View (Protocol 22)
// Scans user face geometry to calibrate the PCPOS avatar

struct FaceEnrollmentView: View {
    @ObservedObject var faceModel: PCPOSFaceModel
    @StateObject private var camera = CameraManager()
    @Binding var isComplete: Bool
    
    @State private var scanProgress: Double = 0.0
    @State private var scanState: ScanState = .positioning
    @State private var feedbackText: String = "Position face in circle"
    @State private var showGrid: Bool = false
    
    enum ScanState {
        case positioning
        case scanning
        case analyzing
        case complete
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // Camera Preview
            CameraPreview(session: camera.session)
                .opacity(0.6)
                .ignoresSafeArea()
            
            // Scanning Overlay
            VStack {
                Spacer()
                
                ZStack {
                    // Target Circle
                    Circle()
                        .stroke(scanColor, lineWidth: 3)
                        .frame(width: 300, height: 300)
                    
                    // Scanning Grid (Face ID Style)
                    if showGrid {
                        ScanningGrid()
                            .frame(width: 300, height: 300)
                            .mask(Circle())
                    }
                    
                    // Progress Ring
                    Circle()
                        .trim(from: 0, to: scanProgress)
                        .stroke(Color.green, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                        .frame(width: 310, height: 310)
                        .rotationEffect(.degrees(-90))
                }
                
                Spacer()
                
                // Feedback Text
                Text(feedbackText)
                    .font(.system(size: 24, weight: .medium, design: .monospaced))
                    .foregroundColor(.white)
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
                
                // Action Button
                if scanState == .positioning {
                    Button(action: startScan) {
                        Text("Initiate Scan")
                            .font(.headline)
                            .foregroundColor(.black)
                            .padding()
                            .frame(width: 200)
                            .background(Color.white)
                            .cornerRadius(30)
                    }
                    .padding(.bottom, 50)
                }
            }
        }
        .onAppear {
            camera.checkPermissions()
        }
    }
    
    private var scanColor: Color {
        switch scanState {
        case .positioning: return .white.opacity(0.5)
        case .scanning: return .blue
        case .analyzing: return .purple
        case .complete: return .green
        }
    }
    
    private func startScan() {
        withAnimation {
            scanState = .scanning
            showGrid = true
            feedbackText = "Hold still..."
        }
        
        // Simulate scanning process
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
            withAnimation {
                scanProgress += 0.01
            }
            
            if scanProgress >= 1.0 {
                timer.invalidate()
                analyzeFace()
            }
        }
    }
    
    private func analyzeFace() {
        withAnimation {
            scanState = .analyzing
            feedbackText = "Calibrating Geometry..."
        }
        
        // Simulate analysis delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            completeEnrollment()
        }
    }
    
    private func completeEnrollment() {
        withAnimation {
            scanState = .complete
            feedbackText = "Face Topology Acquired"
        }
        
        // Save dummy profile data
        saveFaceProfile()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isComplete = true
        }
    }
    
    private func saveFaceProfile() {
        // In real implementation, this would save actual measurements
        // For now, we just mark it as done
        UserDefaults.standard.set(true, forKey: "FaceProfileEnrolled")
    }
}

struct ScanningGrid: View {
    var body: some View {
        GeometryReader { geo in
            Path { path in
                let step: CGFloat = 30
                for x in stride(from: 0, to: geo.size.width, by: step) {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: geo.size.height))
                }
                for y in stride(from: 0, to: geo.size.height, by: step) {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: geo.size.width, y: y))
                }
            }
            .stroke(Color.green.opacity(0.3), lineWidth: 1)
        }
    }
}
