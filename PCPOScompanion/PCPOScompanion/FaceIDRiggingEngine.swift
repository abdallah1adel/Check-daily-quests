import SwiftUI
import Combine
import simd

// MARK: - Face ID Animation & Rigging Engine
/// Advanced rigging system for Face ID with hierarchical bones, blend shapes, IK, and Disney principles

// MARK: - Bone Hierarchy System

/// Represents a bone in the facial rig
struct FaceBone: Identifiable, Codable {
    let id: String
    var position: CGPoint
    var rotation: Angle
    var scale: CGSize
    var parentID: String?
    var childrenIDs: [String]
    
    // Animation constraints
    var rotationLimit: ClosedRange<Double> = -45...45
    var scaleLimit: ClosedRange<CGFloat> = 0.5...2.0
    
    // Disney squash & stretch
    var squashAmount: CGFloat = 0.0
    var stretchAmount: CGFloat = 0.0
    
    init(id: String, position: CGPoint, parentID: String? = nil) {
        self.id = id
        self.position = position
        self.rotation = .zero
        self.scale = CGSize(width: 1.0, height: 1.0)
        self.parentID = parentID
        self.childrenIDs = []
    }
    
    /// Calculate world transform (includes parent transforms)
    func worldTransform(parentTransform: CGAffineTransform = .identity) -> CGAffineTransform {
        var transform = CGAffineTransform.identity
        
        // Apply squash & stretch (Disney Principle #1)
        let squashX = 1.0 + squashAmount * 0.3
        let squashY = 1.0 - squashAmount * 0.3
        let stretchX = 1.0 - stretchAmount * 0.2
        let stretchY = 1.0 + stretchAmount * 0.4
        
        transform = transform
            .translatedBy(x: position.x, y: position.y)
            .rotated(by: rotation.radians)
            .scaledBy(x: scale.width * squashX * stretchX, y: scale.height * squashY * stretchY)
            .translatedBy(x: -position.x, y: -position.y)
        
        return transform.concatenating(parentTransform)
    }
}

// MARK: - Face Rig Structure

@MainActor
class FaceIDRig: ObservableObject {
    @Published var bones: [String: FaceBone] = [:]
    @Published var blendShapes: [String: CGFloat] = [:]
    @Published var currentPose: FacePose = .neutral
    
    // Animation layers (stacked for complex expressions)
    @Published var baseLayer: FacePose = .neutral
    @Published var emotionLayer: FacePose = .neutral
    @Published var lipSyncLayer: FacePose = .neutral
    @Published var gestureLayer: FacePose = .neutral
    
    // IK targets
    @Published var gazeTarget: CGPoint = .zero
    @Published var headTarget: CGPoint = .zero
    
    init() {
        setupDefaultRig()
    }
    
    // MARK: - Rig Setup
    
    private func setupDefaultRig() {
        // Root bone (head center)
        let root = FaceBone(id: "root", position: CGPoint(x: 0, y: 0))
        bones["root"] = root
        
        // Head bone (can rotate/tilt)
        let head = FaceBone(id: "head", position: CGPoint(x: 0, y: -20), parentID: "root")
        bones["head"] = head
        
        // Left eye bone
        let leftEye = FaceBone(id: "leftEye", position: CGPoint(x: -30, y: -10), parentID: "head")
        leftEye.rotationLimit = -30...30
        bones["leftEye"] = leftEye
        
        // Right eye bone
        let rightEye = FaceBone(id: "rightEye", position: CGPoint(x: 30, y: -10), parentID: "head")
        rightEye.rotationLimit = -30...30
        bones["rightEye"] = rightEye
        
        // Nose bone (subtle movement)
        let nose = FaceBone(id: "nose", position: CGPoint(x: 0, y: 5), parentID: "head")
        nose.rotationLimit = -5...5
        bones["nose"] = nose
        
        // Mouth bone
        let mouth = FaceBone(id: "mouth", position: CGPoint(x: 0, y: 30), parentID: "head")
        mouth.rotationLimit = -15...15
        bones["mouth"] = mouth
        
        // Update parent-child relationships
        updateHierarchy()
    }
    
    private func updateHierarchy() {
        for (id, bone) in bones {
            if let parentID = bone.parentID {
                bones[parentID]?.childrenIDs.append(id)
            }
        }
    }
    
    // MARK: - Blend Shapes (Morph Targets)
    
    enum BlendShape: String, CaseIterable {
        // Eye shapes
        case eyeOpen = "eyeOpen"
        case eyeClosed = "eyeClosed"
        case eyeSquint = "eyeSquint"
        case eyeWide = "eyeWide"
        
        // Mouth shapes
        case mouthSmile = "mouthSmile"
        case mouthFrown = "mouthFrown"
        case mouthOpen = "mouthOpen"
        case mouthPucker = "mouthPucker"
        case mouthWide = "mouthWide"
        
