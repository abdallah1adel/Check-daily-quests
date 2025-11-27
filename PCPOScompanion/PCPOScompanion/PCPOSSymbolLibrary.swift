import SwiftUI

/// Massive SF Symbols Library (20X Expansion)
/// 200+ symbols organized by emotion and activity
struct PCPOSSymbolLibrary {
    
    // MARK: - Symbol Collections (20X Expansion)
    
    static let symbols: [String: [String]] = [
        // HAPPY (25 symbols)
        "HAPPY": [
            "face.smiling.inverse", "sun.max.fill", "sparkles", "star.fill", "heart.fill",
            "face.smiling", "sun.max", "star.circle.fill", "heart.circle.fill", "gift.fill",
            "balloon.fill", "party.popper.fill", "crown.fill", "lanyardcard.fill", "hand.thumbsup.fill",
            "music.note", "headphones", "gamecontroller.fill", "trophy.fill", "medal.fill",
            "checkmark.seal.fill", "leaf.fill", "bubble.left.and.bubble.right.fill", "hands.sparkles.fill", "hand.wave.fill"
        ],
        
        // SAD (25 symbols)
        "SAD": [
            "cloud.rain.fill", "face.dashed", "drop.fill", "cloud.fill", "cloud.drizzle.fill",
            "cloud.heavyrain.fill", "cloud.bolt.rain.fill", "umbrella.fill", "wind", "leaf.arrow.triangle.circlepath",
            "moon.fill", "moon.stars.fill", "cloud.moon.rain.fill", "snowflake", "cloud.snow.fill",
            "smoke.fill", "aqi.low", "heart.slash.fill", "xmark.seal.fill", "hand.thumbsdown.fill",
            "figure.walk", "battery.0percent", "moon.zzz.fill", "zzz", "bed.double.fill"
        ],
        
        // EXCITED (25 symbols)
        "EXCITED": [
            "bolt.heart.fill", "bolt.fill", "sparkles", "star.leadinghalf.fill", "eyes.inverse",
            "exclamationmark.2", "exclamationmark.3", "arrow.up.right.circle.fill", "flame.fill", "sun.max.fill",
            "light.beacon.max.fill", "lightbulb.fill", "fireworks", "party.popper.fill", "gift.fill",
            "trophy.fill", "medal.fill", "crown.fill", "star.circle.fill", "sparkle.magnifyingglass",
            "wand.and.stars", "wand.and.rays", "moon.stars.fill", "theatermasks.fill", "ticket.fill"
        ],
        
        // ANGRY (25 symbols)
        "ANGRY": [
            "flame.fill", "exclamationmark.triangle.fill", "bolt.fill", "smoke.fill", "tornado",
            "hurricane", "tropicalstorm", "flame.circle.fill", "bolt.circle.fill", "exclamationmark.octagon.fill",
            "hand.raised.fill", "xmark.shield.fill", "xmark.octagon.fill", "slash.circle.fill", "nosign",
            "exclamationmark.square.fill", "exclamationmark.bubble.fill", "cloud.bolt.fill", "cloud.bolt.rain.fill", "allergens",
            "burst.fill", "cross.fill", "minus.circle.fill", "hand.point.up.left.fill", "figure.walk.arrival"
        ],
        
        // SURPRISED (25 symbols)
        "SURPRISED": [
            "sparkles", "eyes", "exclamationmark.circle.fill", "questionmark.circle.fill", "lightbulb.max.fill",
            "star.circle.fill", "sparkle.magnifyingglass", "exclamationmark.2", "questionmark.bubble.fill", "brain.head.profile",
            "eye.fill", "eye.circle.fill", "eye.trianglebadge.exclamationmark.fill", "light.beacon.max.fill", "antenna.radiowaves.left.and.right",
            "dot.radiowaves.left.and.right", "wave.3.forward.circle.fill", "waveform.circle.fill", "dot.scope", "scope",
            "chart.line.uptrend.xyaxis.circle.fill", "arrow.up.forward.circle.fill", "arrow.up.circle.fill", "arrowshape.up.fill", "fireworks"
        ],
        
        // CALM (25 symbols)
        "CALM": [
            "moon.stars.fill", "moon.fill", "cloud.fill", "leaf.fill", "wind",
            "water.waves", "drop.fill", "snowflake", "sparkles", "circle.hexagongrid.fill",
            "aqi.medium", "humidity.fill", "moon.zzz.fill", "bed.double.fill", "heart.fill",
            "circle.grid.cross.fill", "circle.dotted", "moonphase.full.moon", "cloud.moon.fill", "sun.dust.fill",
            "sun.haze.fill", "sun.rain.fill", "beach.umbrella.fill", "figure.yoga", "figure.mind.and.body"
        ],
        
        // THINKING (25 symbols)
        "THINKING": [
            "brain.head.profile", "lightbulb.fill", "questionmark.bubble.fill", "ellipsis.bubble.fill", "brain",
            "gearshape.fill", "gearshape.2.fill", "cpu.fill", "memorychip.fill", "chart.bar.fill",
            "chart.line.uptrend.xyaxis", "magnifyingglass.circle.fill", "doc.text.magnifyingglass", "book.fill", "books.vertical.fill",
            "text.book.closed.fill", "graduationcap.fill", "studentdesk", "puzzlepiece.fill", "puzzlepiece.extension.fill",
            "scope", "target", "chart.xyaxis.line", "function", "sum"
        ],
        
        // CONFUSED (25 symbols)
        "CONFUSED": [
            "questionmark.bubble.fill", "questionmark.circle.fill", "questionmark.square.fill", "questionmark.diamond.fill", "questionmark",
            "exclamationmark.questionmark", "exclamationmark.triangle.fill", "arrow.triangle.swap", "arrow.left.arrow.right.circle.fill", "arrow.clockwise.circle.fill",
            "arrow.counterclockwise.circle.fill", "arrow.uturn.backward.circle.fill", "arrow.uturn.forward.circle.fill", "arrow.turn.up.left", "arrow.turn.up.right",
            "gyroscope", "dial.medium.fill", "gauge.with.needle.fill", "speedometer", "timer",
            "hourglass", "clock.arrow.circlepath", "gobackward", "goforward", "shuffle.circle.fill"
        ],
        
        // PLAYFUL (25 symbols)
        "PLAYFUL": [
            "gamecontroller.fill", "dice.fill", "paintbrush.fill", "paintpalette.fill", "pencil.and.scribble",
            "theatermasks.fill", "balloon.fill", "party.popper.fill", "gift.fill", "birthday.cake.fill",
            "teddybear.fill", "hare.fill", "tortoise.fill", "bird.fill", "fish.fill",
            "ladybug.fill", "lizard.fill", "pawprint.fill", "pawprint.circle.fill", "leaf.arrow.circlepath",
            "figure.play", "figure.run", "figure.roll", "figure.dance", "musical.note.list"
        ],
        
        // CONFIDENT (25 symbols)
        "CONFIDENT": [
            "shield.lefthalf.filled", "crown.fill", "checkmark.shield.fill", "checkmark.seal.fill", "medal.fill",
            "trophy.fill", "flag.fill", "flag.checkered", "star.fill", "rosette",
            "checkmark.circle.fill", "hand.thumbsup.fill", "hand.raised.fill", "figure.stand", "figure.arms.open",
            "plus.circle.fill", "arrow.up.circle.fill", "arrowshape.up.fill", "chevron.up.circle.fill", "arrow.up.right.circle.fill",
            "chart.line.uptrend.xyaxis.circle.fill", "increase.quotelevel", "amplifier", "speaker.wave.3.fill", "megaphone.fill"
        ]
    ]
    
