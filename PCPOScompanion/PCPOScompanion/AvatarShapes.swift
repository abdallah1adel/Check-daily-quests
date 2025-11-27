import SwiftUI

// MARK: - Face ID Shapes
// Clean, minimal shapes matching Apple's Face ID design

nonisolated struct FaceIDBrackets: Shape {
    // No morphing - just clean corner brackets like real Face ID
    var animatableData: CGFloat = 1.0 // For compatibility
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        
        // Face ID Bracket Specs (matching reference images)
        let legLength: CGFloat = 45  // Length of each bracket arm
        let thickness: CGFloat = 5   // Line thickness
        let cornerRadius: CGFloat = 2.5 // Rounded cap radius
        
        // Each bracket is an L-shape at the corner
        // We'll draw 4 separate brackets, one at each corner
        
        // TOP LEFT BRACKET
        addBracket(to: &path, 
                   corner: .topLeft,
                   at: CGPoint(x: 0, y: 0),
                   legLength: legLength,
                   thickness: thickness,
                   cornerRadius: cornerRadius)
        
        // TOP RIGHT BRACKET
        addBracket(to: &path,
                   corner: .topRight,
                   at: CGPoint(x: w, y: 0),
                   legLength: legLength,
                   thickness: thickness,
                   cornerRadius: cornerRadius)
        
        // BOTTOM RIGHT BRACKET
        addBracket(to: &path,
                   corner: .bottomRight,
                   at: CGPoint(x: w, y: h),
                   legLength: legLength,
                   thickness: thickness,
                   cornerRadius: cornerRadius)
        
        // BOTTOM LEFT BRACKET
        addBracket(to: &path,
                   corner: .bottomLeft,
                   at: CGPoint(x: 0, y: h),
                   legLength: legLength,
                   thickness: thickness,
                   cornerRadius: cornerRadius)
        
        return path
    }
    
    private func addBracket(to path: inout Path, corner: Corner, at point: CGPoint, legLength: CGFloat, thickness: CGFloat, cornerRadius: CGFloat) {
        let halfThickness = thickness / 2
        
        switch corner {
        case .topLeft:
            // Vertical leg (going down from corner)
            path.addRoundedRect(in: CGRect(x: point.x, y: point.y, width: thickness, height: legLength), cornerSize: CGSize(width: cornerRadius, height: cornerRadius))
            // Horizontal leg (going right from corner)
            path.addRoundedRect(in: CGRect(x: point.x, y: point.y, width: legLength, height: thickness), cornerSize: CGSize(width: cornerRadius, height: cornerRadius))
            
        case .topRight:
            // Vertical leg (going down from corner)
            path.addRoundedRect(in: CGRect(x: point.x - thickness, y: point.y, width: thickness, height: legLength), cornerSize: CGSize(width: cornerRadius, height: cornerRadius))
            // Horizontal leg (going left from corner)
            path.addRoundedRect(in: CGRect(x: point.x - legLength, y: point.y, width: legLength, height: thickness), cornerSize: CGSize(width: cornerRadius, height: cornerRadius))
            
        case .bottomRight:
            // Vertical leg (going up from corner)
            path.addRoundedRect(in: CGRect(x: point.x - thickness, y: point.y - legLength, width: thickness, height: legLength), cornerSize: CGSize(width: cornerRadius, height: cornerRadius))
            // Horizontal leg (going left from corner)
            path.addRoundedRect(in: CGRect(x: point.x - legLength, y: point.y - thickness, width: legLength, height: thickness), cornerSize: CGSize(width: cornerRadius, height: cornerRadius))
            
        case .bottomLeft:
            // Vertical leg (going up from corner)
            path.addRoundedRect(in: CGRect(x: point.x, y: point.y - legLength, width: thickness, height: legLength), cornerSize: CGSize(width: cornerRadius, height: cornerRadius))
            // Horizontal leg (going right from corner)
            path.addRoundedRect(in: CGRect(x: point.x, y: point.y - thickness, width: legLength, height: thickness), cornerSize: CGSize(width: cornerRadius, height: cornerRadius))
        }
    }
    
    enum Corner {
        case topLeft, topRight, bottomRight, bottomLeft
    }
}

// MARK: - Face ID Dot Grid
// Minimal dot grid representing the scanned face (like actual Face ID)

