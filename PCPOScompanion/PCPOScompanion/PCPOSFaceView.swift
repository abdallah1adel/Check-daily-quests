import SwiftUI

struct PCPOSFaceView: View {
    @ObservedObject var model: PCPOSFaceModel
    
    // Controllers (managed internally or passed in?)
    // For simplicity, we'll let the model drive the state, and this view just renders it.
    // However, we need the controllers to handle the *animation logic* (blinking, etc).
    // Ideally, the Model holds the state, and Controllers update the Model.
    
    // Let's instantiate controllers here for now, observing the model.
    // In a perfect world, these would be in the Model, but SwiftUI Views need to own StateObjects often.
    
    @StateObject private var eyeController: PCPOSEyeController
    @StateObject private var mouthController: PCPOSMouthController
    @StateObject private var headController: PCPOSHeadRotationController
    
    init(model: PCPOSFaceModel) {
        self.model = model
        
        // Initialize controllers with references to the model's geometry
        // Note: This is a bit tricky because StateObjects init is special.
        // We'll init them with dummy values and sync in onAppear/onChange if needed,
        // OR we rely on the Model being the single source of truth and Controllers just modifying it.
        
        // BETTER APPROACH:
        // The Controllers should probably be owned by the PCPOSFaceModel or a higher level manager.
        // But for this view, we'll create them to manage the *animations*.
        
        _eyeController = StateObject(wrappedValue: PCPOSEyeController(leftEye: model.profile.geometry.eyeLeft, rightEye: model.profile.geometry.eyeRight))
        _mouthController = StateObject(wrappedValue: PCPOSMouthController(mouth: model.profile.geometry.mouth))
        _headController = StateObject(wrappedValue: PCPOSHeadRotationController(transform: model.profile.transform))
    }
    
    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            let center = CGPoint(x: size.width/2, y: size.height/2)
            
            ZStack {
                // 1. Head Shape / Background
                // Using the canvas configuration from profile
                RoundedRectangle(cornerRadius: model.profile.canvas.cornerRadius)
                    .fill(Color(hex: model.profile.appearance.colors.background))
                    .overlay(
                        RoundedRectangle(cornerRadius: model.profile.canvas.cornerRadius)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color(hex: model.profile.appearance.colors.primary).opacity(0.8),
                                        Color(hex: model.profile.appearance.colors.secondary).opacity(0.5)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
                    .shadow(
                        color: Color(hex: model.profile.appearance.colors.glowColor).opacity(model.profile.appearance.colors.glowOpacity),
                        radius: model.profile.appearance.effects.glow.radius
                    )
                
                // 2. Face Container (Rotatable)
                ZStack {
                    // Eyes
                    PCPOSEyeView(
                        geometry: model.profile.geometry.eyeLeft,
                        isLeft: true,
                        color: Color(hex: model.profile.appearance.colors.primary)
                    )
                    
                    PCPOSEyeView(
                        geometry: model.profile.geometry.eyeRight,
                        isLeft: false,
                        color: Color(hex: model.profile.appearance.colors.primary)
                    )
                    
                    // Mouth
                    PCPOSMouthView(
                        geometry: model.profile.geometry.mouth,
                        smile: model.profile.geometry.mouth.smile,
                        color: Color(hex: model.profile.appearance.colors.primary)
                    )
                }
                .headRotation(model.profile.transform) // Apply 3D rotation
            }
        }
        .onAppear {
            // Start idle animations
            eyeController.startAutoBlink()
            eyeController.startNaturalSaccades()
            mouthController.startIdleBreathing()
        }
        .onChange(of: model.profile.geometry.eyeLeft.openness) { _ in
            // Sync if needed, but Model is @Published so view updates automatically
        }
    }
}