        // Brow shapes
        case browRaise = "browRaise"
        case browFurrow = "browFurrow"
        
        // Cheek shapes
        case cheekPuff = "cheekPuff"
        case cheekSuck = "cheekSuck"
        
        // Overall expressions
        case happy = "happy"
        case sad = "sad"
        case surprised = "surprised"
        case angry = "angry"
        case neutral = "neutral"
    }
    
    func setBlendShape(_ shape: BlendShape, value: CGFloat) {
        blendShapes[shape.rawValue] = max(0, min(1, value))
        updateFromBlendShapes()
    }
    
    func blendMultipleShapes(_ shapes: [BlendShape: CGFloat]) {
        for (shape, value) in shapes {
            setBlendShape(shape, value: value)
        }
    }
    
    private func updateFromBlendShapes() {
        // Apply blend shapes to bones
        if let eyeOpen = blendShapes[BlendShape.eyeOpen.rawValue] {
            let closed = blendShapes[BlendShape.eyeClosed.rawValue] ?? 0
            let squint = blendShapes[BlendShape.eyeSquint.rawValue] ?? 0
            
            // Left eye
            if var leftEye = bones["leftEye"] {
                let openness = eyeOpen - closed
                leftEye.scale.height = 0.1 + openness * 0.9
                leftEye.squashAmount = squint * 0.5
                bones["leftEye"] = leftEye
            }
            
            // Right eye
            if var rightEye = bones["rightEye"] {
                let openness = eyeOpen - closed
                rightEye.scale.height = 0.1 + openness * 0.9
                rightEye.squashAmount = squint * 0.5
                bones["rightEye"] = rightEye
            }
        }
        
        // Mouth blend shapes
        if let smile = blendShapes[BlendShape.mouthSmile.rawValue] {
            if var mouth = bones["mouth"] {
                mouth.rotation = .degrees(smile * 15 - (blendShapes[BlendShape.mouthFrown.rawValue] ?? 0) * 15)
                mouth.scale.width = 1.0 + smile * 0.3
                bones["mouth"] = mouth
            }
        }
        
        if let open = blendShapes[BlendShape.mouthOpen.rawValue] {
            if var mouth = bones["mouth"] {
                mouth.scale.height = 0.3 + open * 0.7
                mouth.stretchAmount = open * 0.4
                bones["mouth"] = mouth
            }
        }
    }
    
    // MARK: - Inverse Kinematics (IK)
    
    /// Solve IK for gaze tracking (eyes look at target)
    func solveGazeIK(target: CGPoint, maxDistance: CGFloat = 100) {
        let headPos = bones["head"]?.position ?? .zero
        
        // Calculate direction to target
        let direction = CGPoint(
            x: target.x - headPos.x,
            y: target.y - headPos.y
        )
        
        let distance = sqrt(direction.x * direction.x + direction.y * direction.y)
        let clampedDistance = min(distance, maxDistance)
        
        // Normalize direction
        let normalized = CGPoint(
            x: direction.x / max(distance, 0.001),
            y: direction.y / max(distance, 0.001)
        )
        
        // Calculate rotation angle
        let angle = atan2(normalized.y, normalized.x)
        
        // Apply to both eyes (with slight offset for convergence)
        let convergence = min(clampedDistance / maxDistance, 0.3)
        
        if var leftEye = bones["leftEye"] {
            leftEye.rotation = .radians(angle - convergence * 0.1)
            bones["leftEye"] = leftEye
        }
        
        if var rightEye = bones["rightEye"] {
            rightEye.rotation = .radians(angle + convergence * 0.1)
            bones["rightEye"] = rightEye
        }
    }
    
    /// Solve IK for head rotation (look at target)
    func solveHeadIK(target: CGPoint) {
        guard var head = bones["head"] else { return }
        
        let rootPos = bones["root"]?.position ?? .zero
        let direction = CGPoint(
            x: target.x - rootPos.x,
            y: target.y - rootPos.y
        )
        
        let angle = atan2(direction.y, direction.x)
        
        // Limit rotation
        let limitedAngle = max(-45, min(45, angle * 180 / .pi))
        head.rotation = .degrees(limitedAngle)
        
        bones["head"] = head
    }
    
    // MARK: - Animation Layers
    
    struct FacePose: Codable {
        var headRotation: Angle = .zero
        var headTilt: Angle = .zero
        var eyeOpenness: CGFloat = 1.0
        var eyeSquint: CGFloat = 0.0
        var mouthSmile: CGFloat = 0.0
        var mouthOpen: CGFloat = 0.0
        var browRaise: CGFloat = 0.0
        
        static let neutral = FacePose()
    }
    
