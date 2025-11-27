//
//  AvatarAttributes.swift
//  PCPOScompanion
//
//  Created by pcpos on 24/11/2025.
//

import Foundation
import ActivityKit
import SwiftUI

struct AvatarAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // We pass the raw params needed to draw the face
        var eyeOpen: Double
        var mouthOpen: Double
        var smile: Double
        var browRaise: Double
        var headTilt: Double
        var glow: Double
        // Color is harder to pass as Codable directly if it's SwiftUI.Color,
        // so we pass components or a hex string, or just hue.
        var hue: Double
    }

    var companionName: String
}
