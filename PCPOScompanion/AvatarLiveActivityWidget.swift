import WidgetKit
import SwiftUI
import ActivityKit

// NOTE: This file usually goes into a separate Widget Extension target.
// For the purpose of this codebase generation, I am placing it here.
// You must add this file to the Widget Extension target in Xcode.

struct AvatarLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AvatarAttributes.self) { context in
            // Lock Screen / Banner View
            // We reuse AvatarCanvasView but need to map ContentState back to AnimationParams
            let params = paramsFromState(context.state)
            
            HStack {
                AvatarCanvasView(params: params)
                    .frame(width: 60, height: 60)
                Text(context.attributes.companionName)
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding()
            .activityBackgroundTint(Color.black.opacity(0.8))
            .activitySystemActionForegroundColor(Color.white)
            
        } dynamicIsland: { context in
            let params = paramsFromState(context.state)
            
            return DynamicIsland {
                // Expanded Region
                // We want a large avatar in the center/bottom
                DynamicIslandExpandedRegion(.center) {
                    VStack {
                        Spacer()
                        AvatarCanvasView(params: params)
                            .frame(width: 100, height: 100)
                            .shadow(color: params.colorTint, radius: 10)
                        Spacer()
                    }
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    Text(context.attributes.companionName)
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .padding(.top, 8)
                }
                
            } compactLeading: {
                // Compact Leading
                AvatarCanvasView(params: params)
                    .frame(width: 24, height: 24)
            } compactTrailing: {
                // Compact Trailing
                // Show a waveform or status
                Image(systemName: "waveform.path.ecg")
                    .foregroundColor(params.colorTint)
            } minimal: {
                // Minimal
                AvatarCanvasView(params: params)
                    .frame(width: 20, height: 20)
            }
        }
    }
    
    func paramsFromState(_ state: AvatarAttributes.ContentState) -> AnimationParams {
        return AnimationParams(
            eyeOpen: state.eyeOpen,
            browRaise: state.browRaise,
            mouthSmile: state.smile,
            mouthOpen: state.mouthOpen,
            headTilt: state.headTilt,
            glow: state.glow,
            colorTint: Color(hue: state.hue, saturation: 0.8, brightness: 1.0)
        )
    }
}
