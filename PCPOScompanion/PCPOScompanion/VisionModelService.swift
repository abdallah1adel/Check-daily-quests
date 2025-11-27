import Foundation
import UIKit
import Combine
#if canImport(MLX)
import MLX
#endif

@MainActor
final class VisionModelService: ObservableObject {

    static let shared = VisionModelService()

    private var model: VisionEncoder?

    private init() {}

    func loadModel() async {
        let bundle = Bundle.main

        guard let configPath = bundle.path(forResource: "config", ofType: "json", inDirectory: "models/vision"),
              let weightsPath = bundle.path(forResource: "model.safetensors.index", ofType: "json", inDirectory: "models/vision")
        else {
            print("❌ Vision model files not found.")
            return
        }

        print("""
        📦 Loading Granite Vision:
        - config: \(configPath)
        - weights: \(weightsPath)
        """)

        do {
            model = try await VisionEncoder(
                configURL: URL(fileURLWithPath: configPath),
                weightsURL: URL(fileURLWithPath: weightsPath)
            )

            print("✅ Granite Vision loaded successfully.")
        } catch {
            print("❌ Vision load error: \(error)")
        }
    }

    #if canImport(MLX)
    func encodeImage(_ uiImage: UIImage) async -> MLXArray? {
        guard let model else {
            print("Vision model not loaded.")
            return nil
        }

        do {
            let tensor = try await model.encode(image: uiImage)
            return tensor
        } catch {
            print("❌ Image encoding error: \(error)")
            return nil
        }
    }
    #else
    func encodeImage(_ uiImage: UIImage) async -> [Float]? {
        guard let model else {
            print("Vision model not loaded.")
            return nil
        }

        do {
            let embedding = try await model.encode(image: uiImage)
            return embedding
        } catch {
            print("❌ Image encoding error: \(error)")
            return nil
        }
    }
    #endif
}

