import SwiftUI

#if os(visionOS)
struct CameraReceiverView: View {
    @StateObject private var deviceLink = DeviceLinkService.shared
    @State private var currentFrame: UIImage?
    
    var body: some View {
        ZStack {
            if let image = currentFrame {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 400, height: 600) // Portrait phone aspect
                    .clipShape(UnevenRoundedRectangle(cornerRadii: .init(topLeading:  20, bottomLeading:  20, bottomTrailing:  20, topTrailing:  20)))
                    .glassBackgroundEffect()
            } else {
                VStack {
                    Image(systemName: "iphone.gen3")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary)
                    Text("Waiting for iPhone Camera...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(width: 300, height: 400)
                .glassBackgroundEffect()
            }
        }
        .onAppear {
            deviceLink.start() // Start browsing
            
            deviceLink.onCameraFrameReceived = { data in
                if let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self.currentFrame = image
                    }
                }
            }
        }
    }
}
#endif