    // MARK: - Color Palettes
    
    static let colorPalettes: [String: [Color]] = [
        "HAPPY": [.yellow, .orange, .green, Color(hex: "37C058")],
        "SAD": [.blue, .purple, .cyan, Color(hex: "4A90E2")],
        "EXCITED": [.orange, .red, .yellow, Color(hex: "FF6B35")],
        "ANGRY": [.red, .black, Color(hex: "8B0000"), Color(hex: "FF4500")],
        "SURPRISED": [.purple, .yellow, .pink, Color(hex: "FF69B4")],
        "CALM": [.cyan, Color(hex: "87CEEB"), Color(hex: "B0E0E6"), Color(hex: "37C058").opacity(0.6)],
        "THINKING": [.indigo, .purple, Color(hex: "6A5ACD"), Color(hex: "483D8B")],
        "CONFUSED": [.mint, .teal, Color(hex: "40E0D0"), Color(hex: "20B2AA")],
        "PLAYFUL": [.pink, .orange, .yellow, Color(hex: "FF1493")],
        "CONFIDENT": [Color(hex: "37C058"), .green, Color(hex: "228B22"), Color(hex: "32CD32")]
    ]
    
    // MARK: - Dynamic Selection
    
    static func symbolFor(emotion: String, intensity: Double, speaking: Bool) -> String {
        let emotionSymbols = symbols[emotion] ?? symbols["CALM"]!
        
        if speaking {
            // Pick from first third (more active symbols)
            let activeRange = 0..<(emotionSymbols.count / 3)
            let index = min(Int(intensity * Double(activeRange.count)), activeRange.count - 1)
            return emotionSymbols[activeRange.lowerBound + index]
        } else {
            // Pick based on intensity across full range
            let index = min(Int(intensity * Double(emotionSymbols.count)), emotionSymbols.count - 1)
            return emotionSymbols[index]
        }
    }
    
    static func colorFor(emotion: String, intensity: Double) -> Color {
        let colors = colorPalettes[emotion] ?? colorPalettes["CALM"]!
        let index = min(Int(intensity * Double(colors.count)), colors.count - 1)
        return colors[index]
    }
}

// MARK: - Color Extension (Hex Support)

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
