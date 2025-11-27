import SwiftUI

// MARK: - Face ID State Machine (Multi-Layer)

enum FaceIDState: Equatable {
    case locked(LockSubState)
    case scanning(ScanSubState)
    case unlocked(UnlockSubState)
    
    enum LockSubState {
        case idle
        case tapReady
        case wiggling
        case alerting
    }
    
    enum ScanSubState {
        case initializing
        case pulsingOrb
        case analyzing
        case verifying
    }
    
    enum UnlockSubState {
        case success
        case confetti
        case celebration
        case settling
    }
}

// MARK: - Massive Symbol Library (300+ Symbols)

struct FaceIDSymbolLibrary {
    
    // MARK: LOCKED STATE (100 Symbols)
    
    static let lockedSymbols: [String: [String]] = [
        "core": [
            "lock.fill", "lock.circle.fill", "lock.square.fill", "lock.rectangle.fill",
            "lock.shield.fill", "lock.trianglebadge.exclamationmark.fill", "lock.open.fill",
            "key.fill", "key.horizontal.fill", "person.badge.key.fill"
        ],
        "security": [
            "shield.fill", "shield.lefthalf.filled", "shield.righthalf.filled", "shield.checkered",
            "checkmark.shield.fill", "xmark.shield.fill", "exclamationmark.shield.fill",
            "lock.shield.fill", "person.fill.checkmark", "person.fill.xmark"
        ],
        "face": [
            "face.smiling", "face.dashed", "faceid", "facemask.fill", "eyes.inverse",
            "eye.fill", "eye.slash.fill", "eye.trianglebadge.exclamationmark.fill",
            "brain.head.profile", "head.profile.arrow.forward.and.visionpro"
        ],
        "alert": [
            "exclamationmark.triangle.fill", "exclamationmark.circle.fill", "exclamationmark.octagon.fill",
            "bell.fill", "bell.badge.fill", "light.beacon.max.fill", "light.beacon.min.fill",
            "speaker.wave.3.fill", "antenna.radiowaves.left.and.right", "wifi.exclamationmark"
        ],
        "access": [
            "door.left.hand.closed", "door.right.hand.closed", "entry.lever.keypad.fill",
            "hand.raised.fill", "hand.point.up.left.fill", "hand.thumbsup.fill",
            "hand.thumbsdown.fill", "checkmark.circle.fill", "xmark.circle.fill", "minus.circle.fill"
        ],
        "patterns": [
            "circle.hexagongrid.fill", "circle.grid.cross.fill", "square.grid.3x3.fill",
            "square.grid.3x3.square", "circle.dotted", "circle.grid.2x2.fill",
            "square.split.2x2.fill", "rectangle.split.3x3.fill", "flowchart.fill", "network"
        ],
        "tech": [
            "cpu.fill", "memorychip.fill", "sensor.fill", "gyroscope", "scope",
            "chart.bar.doc.horizontal.fill", "chart.xyaxis.line", "waveform.circle.fill",
            "dot.radiowaves.left.and.right", "dot.arrowtriangles.up.right.down.left.circle"
        ],
        "ambient": [
            "moon.fill", "moon.stars.fill", "cloud.fill", "snowflake", "drop.fill",
            "wind", "smoke.fill", "aqi.medium", "humidity.fill", "thermometer.medium"
        ],
        "symbols": [
            "ellipsis.circle.fill", "questionmark.circle.fill", "at.circle.fill",
            "number.circle.fill", "textformat.alt", "character.cursor.ibeam",
            "rectangle.and.text.magnifyingglass", "doc.text.fill", "envelope.fill", "tray.fill"
        ],
        "geometric": [
            "diamond.fill", "hexagon.fill", "octagon.fill", "pentagon.fill",
            "triangle.fill", "square.fill", "circle.fill", "seal.fill",
            "burst.fill", "sparkles", "star.fill", "moon.stars.circle.fill"
        ]
    ]
    
    // MARK: SCANNING STATE (100 Symbols)
    
