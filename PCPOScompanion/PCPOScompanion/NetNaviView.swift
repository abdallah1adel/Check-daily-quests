import SwiftUI
import Combine

/// Wrapper that maps the legacy `NetNaviView` name to the new `PCPOSView` implementation.
/// This keeps existing code (e.g., ContentView) functional without changing all references.
struct NetNaviView: View {
    var params: AnimationParams
    var body: some View {
        PCPOSView(params: params)
    }
}