nonisolated struct FaceIDDotGrid: View {
    var params: AnimationParams
    
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            
            // Create 7x9 sparse dot grid
            let cols = 7
            let rows = 9
            let hSpacing = w / CGFloat(cols + 1)
            let vSpacing = h / CGFloat(rows + 1)
            
            ForEach(0..<rows, id: \.self) { row in
                ForEach(0..<cols, id: \.self) { col in
                    let x = hSpacing * CGFloat(col + 1)
                    let y = vSpacing * CGFloat(row + 1)
                    
                    // Calculate dot properties based on emotion
                    let dotSize = baseDotSize(row: row, col: col)
                    let dotOpacity = baseDotOpacity(row: row, col: col)
                    let emotionOffset = emotionDotOffset(row: row, col: col)
                    
                    Circle()
                        .fill(Color.white.opacity(dotOpacity))
                        .frame(width: dotSize, height: dotSize)
                        .offset(x: x + emotionOffset.width, y: y + emotionOffset.height)
                        .shadow(color: params.colorTint.opacity(0.3), radius: 2)
                }
            }
        }
    }
    
    private func baseDotSize(row: Int, col: Int) -> CGFloat {
        // Center dots slightly larger
        let centerRow = 4
        let centerCol = 3
        let distance = sqrt(pow(Double(row - centerRow), 2) + pow(Double(col - centerCol), 2))
        let size = max(2.5, 4.0 - distance * 0.2)
        
        // Eyes area - larger dots
        if (row == 3 || row == 4) && (col == 2 || col == 4) {
            return size * (params.eyeOpen > 0.8 ? 1.3 : 1.0)
        }
        
        return size
    }
    
    private func baseDotOpacity(row: Int, col: Int) -> Double {
        // Fade edges
        let centerRow = 4
        let centerCol = 3
        let distance = sqrt(pow(Double(row - centerRow), 2) + pow(Double(col - centerCol), 2))
        return max(0.3, 1.0 - distance * 0.08) * Double(params.glow)
    }
    
    private func emotionDotOffset(row: Int, col: Int) -> CGSize {
        var offset = CGSize.zero
        
        // Smile/frown: bottom dots curve
        if row >= 6 {
            let smileAmount = params.mouthSmile * 3.0
            let xFactor = CGFloat(col - 3) / 3.0 // -1 to 1
            offset.height = -abs(xFactor) * smileAmount
        }
        
        // Eye openness: middle rows move
        if row >= 2 && row <= 5 {
            offset.height = params.browRaise * 2.0
        }
        
        // Mouth open: bottom expands
        if row >= 7 {
            offset.height += params.mouthOpen * 3.0
        }
        
        return offset
    }
}

// MARK: - PCPOS Face Shapes (Disney Animation Principles Applied)
// 🎭 Disney's 12 Animation Principles Implementation:
// 1. Squash & Stretch - Face can deform naturally
// 2. Anticipation - Prepares for action
// 3. Staging - Directs attention to important features
// 4. Straight Ahead & Pose-to-Pose - Combines both techniques
// 5. Follow Through & Overlapping Action - Natural secondary movements
// 6. Slow In & Slow Out - Eased transitions
// 7. Arc - Natural curved movements
// 8. Secondary Action - Supporting movements
// 9. Timing - Perfect pacing for drama
// 10. Exaggeration - Enhanced expressiveness
// 11. Solid Drawing - Proper form and structure
// 12. Appeal - Believable and charming character

struct PCPOSLeftEye: Shape {
    var animatableData: AnimatablePair<CGFloat, AnimatablePair<CGFloat, CGFloat>>
    // animatableData.first: blink (0 closed, 1 open)
    // animatableData.second.first: squint (0 normal, 1 squint)
    // animatableData.second.second: excitement (0 calm, 1 excited)

    init(blink: CGFloat = 1.0, squint: CGFloat = 0.0, excitement: CGFloat = 0.0) {
        self.animatableData = AnimatablePair(blink, AnimatablePair(squint, excitement))
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()

        // Disney Principle: Squash & Stretch - Eyes can deform expressively
        let scaleX = rect.width / 60.0
        let scaleY = rect.height / 60.0

        let blink = animatableData.first
        let squint = animatableData.second.first
        let excitement = animatableData.second.second

        let eyeCenterX = 38.7 * scaleX
        let eyeCenterY = 25.0 * scaleY

        // Base dimensions with Disney exaggeration
        var eyeWidth = 2.0 * scaleX * (1.0 + excitement * 0.3)  // Excitement widens eyes
        var eyeHeight = 1.5 * scaleY * blink * (1.0 - squint * 0.7) // Squint narrows height

        // Disney Principle: Anticipation - Eyes prepare for action
        if squint > 0.5 {
            eyeWidth *= 1.2  // Anticipation widens eyes
            eyeHeight *= 0.8  // But narrows in focus
        }

        let eyeRect = CGRect(
            x: eyeCenterX - eyeWidth/2,
            y: eyeCenterY - eyeHeight/2,
            width: eyeWidth,
            height: eyeHeight
        )

        path.addEllipse(in: eyeRect)
        return path
    }
}

