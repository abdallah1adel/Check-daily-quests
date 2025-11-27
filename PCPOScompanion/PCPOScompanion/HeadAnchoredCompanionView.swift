import SwiftUI
#if os(visionOS)
import RealityKit
import RealityKitContent
#endif

#if os(visionOS)
struct HeadAnchoredCompanionView: View {
    @StateObject private var personalityEngine = PersonalityEngine()
    @StateObject private var speechManager = SpeechManager()
    
    var body: some View {
        RealityView { content, attachments in
            // Create a head-anchored entity
            let headAnchor = AnchorEntity(.head)
            
            // Create a billboard entity (always faces user)
            let billboardEntity = ModelEntity(
                mesh: .generatePlane(width: 0.3, height: 0.3),
                materials: [UnlitMaterial(color: .clear)]
            )
            
            // Position: 1.5 meters in front, slightly down
            billboardEntity.position = [0, -0.2, -1.5]
            
            // Add attachment (SwiftUI View) to the entity
            if let attachment = attachments.entity(for: "AvatarView") {
                attachment.position = [0, 0, 0]
                billboardEntity.addChild(attachment)
            }
            
            // Add Camera Receiver Attachment (Floating to the side)
            if let camAttachment = attachments.entity(for: "CameraView") {
                camAttachment.position = [0.6, 0, 0] // 60cm to the right
                billboardEntity.addChild(camAttachment)
            }
            
            headAnchor.addChild(billboardEntity)
            content.add(headAnchor)
            
        } attachments: {
            Attachment(id: "AvatarView") {
                // Reuse the existing AvatarCanvasView
                // We map the personality engine state to animation params
                let params = AnimationParams(
                    eyeOpen: personalityEngine.currentAttributes.eyeOpen,
                    browRaise: personalityEngine.currentAttributes.browRaise,
                    mouthSmile: personalityEngine.currentAttributes.smile,
                    mouthOpen: personalityEngine.currentAttributes.mouthOpen,
                    headTilt: personalityEngine.currentAttributes.headTilt,
                    glow: personalityEngine.currentAttributes.glow,
                    colorTint: Color(hue: personalityEngine.currentAttributes.hue, saturation: 0.8, brightness: 1.0)
                )
                
                AvatarCanvasView(params: params)
                    .frame(width: 300, height: 300) // Larger for 3D space
                    .glassBackgroundEffect() // VisionOS glass effect
            }
            
            Attachment(id: "CameraView") {
                CameraReceiverView()
                    .frame(width: 200, height: 300)
            }
        }
        .onAppear {
            setupPipeline()
        }
    }
    
    private func setupPipeline() {
        // Connect Speech -> Chat -> TTS -> Animation
        // This mirrors the iOS setup but simplified for HUD
        speechManager.startListening { text in
            Task {
                let (response, emotion) = await personalityEngine.chatService.sendMessage(text)
                if let emotion = emotion {
                    personalityEngine.updateEmotion(pad: PADEmotion.fromTag(emotion))
                }
                speechManager.speak(response)
            }
        }
    }
}
#endif