    /// Blend all animation layers into final pose
    func blendLayers() {
        // Weighted blend of all layers
        let baseWeight: CGFloat = 0.3
        let emotionWeight: CGFloat = 0.4
        let lipSyncWeight: CGFloat = 0.2
        let gestureWeight: CGFloat = 0.1
        
        currentPose = FacePose(
            headRotation: blendAngle(
                baseLayer.headRotation * baseWeight +
                emotionLayer.headRotation * emotionWeight +
                lipSyncLayer.headRotation * lipSyncWeight +
                gestureLayer.headRotation * gestureWeight
            ),
            headTilt: blendAngle(
                baseLayer.headTilt * baseWeight +
                emotionLayer.headTilt * emotionWeight +
                lipSyncLayer.headTilt * lipSyncWeight +
                gestureLayer.headTilt * gestureWeight
            ),
            eyeOpenness: blendValue(
                baseLayer.eyeOpenness * baseWeight +
                emotionLayer.eyeOpenness * emotionWeight +
                lipSyncLayer.eyeOpenness * lipSyncWeight +
                gestureLayer.eyeOpenness * gestureWeight
            ),
            eyeSquint: blendValue(
                baseLayer.eyeSquint * baseWeight +
                emotionLayer.eyeSquint * emotionWeight +
                lipSyncLayer.eyeSquint * lipSyncWeight +
                gestureLayer.eyeSquint * gestureWeight
            ),
            mouthSmile: blendValue(
                baseLayer.mouthSmile * baseWeight +
                emotionLayer.mouthSmile * emotionWeight +
                lipSyncLayer.mouthSmile * lipSyncWeight +
                gestureLayer.mouthSmile * gestureWeight
            ),
            mouthOpen: blendValue(
                baseLayer.mouthOpen * baseWeight +
                emotionLayer.mouthOpen * emotionWeight +
                lipSyncLayer.mouthOpen * lipSyncWeight +
                gestureLayer.mouthOpen * gestureWeight
            ),
            browRaise: blendValue(
                baseLayer.browRaise * baseWeight +
                emotionLayer.browRaise * emotionWeight +
                lipSyncLayer.browRaise * lipSyncWeight +
                gestureLayer.browRaise * gestureWeight
            )
        )
        
        applyPoseToBones()
    }
    
    private func blendAngle(_ angle: Angle) -> Angle {
        // Normalize angle to -180...180 range
        let degrees = angle.degrees
        let normalized = ((degrees + 180).truncatingRemainder(dividingBy: 360) - 180)
        return .degrees(normalized)
    }
    
    private func blendValue(_ value: CGFloat) -> CGFloat {
        return max(0, min(1, value))
    }
    
    private func applyPoseToBones() {
        // Apply current pose to bone hierarchy
        if var head = bones["head"] {
            head.rotation = currentPose.headRotation
            bones["head"] = head
        }
        
        // Update blend shapes from pose
        setBlendShape(.eyeOpen, value: currentPose.eyeOpenness)
        setBlendShape(.eyeSquint, value: currentPose.eyeSquint)
        setBlendShape(.mouthSmile, value: currentPose.mouthSmile)
        setBlendShape(.mouthOpen, value: currentPose.mouthOpen)
        setBlendShape(.browRaise, value: currentPose.browRaise)
    }
    
    // MARK: - Disney Animation Principles
    
    /// Apply anticipation (Disney Principle #2)
    func applyAnticipation(direction: AnticipationDirection, amount: CGFloat) {
        guard var head = bones["head"] else { return }
        
        let anticipationOffset: CGPoint
        switch direction {
        case .up:
            anticipationOffset = CGPoint(x: 0, y: amount * 5)
        case .down:
            anticipationOffset = CGPoint(x: 0, y: -amount * 5)
        case .left:
            anticipationOffset = CGPoint(x: amount * 5, y: 0)
        case .right:
            anticipationOffset = CGPoint(x: -amount * 5, y: 0)
        }
        
        head.position.x += anticipationOffset.x
        head.position.y += anticipationOffset.y
        bones["head"] = head
    }
    
    /// Apply follow-through (Disney Principle #5)
    func applyFollowThrough(boneID: String, velocity: CGPoint, damping: CGFloat = 0.9) {
        guard var bone = bones[boneID] else { return }
        
        // Apply velocity with damping
        bone.position.x += velocity.x * (1 - damping)
        bone.position.y += velocity.y * (1 - damping)
        
        // Clamp to limits
        bone.position.x = max(-50, min(50, bone.position.x))
        bone.position.y = max(-50, min(50, bone.position.y))
        
        bones[boneID] = bone
    }
    
    /// Apply exaggeration (Disney Principle #10)
    func applyExaggeration(factor: CGFloat) {
        for (id, var bone) in bones {
            bone.scale.width *= (1.0 + factor * 0.2)
            bone.scale.height *= (1.0 + factor * 0.2)
            bone.rotation.degrees *= (1.0 + factor * 0.3)
            bones[id] = bone
        }
    }
    
