import Foundation
import SwiftUI
import Combine

// MARK: - Face Profile Configuration

// MARK: - Face Profile Configuration (v2.0)

struct PCPOSFaceProfile: Codable, Sendable {
    let version: String
    let metadata: ProfileMetadata
    let canvas: CanvasConfiguration
    var geometry: FaceGeometry
    var transform: HeadTransform
    var appearance: AppearanceSettings
    let animation: AnimationSettings
    let integration: IntegrationSettings
    
    struct ProfileMetadata: Codable, Sendable {
        let name: String
        let author: String
        let created: String
        let appleCompliant: Bool
        let dynamicIslandReady: Bool
        let liveActivitySupported: Bool
    }
    
    struct CanvasConfiguration: Codable, Sendable {
        let size: CGSize
        let backgroundColor: String
        let containerStyle: String
        let cornerRadius: CGFloat
        let safeArea: EdgeInsets
        
        struct EdgeInsets: Codable, Sendable {
            let top: CGFloat
            let bottom: CGFloat
            let left: CGFloat
            let right: CGFloat
        }
    }
    
    struct FaceGeometry: Codable, Sendable {
        let headShape: HeadShape
        var eyeLeft: EyeGeometry
        var eyeRight: EyeGeometry
        var mouth: MouthGeometry
    }
    
    struct HeadShape: Codable, Sendable {
        let type: String
        let width: CGFloat
        let height: CGFloat
        let cornerRadius: CGFloat
        let anchorPoints: AnchorPoints
        
        struct AnchorPoints: Codable, Sendable {
            let topCenter: CGPoint
            let topLeft: CGPoint
            let topRight: CGPoint
            let bottomLeft: CGPoint
            let bottomRight: CGPoint
            let chin: CGPoint
        }
    }
    
    struct EyeGeometry: Codable, Sendable {
        let type: String
        let center: CGPoint
        let width: CGFloat
        let height: CGFloat
        let thickness: CGFloat
        var openness: CGFloat
        var squint: CGFloat
        var gazeOffset: CGPoint
    }
    
    struct MouthGeometry: Codable, Sendable {
        let type: String
        let center: CGPoint
        let width: CGFloat
        let height: CGFloat
        let thickness: CGFloat
        var smile: CGFloat
        var openness: CGFloat
        var viseme: String
        var mouthWidth: CGFloat
    }
    
    struct AppearanceSettings: Codable, Sendable {
        var colors: ColorPalette
        var effects: VisualEffects
        
        struct ColorPalette: Codable, Sendable {
            var primary: String
            var secondary: String
            var accent: String
            var background: String
            var glowColor: String
            var glowOpacity: CGFloat
        }
        
        struct VisualEffects: Codable, Sendable {
            var glow: GlowEffect
            var shadow: ShadowEffect
            var scanLine: ScanLineEffect
            
            struct GlowEffect: Codable, Sendable {
                var enabled: Bool
                var radius: CGFloat
                var intensity: CGFloat
            }
            
            struct ShadowEffect: Codable, Sendable {
                var enabled: Bool
                var color: String
                var opacity: CGFloat
                var offset: CGPoint
                var blur: CGFloat
            }
            
            struct ScanLineEffect: Codable, Sendable {
                var enabled: Bool
                var speed: CGFloat
                var opacity: CGFloat
            }
        }
    }
    
    struct AnimationSettings: Codable, Sendable {
        let disney: DisneySettings
        let timing: TimingSettings
        
        struct DisneySettings: Codable, Sendable {
            let anticipation: EffectSetting
            let followThrough: EffectSetting
            let squashStretch: SquashStretchSetting
            
            struct EffectSetting: Codable, Sendable {
                let enabled: Bool
                let duration: Double
                let magnitude: Double?
                let delay: Double?
            }
            
            struct SquashStretchSetting: Codable, Sendable {
                let enabled: Bool
                let maxDeformation: Double
            }
        }
        
