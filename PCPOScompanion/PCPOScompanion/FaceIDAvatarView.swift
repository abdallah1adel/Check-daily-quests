import SwiftUI

struct FaceIDAvatarView: View {
    var params: AnimationParams
    var deformation: CGSize = CGSize(width: 1.0, height: 1.0) // Squash & Stretch
    
    // Internal State for "Lock to Face" animation
    @State private var animationState: AnimationState = .locked
    @State private var scanRotation: Double = 0
    
    enum AnimationState {
        case locked
        case scanning
        case unlocked // The Face
    }

    var body: some View {
        ZStack {
            // Background glow
            Circle()
                .fill(params.colorTint.opacity(0.15))
                .blur(radius: 20)
                .scaleEffect(1.3)

            // Content based on state
            Group {
                switch animationState {
                case .locked:
                    PadlockShape()
                        .fill(params.colorTint)
                        .frame(width: 60, height: 80)
                        .transition(.scale.combined(with: .opacity))
                    
                case .scanning:
                    ScanningOrbView(color: params.colorTint)
                        .frame(width: 100, height: 100)
                        .transition(.opacity)
                    
                case .unlocked:
                    // The Face ID Avatar
                    ZStack {
                        // Face ID Brackets (corner L-shapes)
                        FaceIDBrackets()
                            .fill(params.colorTint)
                            .frame(width: 180, height: 180)
                            .shadow(color: params.colorTint.opacity(0.5), radius: 10 * params.glow)
                            // Apply deformation to brackets
                            .scaleEffect(x: deformation.width, y: deformation.height)

                        // Dot Grid Face (inside the brackets)
                        FaceIDDotGrid(params: params)
                            .frame(width: 120, height: 150)
                            // Face deforms slightly less than container for depth effect
                            .scaleEffect(x: deformation.width * 0.9 + 0.1, y: deformation.height * 0.9 + 0.1)
                    }
                    .transition(.scale(scale: 0.8).combined(with: .opacity))
                }
            }
        }
        .scaleEffect(params.glow * 0.05 + 1.0) // Subtle pulsing
        .onAppear {
            // Start the sequence
            runUnlockSequence()
        }
    }
    
    private func runUnlockSequence() {
        // 1. Start Locked
        animationState = .locked
        
        // 2. Start Scanning (after 0.5s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeInOut(duration: 0.3)) {
                animationState = .scanning
            }
            PCPOSHaptics.shared.playListeningStart()
        }
        
        // 3. Unlock / Reveal Face (after 1.5s total)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                animationState = .unlocked
            }
            PCPOSHaptics.shared.playSuccess()
        }
    }
}

// MARK: - Helper Shapes

struct PadlockShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        
        // Body
        let bodyRect = CGRect(x: 0, y: height * 0.4, width: width, height: height * 0.6)
        path.addRoundedRect(in: bodyRect, cornerSize: CGSize(width: 8, height: 8))
        
        // Shackle
        let shackleWidth = width * 0.6
        let shackleHeight = height * 0.5
        let shackleX = (width - shackleWidth) / 2
        let shackleRect = CGRect(x: shackleX, y: 0, width: shackleWidth, height: shackleHeight)
        
        var shacklePath = Path()
        shacklePath.addRoundedRect(in: shackleRect, cornerSize: CGSize(width: shackleWidth/2, height: shackleWidth/2))
        
        // Cut out the bottom of the shackle
        // (Simplified: Just drawing the arc)
        path.addPath(shacklePath)
        
        return path
    }
}

struct ScanningOrbView: View {
    let color: Color
    @State private var isRotating = false
    
    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(
                    AngularGradient(gradient: Gradient(colors: [color.opacity(0), color, color.opacity(0)]), center: .center),
                    lineWidth: 8
                )
                .rotationEffect(.degrees(isRotating ? 360 : 0))
                .animation(Animation.linear(duration: 1.0).repeatForever(autoreverses: false), value: isRotating)
            
            Circle()
                .fill(color.opacity(0.2))
                .scaleEffect(isRotating ? 1.1 : 0.9)
                .animation(Animation.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: isRotating)
        }
        .onAppear {
            isRotating = true
        }
    }
}


#Preview {
    FaceIDAvatarView(params: AnimationParams(
        eyeOpen: 1.0,
        browRaise: 0.0,
        mouthSmile: 0.5,
        mouthOpen: 0.2,
        headTilt: 0.0,
        glow: 0.8,
        colorTint: .cyan
    ))
    .background(Color.black)
}
