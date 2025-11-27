import SwiftUI

// MARK: - Enhanced Face ID View with Individual Part Movement

extension RefinedPCPOSFaceIDView {
    
    /// Enhanced eye shape with individual movement and symbol effects
    @ViewBuilder
    func enhancedEyeShape(
        size: CGFloat,
        offset: CGSize,
        rotation: Angle,
        scale: CGFloat,
        intensity: Double
    ) -> some View {
        ZStack {
            // Eye with gradient fill
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: faceModel.profile.appearance.colors.primary),
                            Color(hex: faceModel.profile.appearance.colors.primary).opacity(0.7)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(
                    width: size * 0.12,
                    height: size * 0.12 * faceModel.profile.geometry.eyeLeft.openness
                )
                .overlay(
                    Capsule()
                        .stroke(Color(hex: faceModel.profile.appearance.colors.primary).opacity(0.3), lineWidth: 1)
                )
            
            // Highlight (glint)
            Circle()
                .fill(Color.white.opacity(0.4))
                .frame(width: size * 0.03, height: size * 0.03)
                .offset(x: -size * 0.02, y: -size * 0.02)
            
            // Symbol overlay for effects
            Image(systemName: "circle.fill")
                .font(.system(size: size * 0.08))
                .foregroundStyle(Color(hex: faceModel.profile.appearance.colors.primary).opacity(0.3))
                .symbolEffect(
                    .wiggle.custom(angle: .degrees(257.0 * intensity)).byLayer,
                    options: .repeat(.periodic(delay: 0.3))
                )
                .symbolEffect(.pulse, isActive: speechManager.isSpeaking)
                .symbolEffect(.breathe, options: .repeat(.continuous).speed(intensity))
        }
        .offset(offset)
        .rotationEffect(rotation)
        .scaleEffect(scale)
    }
    
    /// Enhanced nose with symbol effects
    @ViewBuilder
    func enhancedNose(
        size: CGFloat,
        offset: CGSize,
        rotation: Angle,
        scale: CGFloat,
        intensity: Double
    ) -> some View {
        ZStack {
            Capsule()
                .fill(Color(hex: faceModel.profile.appearance.colors.primary))
                .frame(width: size * 0.03, height: size * 0.06)
            
            // Symbol effect overlay
            Image(systemName: "diamond.fill")
                .font(.system(size: size * 0.04))
                .foregroundStyle(Color(hex: faceModel.profile.appearance.colors.primary).opacity(0.4))
                .symbolEffect(
                    .wiggle.custom(angle: .degrees(127.0 * intensity)).byLayer,
                    options: .repeat(.periodic(delay: 0.5))
                )
                .symbolEffect(.scale.up, isActive: intensity > 0.7)
        }
        .offset(offset)
        .rotationEffect(rotation)
        .scaleEffect(scale)
    }
    
    /// Enhanced mouth with extensive symbol effects
    @ViewBuilder
    func enhancedMouth(
        size: CGFloat,
        offset: CGSize,
        rotation: Angle,
        scale: CGFloat,
        intensity: Double
    ) -> some View {
        let openAmount = CGFloat(speechManager.audioLevel)
        let smile = faceModel.profile.geometry.mouth.smile
        
        ZStack {
            // Main mouth shape
            Group {
                if openAmount > 0.2 {
                    // Open mouth (talking)
                    Ellipse()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color(hex: faceModel.profile.appearance.colors.primary),
                                    Color(hex: faceModel.profile.appearance.colors.primary).opacity(0.6)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 3
                        )
                        .frame(
                            width: size * 0.18,
                            height: size * 0.08 * (0.5 + openAmount)
                        )
                } else {
                    // Closed mouth
                    Path { path in
                        let width = size * 0.2
                        let curvature = smile * size * 0.05
                        
                        path.move(to: CGPoint(x: -width/2, y: 0))
                        path.addQuadCurve(
                            to: CGPoint(x: width/2, y: 0),
                            control: CGPoint(x: 0, y: curvature)
                        )
                    }
                    .stroke(
                        Color(hex: faceModel.profile.appearance.colors.primary),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                }
            }
            
            // Symbol effects overlay
            Image(systemName: "waveform")
                .font(.system(size: size * 0.1))
                .foregroundStyle(Color(hex: faceModel.profile.appearance.colors.primary).opacity(0.2))
                .symbolEffect(
                    .wiggle.custom(angle: .degrees(173.0 * intensity)).byLayer,
                    options: .repeat(.periodic(delay: 0.2))
                )
                .symbolEffect(.variableColor.iterative, options: .repeat(.continuous), isActive: speechManager.isSpeaking)
                .symbolEffect(.pulse)
        }
        .offset(offset)
        .rotationEffect(rotation)
        .scaleEffect(scale)
    }
}

// MARK: - Symbol Effect Extensions

extension View {
    func applyDynamicWiggle(angle: Double, delay: Double, isActive: Bool) -> some View {
        self.symbolEffect(
            .wiggle.custom(angle: .degrees(angle)).byLayer,
            options: .repeat(.periodic(delay: delay)),
            isActive: isActive
        )
    }
    
    func applyCompositeEffects(intensity: Double, speaking: Bool) -> some View {
        self
            .symbolEffect(.pulse, options: .repeat(.continuous), isActive: speaking)
            .symbolEffect(.breathe, options: .repeat(.continuous).speed(intensity))
            .symbolEffect(
                .wiggle.custom(angle: .degrees(257.0 * intensity)).byLayer,
                options: .repeat(.periodic(delay: 0.3 / intensity))
            )
            .symbolEffect(.variableColor.cumulative, isActive: intensity > 0.7)
    }
}