        struct TimingSettings: Codable, Sendable {
            let autoBlink: IntervalSetting
            let saccade: IntervalSetting
            
            struct IntervalSetting: Codable, Sendable {
                let interval: Double
                let variation: Double?
                let maxOffset: Double?
            }
        }
    }
    
    struct IntegrationSettings: Codable, Sendable {
        let dynamicIsland: DynamicIslandConfig
        let liveActivity: LiveActivityConfig
        let avFoundation: AVFoundationConfig
        
        struct DynamicIslandConfig: Codable, Sendable {
            let enabled: Bool
            let compactSize: CGSize
            let expandedSize: CGSize
            let scaleFactor: CGFloat
            let backgroundStyle: String
        }
        
        struct LiveActivityConfig: Codable, Sendable {
            let enabled: Bool
            let updateFrequency: Double
            let maxDuration: Double
        }
        
        struct AVFoundationConfig: Codable, Sendable {
            let faceTrackingEnabled: Bool
            let useFrontCamera: Bool
            let minFaceSize: CGFloat
            let maxFaces: Int
        }
    }
}

extension CGPoint: Codable {
    enum CodingKeys: String, CodingKey {
        case x, y
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let x = try container.decode(CGFloat.self, forKey: .x)
        let y = try container.decode(CGFloat.self, forKey: .y)
        self.init(x: x, y: y)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(x, forKey: .x)
        try container.encode(y, forKey: .y)
    }
}

// MARK: - Head Transform (3D Rotation)

struct HeadTransform: Codable, Sendable {
    var rotation: Rotation
    var scale: CGFloat
    var position: CGPoint
    
    struct Rotation: Codable, Sendable {
        var pitch: CGFloat // X-axis: nod up/down
        var yaw: CGFloat   // Y-axis: turn left/right
        var roll: CGFloat  // Z-axis: tilt sideways
    }
    
    init() {
        self.rotation = Rotation(pitch: 0, yaw: 0, roll: 0)
        self.scale = 1.0
        self.position = .zero
    }
    
    // Convert Euler angles to affine transform for SwiftUI
    func toAffineTransform(anchorPoint: CGPoint) -> CGAffineTransform {
        var transform = CGAffineTransform.identity
        
        // Yaw creates perspective scaling (3/4 view)
        let yawScale = cos(rotation.yaw * .pi / 180)
        transform = transform.scaledBy(x: max(0.3, yawScale), y: 1.0)
        
        // Pitch creates vertical shear
        let pitchShear = sin(rotation.pitch * .pi / 180) * 0.3
        transform = transform.concatenating(
            CGAffineTransform(a: 1, b: pitchShear, c: 0, d: 1, tx: 0, ty: 0)
        )
        
        // Roll is pure rotation
        transform = transform.rotated(by: rotation.roll * .pi / 180)
        
        // Apply scale
        transform = transform.scaledBy(x: scale, y: scale)
        
        return transform
    }
}

// MARK: - PCPOS Face Model

@MainActor
class PCPOSFaceModel: ObservableObject {
    @Published var profile: PCPOSFaceProfile
    