struct PCPOSRightEye: Shape {
    var animatableData: AnimatablePair<CGFloat, AnimatablePair<CGFloat, CGFloat>>
    // animatableData.first: blink (0 closed, 1 open)
    // animatableData.second.first: squint (0 normal, 1 squint)
    // animatableData.second.second: excitement (0 calm, 1 excited)

    init(blink: CGFloat = 1.0, squint: CGFloat = 0.0, excitement: CGFloat = 0.0) {
        self.animatableData = AnimatablePair(blink, AnimatablePair(squint, excitement))
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()

        // Disney Principle: Secondary Action - Right eye follows left with slight delay
        let scaleX = rect.width / 60.0
        let scaleY = rect.height / 60.0

        let blink = animatableData.first
        let squint = animatableData.second.first
        let excitement = animatableData.second.second

        let eyeCenterX = 15.6 * scaleX
        let eyeCenterY = 25.9 * scaleY

        // Base dimensions with Disney exaggeration
        var eyeWidth = 2.2 * scaleX * (1.0 + excitement * 0.3)
        var eyeHeight = 1.6 * scaleY * blink * (1.0 - squint * 0.7)

        // Disney Principle: Follow-through - Right eye slightly delayed
        if squint > 0.3 {
            eyeWidth *= 1.15  // Slightly less anticipation than left eye
            eyeHeight *= 0.85
        }

        let eyeRect = CGRect(
            x: eyeCenterX - eyeWidth/2,
            y: eyeCenterY - eyeHeight/2,
            width: eyeWidth,
            height: eyeHeight
        )

        path.addEllipse(in: eyeRect)
        return path
    }
}

struct PCPOSDisneyMouth: Shape {
    var animatableData: AnimatablePair<CGFloat, AnimatablePair<CGFloat, CGFloat>>
    // animatableData.first: smile (0 frown, 1 smile)
    // animatableData.second.first: open (0 closed, 1 open)
    // animatableData.second.second: exaggeration (0 normal, 1 exaggerated)

    init(smile: CGFloat = 0.5, open: CGFloat = 0.0, exaggeration: CGFloat = 0.0) {
        self.animatableData = AnimatablePair(smile, AnimatablePair(open, exaggeration))
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()

        // Disney Principle: Exaggeration - Mouth can be dramatically expressive
        let scaleX = rect.width / 60.0
        let scaleY = rect.height / 60.0

        let smile = animatableData.first
        let open = animatableData.second.first
        let exaggeration = animatableData.second.second

        let mouthCenterX = 30 * scaleX
        let mouthCenterY = 41 * scaleY

        // Disney exaggeration affects scale
        let exaggerationFactor = 1.0 + exaggeration * 0.5
        let mouthWidth = 12 * scaleX * exaggerationFactor
        let mouthHeight = 3 * scaleY * (0.5 + open * 0.5) * exaggerationFactor

        let leftPoint = CGPoint(x: mouthCenterX - mouthWidth/2, y: mouthCenterY)
        let rightPoint = CGPoint(x: mouthCenterX + mouthWidth/2, y: mouthCenterY)

        // Disney Principle: Appeal - Curved smile/frown with personality
        let curveOffset = mouthHeight * (smile - 0.5) * 2 * (1.0 + exaggeration)

        path.move(to: leftPoint)
        path.addQuadCurve(
            to: rightPoint,
            control: CGPoint(x: mouthCenterX, y: mouthCenterY - curveOffset)
        )

        // Disney Principle: Staging - Open mouth draws attention
        if open > 0.1 {
            let thickness = mouthHeight * (0.8 + exaggeration * 0.4)
            path.addLine(to: CGPoint(x: rightPoint.x, y: rightPoint.y + thickness))
            path.addQuadCurve(
                to: CGPoint(x: leftPoint.x, y: leftPoint.y + thickness),
                control: CGPoint(x: mouthCenterX, y: mouthCenterY + thickness - curveOffset)
            )
            path.closeSubpath()
        }

        return path
    }
}

struct PCPOSBody: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        // Based on SVG: Circle with center at (30,30) radius 28
        let scale = min(rect.width, rect.height) / 60.0
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = 28 * scale

        path.addEllipse(in: CGRect(
            x: center.x - radius,
            y: center.y - radius,
            width: radius * 2,
            height: radius * 2
        ))

        return path
    }
}