    static let scanningSymbols: [String: [String]] = [
        "waves": [
            "waveform", "waveform.circle.fill", "waveform.badge.mic", "waveform.and.magnifyingglass",
            "wave.3.forward", "wave.3.backward", "wave.3.forward.circle.fill", "wave.3.backward.circle.fill",
            "water.waves", "water.waves.slash", "wifi", "wifi.circle.fill"
        ],
        "scanning": [
            "target", "scope", "viewfinder", "viewfinder.circle.fill", "eye.fill",
            "dot.scope", "dot.viewfinder", "magnifyingglass.circle.fill",
            "scanner.fill", "barcode.viewfinder", "qrcode.viewfinder", "circle.dotted"
        ],
        "radiowaves": [
            "antenna.radiowaves.left.and.right", "dot.radiowaves.left.and.right",
            "dot.radiowaves.up.forward", "dot.radiowaves.right", "dot.radiowaves.left.and.right.circle",
            "dot.radiowaves.forward", "personalhotspot", "wifi.router.fill", "sensor.fill", "gyroscope"
        ],
        "particles": [
            "circle.fill", "smallcircle.filled.circle.fill", "largecircle.fill.circle",
            "circle.circle.fill", "circle.inset.filled", "record.circle.fill",
            "circle.hexagongrid.fill", "circle.grid.cross.fill", "sparkles", "sparkle.magnifyingglass"
        ],
        "energy": [
            "bolt.fill", "bolt.circle.fill", "bolt.horizontal.fill", "bolt.heart.fill",
            "bolt.badge.automatic.fill", "bolt.shield.fill", "powerplug.fill",
            "battery.100percent.bolt", "lightbulb.fill", "lightbulb.max.fill"
        ],
        "sensors": [
            "sensor.fill", "togglepower", "figure.stand.line.dotted.figure.stand",
            "figure.wave", "figure.walk.motion", "point.3.connected.trianglepath.dotted",
            "triangle.fill", "diamond.fill", "hexagon.fill", "octagon.fill"
        ],
        "indicators": [
            "circle.badge.checkmark.fill", "exclamationmark.2", "exclamationmark.3",
            "arrow.up.forward.circle.fill", "arrow.down.backward.circle.fill",
            "arrow.left.arrow.right.circle.fill", "arrow.triangle.swap", "arrow.triangle.capsulepath"
        ],
        "processing": [
            "gearshape.fill", "gearshape.2.fill", "gearshape.circle.fill",
            "cpu.fill", "memorychip.fill", "brain", "brain.head.profile",
            "chart.line.uptrend.xyaxis.circle.fill", "chart.bar.xaxis.ascending", "chart.xyaxis.line"
        ],
        "flow": [
            "arrow.circlepath", "arrow.clockwise.circle.fill", "arrow.counterclockwise.circle.fill",
            "arrow.triangle.2.circlepath.circle.fill", "goforward", "gobackward",
            "repeat.circle.fill", "shuffle.circle.fill", "infinity.circle.fill", "recordingtape.circle.fill"
        ],
        "tech": [
            "laser.burst.fill", "light.ribbon.fill", "light.beacon.max.fill",
            "dot.arrowtriangles.up.right.down.left.circle", "externaldrive.fill.badge.wifi",
            "network", "airport.express", "airport.extreme.tower", "server.rack", "cpu.fill"
        ]
    ]
    
    // MARK: UNLOCKED STATE (100 Symbols)
    