    init() {
        // Default face profile (PCPOS v2.0)
        self.profile = PCPOSFaceProfile(
            version: "2.0",
            metadata: PCPOSFaceProfile.ProfileMetadata(
                name: "PCPOS Default",
                author: "PCPOS Companion",
                created: "2025-11-27",
                appleCompliant: true,
                dynamicIslandReady: true,
                liveActivitySupported: true
            ),
            canvas: PCPOSFaceProfile.CanvasConfiguration(
                size: CGSize(width: 150, height: 150),
                backgroundColor: "#000000",
                containerStyle: "squircle",
                cornerRadius: 37.5,
                safeArea: PCPOSFaceProfile.CanvasConfiguration.EdgeInsets(top: 10, bottom: 10, left: 10, right: 10)
            ),
            geometry: PCPOSFaceProfile.FaceGeometry(
                headShape: PCPOSFaceProfile.HeadShape(
                    type: "hexagon",
                    width: 150,
                    height: 150,
                    cornerRadius: 20,
                    anchorPoints: PCPOSFaceProfile.HeadShape.AnchorPoints(
                        topCenter: CGPoint(x: 0, y: -75),
                        topLeft: CGPoint(x: -60, y: -50),
                        topRight: CGPoint(x: 60, y: -50),
                        bottomLeft: CGPoint(x: -50, y: 50),
                        bottomRight: CGPoint(x: 50, y: 50),
                        chin: CGPoint(x: 0, y: 75)
                    )
                ),
                eyeLeft: PCPOSFaceProfile.EyeGeometry(
                    type: "bracket",
                    center: CGPoint(x: -30, y: -10),
                    width: 25,
                    height: 30,
                    thickness: 4,
                    openness: 1.0,
                    squint: 0.0,
                    gazeOffset: .zero
                ),
                eyeRight: PCPOSFaceProfile.EyeGeometry(
                    type: "bracket",
                    center: CGPoint(x: 30, y: -10),
                    width: 25,
                    height: 30,
                    thickness: 4,
                    openness: 1.0,
                    squint: 0.0,
                    gazeOffset: .zero
                ),
                mouth: PCPOSFaceProfile.MouthGeometry(
                    type: "arc",
                    center: CGPoint(x: 0, y: 30),
                    width: 40,
                    height: 8,
                    thickness: 3,
                    smile: 0.0,
                    openness: 0.0,
                    viseme: "neutral",
                    mouthWidth: 1.0
                )
            ),
            transform: HeadTransform(),
            appearance: PCPOSFaceProfile.AppearanceSettings(
                colors: PCPOSFaceProfile.AppearanceSettings.ColorPalette(
                    primary: "#00FF00", // Green
                    secondary: "#00CC00",
                    accent: "#00FF88",
                    background: "#000000",
                    glowColor: "#00FF00",
                    glowOpacity: 0.3
                ),
                effects: PCPOSFaceProfile.AppearanceSettings.VisualEffects(
                    glow: PCPOSFaceProfile.AppearanceSettings.VisualEffects.GlowEffect(enabled: true, radius: 15, intensity: 0.3),
                    shadow: PCPOSFaceProfile.AppearanceSettings.VisualEffects.ShadowEffect(enabled: true, color: "#000000", opacity: 0.5, offset: CGPoint(x: 0, y: 4), blur: 8),
                    scanLine: PCPOSFaceProfile.AppearanceSettings.VisualEffects.ScanLineEffect(enabled: true, speed: 2.0, opacity: 0.2)
                )
            ),
            animation: PCPOSFaceProfile.AnimationSettings(
                disney: PCPOSFaceProfile.AnimationSettings.DisneySettings(
                    anticipation: PCPOSFaceProfile.AnimationSettings.DisneySettings.EffectSetting(enabled: true, duration: 0.2, magnitude: 0.15, delay: nil),
                    followThrough: PCPOSFaceProfile.AnimationSettings.DisneySettings.EffectSetting(enabled: true, duration: 0.3, magnitude: nil, delay: 0.1),
                    squashStretch: PCPOSFaceProfile.AnimationSettings.DisneySettings.SquashStretchSetting(enabled: true, maxDeformation: 0.2)
                ),
                timing: PCPOSFaceProfile.AnimationSettings.TimingSettings(
                    autoBlink: PCPOSFaceProfile.AnimationSettings.TimingSettings.IntervalSetting(interval: 4.0, variation: 1.0, maxOffset: nil),
                    saccade: PCPOSFaceProfile.AnimationSettings.TimingSettings.IntervalSetting(interval: 2.5, variation: nil, maxOffset: 0.3)
                )
            ),
            integration: PCPOSFaceProfile.IntegrationSettings(
                dynamicIsland: PCPOSFaceProfile.IntegrationSettings.DynamicIslandConfig(enabled: true, compactSize: CGSize(width: 44, height: 44), expandedSize: CGSize(width: 88, height: 88), scaleFactor: 0.293, backgroundStyle: "system"),
                liveActivity: PCPOSFaceProfile.IntegrationSettings.LiveActivityConfig(enabled: true, updateFrequency: 0.033, maxDuration: 480),
                avFoundation: PCPOSFaceProfile.IntegrationSettings.AVFoundationConfig(faceTrackingEnabled: true, useFrontCamera: true, minFaceSize: 0.1, maxFaces: 1)
            )
        )
    }
    
