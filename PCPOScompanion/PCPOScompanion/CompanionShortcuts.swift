import AppIntents
import SwiftUI

// 1. The Intent
struct TalkToCompanionIntent: AppIntent {
    static var title: LocalizedStringResource = "Talk to Companion"
    static var description = IntentDescription("Opens the companion app and starts listening immediately.")
    static var openAppWhenRun: Bool = true
    
    @MainActor
    func perform() async throws -> some IntentResult {
        // Deep link handling will be done in ContentView via onOpenURL or userActivity
        // We return a result that opens the app
        return .result(opensIntent: OpenURLIntent(URL(string: "PCPOScompanion://talk")!))
    }
}

// 2. The Shortcuts Provider
struct CompanionShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: TalkToCompanionIntent(),
            phrases: [
                "Hey \(.applicationName)",
                "Talk to \(.applicationName)",
                "Start \(.applicationName)"
            ],
            shortTitle: "Talk to Companion",
            systemImageName: "mic.fill"
        )
    }
}

// Helper intent to open URL since we can't directly control the view state from here easily without a shared model
struct OpenURLIntent: AppIntent {
    static var title: LocalizedStringResource = "Open URL"
    
    @Parameter(title: "URL")
    var url: URL
    
    init() {}
    
    init(_ url: URL) {
        self.url = url
    }
    
    @MainActor
    func perform() async throws -> some IntentResult {
        await UIApplication.shared.open(url)
        return .result()
    }
}