    static let unlockedSymbols: [String: [String]] = [
        "celebration": [
            "sparkles", "party.popper.fill", "burst.fill", "fireworks", "gift.fill",
            "balloon.fill", "balloon.2.fill", "birthday.cake.fill", "crown.fill", "star.fill"
        ],
        "success": [
            "checkmark.seal.fill", "checkmark.circle.fill", "checkmark.shield.fill",
            "hand.thumbsup.fill", "rosette", "medal.fill", "trophy.fill",
            "flag.fill", "flag.checkered", "target"
        ],
        "joy": [
            "face.smiling.inverse", "face.smiling", "heart.fill", "heart.circle.fill",
            "heart.text.square.fill", "sparkle.magnifyingglass", "wand.and.stars",
            "wand.and.rays", "sun.max.fill", "sun.haze.fill"
        ],
        "unlock": [
            "lock.open.fill", "lock.open.trianglebadge.exclamationmark.fill",
            "key.horizontal.fill", "entry.lever.keypad.fill", "faceid",
            "touchid", "person.badge.shield.checkmark.fill", "hand.draw.fill",
            "signature", "rectangle.and.hand.point.up.left.fill"
        ],
        "energy": [
            "bolt.heart.fill", "bolt.fill", "bolt.badge.automatic.fill",
            "light.beacon.max.fill", "lightbulb.max.fill", "light.ribbon.fill",
            "laser.burst.fill", "sun.max.fill", "sunrise.fill", "sunset.fill"
        ],
        "movement": [
            "figure.run", "figure.play", "figure.dance", "figure.roll",
            "hare.fill", "arrow.up.right.circle.fill", "arrow.forward.circle.fill",
            "chevron.forward.circle.fill", "arrowshape.right.fill", "location.fill"
        ],
        "nature": [
            "leaf.fill", "leaf.arrow.circlepath", "snowflake", "drop.fill",
            "flame.fill", "sun.max.fill", "moon.stars.fill", "cloud.fill",
            "rainbow", "sparkles"
        ],
        "magic": [
            "wand.and.stars", "wand.and.rays", "sparkle.magnifyingglass",
            "scope", "eyes", "eye.fill", "theatermasks.fill",
            "moon.stars.circle.fill", "star.circle.fill", "sparkles"
        ],
        "positive": [
            "plus.circle.fill", "plus.app.fill", "rectangle.stack.fill.badge.plus",
            "folder.fill.badge.plus", "heart.square.fill", "suitcase.fill",
            "briefcase.fill", "house.fill", "building.2.fill", "mappin.circle.fill"
        ],
        "music": [
            "music.note", "music.note.list", "music.quarternote.3", "headphones.circle.fill",
            "hifispeaker.fill", "speaker.wave.3.fill", "amplifier", "radio.fill",
            "waveform.circle.fill", "tuningfork"
        ]
    ]
    
    // MARK: - Dynamic Selection
    
    static func symbolsFor(state: FaceIDState, intensity: Double) -> [String] {
        switch state {
        case .locked(let subState):
            return selectFromCategories(lockedSymbols, subState: subState, intensity: intensity)
        case .scanning(let subState):
            return selectFromCategories(scanningSymbols, subState: subState, intensity: intensity)
        case .unlocked(let subState):
            return selectFromCategories(unlockedSymbols, subState: subState, intensity: intensity)
        }
    }
    
    private static func selectFromCategories<T>(_ categories: [String: [String]], subState: T, intensity: Double) -> [String] {
        // Flatten all symbols from all categories
        let allSymbols = categories.values.flatMap { $0 }
        
        // Select count based on intensity
        let count = min(Int(intensity * 20) + 5, allSymbols.count)
        
        // Return random subset
        return Array(allSymbols.shuffled().prefix(count))
    }
}

// MARK: - Symbol Animation Configuration

struct SymbolAnimationConfig {
    var symbols: [String]
    var color: Color
    var weight: Font.Weight
    var scale: CGFloat
    var effects: [SymbolEffectConfig]
    var motion: MotionConfig
    
    struct MotionConfig {
        var rotation: Angle = .zero
        var offset: CGSize = .zero
        var amplitude: CGFloat = 1.0
        var frequency: Double = 1.0
    }
}

enum SymbolEffectConfig {
    case bounce(intensity: Double)
    case pulse(intensity: Double)
    case wiggle(angle: Angle, delay: Double)
    case scale(direction: ScaleDirection, intensity: Double)
    case variableColor(mode: VariableColorMode)
    case breathe(speed: Double)
    case appear
    case disappear
    
    enum ScaleDirection {
        case up, down
    }
    
    enum VariableColorMode {
        case iterative, cumulative
    }
}