    // Load from JSON
    func loadProfile(from jsonData: Data) throws {
        let decoder = JSONDecoder()
        self.profile = try decoder.decode(PCPOSFaceProfile.self, from: jsonData)
    }
    
    // Save to JSON
    func saveProfile() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(profile)
    }
    
    // MARK: - Animation Updates
    
    func updateEyeOpenness(_ openness: CGFloat) {
        profile.geometry.eyeLeft.openness = max(0, min(1, openness))
        profile.geometry.eyeRight.openness = max(0, min(1, openness))
    }
    
    func updateGaze(x: CGFloat, y: CGFloat) {
        let gazeOffset = CGPoint(
            x: max(-1, min(1, x)),
            y: max(-1, min(1, y))
        )
        profile.geometry.eyeLeft.gazeOffset = gazeOffset
        profile.geometry.eyeRight.gazeOffset = gazeOffset
    }
    
    func updateSmile(_ smile: CGFloat) {
        profile.geometry.mouth.smile = max(-1, min(1, smile))
    }
    
    func updateMouthOpenness(_ openness: CGFloat) {
        profile.geometry.mouth.openness = max(0, min(1, openness))
    }
    
    func updateHeadRotation(pitch: CGFloat, yaw: CGFloat, roll: CGFloat) {
        profile.transform.rotation.pitch = max(-30, min(30, pitch))
        profile.transform.rotation.yaw = max(-45, min(45, yaw))
        profile.transform.rotation.roll = max(-15, min(15, roll))
    }
    
    // MARK: - Mood & Color Logic
    
    func updateMoodColor(valence: Double, arousal: Double) {
        // Map PAD (Valence/Arousal) to Color Temperature
        // High Valence (Happy) -> Warm/Green
        // Low Valence (Sad) -> Cool/Blue
        // High Arousal (Excited) -> Bright/Intense
        // Low Arousal (Calm) -> Dim/Pastel
        
        let baseColor: ColorComponents
        
        if valence > 0.5 {
            // Happy/Excited -> Green/Yellow
            baseColor = ColorComponents(r: 0.0, g: 1.0, b: 0.0) // Green
        } else if valence < -0.5 {
            // Sad/Angry -> Blue/Red
            if arousal > 0.5 {
                baseColor = ColorComponents(r: 1.0, g: 0.0, b: 0.0) // Red (Angry)
            } else {
                baseColor = ColorComponents(r: 0.0, g: 0.0, b: 1.0) // Blue (Sad)
            }
        } else {
            // Neutral -> Cyan/Teal
            baseColor = ColorComponents(r: 0.0, g: 1.0, b: 1.0)
        }
        
        // Apply intensity based on arousal
        let intensity = CGFloat(max(0.5, min(1.0, arousal + 0.5)))
        
        // Convert to Hex (simplified)
        let hex = String(format: "#%02X%02X%02X",
                         Int(baseColor.r * 255 * intensity),
                         Int(baseColor.g * 255 * intensity),
                         Int(baseColor.b * 255 * intensity))
        
        withAnimation(.easeInOut(duration: 1.0)) {
            profile.appearance.colors.primary = hex
            profile.appearance.colors.glowColor = hex
            profile.appearance.colors.glowOpacity = intensity * 0.5
        }
    }
    
    struct ColorComponents {
        let r: CGFloat
        let g: CGFloat
        let b: CGFloat
    }
}
