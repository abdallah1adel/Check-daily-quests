import SwiftUI

// MARK: - 5-Layer Rotation Depth System

struct MultiLayerDepthSystem {
    
    // MARK: - Layer Configuration
    
    enum Layer: Int, CaseIterable {
        case background = 0    // Slowest (×0.25)
        case midBack = 1       // Slow (×0.5)
        case middle = 2        // Baseline (×1.0)
        case midFront = 3      // Fast (×1.5)
        case foreground = 4    // Fastest (×2.0)
        
        var rotationMultiplier: Double {
            switch self {
            case .background: return 0.25
            case .midBack: return 0.5
            case .middle: return 1.0
            case .midFront: return 1.5
            case .foreground: return 2.0
            }
        }
        
        var baseOpacity: Double {
            switch self {
            case .background: return 0.4   // Far = transparent
            case .midBack: return 0.55
            case .middle: return 0.7
            case .midFront: return 0.85
            case .foreground: return 1.0   // Near = opaque
            }
        }
        
        var sizeMultiplier: CGFloat {
            switch self {
            case .background: return 0.6   // Far = smaller
            case .midBack: return 0.75
            case .middle: return 0.9
            case .midFront: return 0.95
            case .foreground: return 1.0   // Near = full size
            }
        }
        
        var zIndex: Double {
            Double(rawValue)
        }
        
        var blurRadius: CGFloat {
            switch self {
            case .background: return 3
            case .midBack: return 2
            case .middle: return 1
            case .midFront: return 0.5
            case .foreground: return 0
            }
        }
    }
    
    // MARK: - Symbol Distribution
    
    struct LayeredSymbol {
        let symbol: String
        let layer: Layer
        let baseSize: CGFloat
        let color: Color
        let offset: CGSize
        
        var computedSize: CGFloat {
            baseSize * layer.sizeMultiplier
        }
        
        var computedOpacity: Double {
            layer.baseOpacity
        }
        
        var computedBlur: CGFloat {
            layer.blurRadius
        }
    }
    
    // MARK: - Layer Manager
    
    class Manager: ObservableObject {
        @Published var rotation: Double = 0
        @Published var symbols: [LayeredSymbol] = []
        
        func distributeSymbols(_ allSymbols: [String], colors: [Color], baseSize: CGFloat) {
            symbols = []
            let symbolsPerLayer = max(1, allSymbols.count / Layer.allCases.count)
            
            for (index, symbol) in allSymbols.enumerated() {
                let layerIndex = min(index / symbolsPerLayer, Layer.allCases.count - 1)
                let layer = Layer.allCases[layerIndex]
                let color = colors[index % colors.count]
                
                // Random orbital offset
                let angle = Double.random(in: 0...(2 * .pi))
                let distance = CGFloat.random(in: 20...60)
                let offset = CGSize(
                    width: cos(angle) * distance,
                    height: sin(angle) * distance
                )
                
                symbols.append(LayeredSymbol(
                    symbol: symbol,
                    layer: layer,
                    baseSize: baseSize,
                    color: color,
                    offset: offset
                ))
            }
        }
        
        func rotationAngle(for layer: Layer) -> Angle {
            .degrees(rotation * layer.rotationMultiplier)
        }
        
        func startRotation(duration: TimeInterval = 20.0) {
            withAnimation(.linear(duration: duration).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
}

// MARK: - 5-Layer View

struct FiveLayerRotationView: View {
    @StateObject private var manager = MultiLayerDepthSystem.Manager()
    let symbols: [String]
    let colors: [Color]
    let baseSize: CGFloat
    
    var body: some View {
        ZStack {
            ForEach(MultiLayerDepthSystem.Layer.allCases, id: \.rawValue) { layer in
                layerView(for: layer)
                    .zIndex(layer.zIndex)
            }
        }
        .onAppear {
            manager.distributeSymbols(symbols, colors: colors, baseSize: baseSize)
            manager.startRotation()
        }
    }
    
    @ViewBuilder
    private func layerView(for layer: MultiLayerDepthSystem.Layer) -> some View {
        let layerSymbols = manager.symbols.filter { $0.layer == layer }
        
        ZStack {
            ForEach(Array(layerSymbols.enumerated()), id: \.offset) { index, symbol in
                Image(systemName: symbol.symbol)
                    .font(.system(size: symbol.computedSize))
                    .foregroundStyle(symbol.color)
                    .opacity(symbol.computedOpacity)
                    .blur(radius: symbol.computedBlur)
                    .offset(symbol.offset)
            }
        }
        .rotationEffect(manager.rotationAngle(for: layer))
    }
}
