import SwiftUI
import PhotosUI

struct RiggingLandmarks: Codable {
    // Normalized coordinates (0...1) relative to image size
    var leftEye: CGPoint
    var rightEye: CGPoint
    var mouth: CGPoint
}

class RiggingManager: ObservableObject {
    @Published var selectedImage: UIImage?
    @Published var landmarks: RiggingLandmarks?
    @Published var isRiggingMode: Bool = false
    
    private let imageKey = "custom_avatar_image"
    private let landmarksKey = "custom_avatar_landmarks"
    
    init() {
        loadImage()
        loadLandmarks()
    }
    
    func saveImage(_ image: UIImage) {
        if let data = image.jpegData(compressionQuality: 0.8) {
            let url = getDocumentsDirectory().appendingPathComponent(imageKey)
            try? data.write(to: url)
            self.selectedImage = image
        }
    }
    
    func loadImage() {
        let url = getDocumentsDirectory().appendingPathComponent(imageKey)
        if let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
            self.selectedImage = image
        }
    }
    
    func saveLandmarks(_ landmarks: RiggingLandmarks) {
        if let data = try? JSONEncoder().encode(landmarks) {
            UserDefaults.standard.set(data, forKey: landmarksKey)
            self.landmarks = landmarks
        }
    }
    
    func loadLandmarks() {
        if let data = UserDefaults.standard.data(forKey: landmarksKey),
           let landmarks = try? JSONDecoder().decode(RiggingLandmarks.self, from: data) {
            self.landmarks = landmarks
        }
    }
    
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}