    enum AnticipationDirection {
        case up, down, left, right
    }
    
    // MARK: - Constraints
    
    /// Apply physics-based constraints to prevent unrealistic deformation
    func applyConstraints() {
        for (id, var bone) in bones {
            // Rotation limits
            let clampedRotation = max(bone.rotationLimit.lowerBound, min(bone.rotationLimit.upperBound, bone.rotation.degrees))
            bone.rotation = .degrees(clampedRotation)
            
            // Scale limits
            bone.scale.width = max(bone.scaleLimit.lowerBound, min(bone.scaleLimit.upperBound, bone.scale.width))
            bone.scale.height = max(bone.scaleLimit.lowerBound, min(bone.scaleLimit.upperBound, bone.scale.height))
            
            // Volume preservation (squash & stretch)
            let volume = bone.scale.width * bone.scale.height
            if volume > 1.5 {
                let factor = sqrt(1.5 / volume)
                bone.scale.width *= factor
                bone.scale.height *= factor
            }
            
            bones[id] = bone
        }
    }
    
    // MARK: - Real-time Update Loop
    
    func update(deltaTime: TimeInterval) {
        // Solve IK
        solveGazeIK(target: gazeTarget)
        solveHeadIK(target: headTarget)
        
        // Blend animation layers
        blendLayers()
        
        // Apply constraints
        applyConstraints()
    }
}

// MARK: - Face ID Rigging View

struct FaceIDRiggedView: View {
    @ObservedObject var rig: FaceIDRig
    @ObservedObject var faceModel: PCPOSFaceModel
    
    var body: some View {
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            
            ZStack {
                // Draw bones in hierarchy order
                ForEach(Array(rig.bones.values.sorted(by: { $0.id < $1.id })), id: \.id) { bone in
                    boneView(for: bone, in: geo.size, center: center)
                }
            }
        }
    }
    
    @ViewBuilder
    private func boneView(for bone: FaceBone, in size: CGSize, center: CGPoint) -> some View {
        let transform = bone.worldTransform()
        let position = CGPoint(
            x: center.x + bone.position.x,
            y: center.y + bone.position.y
        )
        
        Group {
            switch bone.id {
            case "head":
                headBoneView(bone: bone, position: position, transform: transform)
            case "leftEye", "rightEye":
                eyeBoneView(bone: bone, position: position, transform: transform)
            case "mouth":
                mouthBoneView(bone: bone, position: position, transform: transform)
            case "nose":
                noseBoneView(bone: bone, position: position, transform: transform)
            default:
                EmptyView()
            }
        }
        .transformEffect(transform)
    }
    
    @ViewBuilder
    private func headBoneView(bone: FaceBone, position: CGPoint, transform: CGAffineTransform) -> some View {
        // Face ID Brackets
        FaceIDBrackets()
            .fill(Color(hex: faceModel.profile.appearance.colors.primary))
            .frame(width: 180, height: 180)
            .position(position)
    }
    
    @ViewBuilder
    private func eyeBoneView(bone: FaceBone, position: CGPoint, transform: CGAffineTransform) -> some View {
        let openness = rig.blendShapes[FaceIDRig.BlendShape.eyeOpen.rawValue] ?? 1.0
        let squint = rig.blendShapes[FaceIDRig.BlendShape.eyeSquint.rawValue] ?? 0.0
        
        if bone.id == "leftEye" {
            PCPOSLeftEye(blink: openness, squint: squint, excitement: 0.0)
                .fill(Color(hex: faceModel.profile.appearance.colors.primary))
                .frame(width: 25, height: 30)
                .position(position)
        } else {
            PCPOSRightEye(blink: openness, squint: squint, excitement: 0.0)
                .fill(Color(hex: faceModel.profile.appearance.colors.primary))
                .frame(width: 25, height: 30)
                .position(position)
        }
    }
    
    @ViewBuilder
    private func mouthBoneView(bone: FaceBone, position: CGPoint, transform: CGAffineTransform) -> some View {
        let smile = rig.blendShapes[FaceIDRig.BlendShape.mouthSmile.rawValue] ?? 0.0
        let open = rig.blendShapes[FaceIDRig.BlendShape.mouthOpen.rawValue] ?? 0.0
        
        PCPOSDisneyMouth(smile: smile, open: open, exaggeration: 0.0)
            .fill(Color(hex: faceModel.profile.appearance.colors.primary))
            .frame(width: 40, height: 8)
            .position(position)
    }
    
    @ViewBuilder
    private func noseBoneView(bone: FaceBone, position: CGPoint, transform: CGAffineTransform) -> some View {
        Circle()
            .fill(Color(hex: faceModel.profile.appearance.colors.primary).opacity(0.5))
            .frame(width: 4, height: 6)
            .position(position)
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

