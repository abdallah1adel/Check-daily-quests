import SwiftUI

/// 🎯 Main App Entry Point with Tab Navigation
@main
struct PCPOScompanionApp: App {
    @StateObject private var personalityEngine = PersonalityEngine()
    @StateObject private var riggingManager = RiggingManager()
    @AppStorage("isOnboardingComplete") private var isOnboardingComplete = false
    
    @Environment(\.scenePhase) private var scenePhase
    
    init() {
        // Start local AI servers
        PythonBridge.shared.startServers()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(personalityEngine)
                .task {
                    await LocalLLMService.shared.loadModel()
                    await VisionModelService.shared.loadModel()
                }
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .background {
                // Optional: Stop servers to save battery, or keep running if background processing needed
                // PythonBridge.shared.stopServers()
            }
        }
    }
}

/// 📱 Main Tab Navigation
struct MainTabView: View {
    @State private var selectedTab = 0
    @StateObject private var personalityEngine = PersonalityEngine.shared
    @StateObject private var speechManager = SpeechManager()
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Profile & Personalization Tab (Main)
            NavigationView {
                ProfileView()
                    .navigationBarTitle("Profile", displayMode: .large)
            }
            .tabItem {
                Label("Profile", systemImage: "person.circle.fill")
            }
            .tag(0)
            
            // PCPOS Interaction Tab
            NavigationView {
                ContentView()
                    .navigationBarHidden(true)
            }
            .tabItem {
                Label("Companion", systemImage: "face.smiling.fill")
            }
            .tag(1)
            
            // Settings Tab
            NavigationView {
                SettingsView(personalityEngine: personalityEngine, speechManager: speechManager)
                    .navigationBarTitle("Settings", displayMode: .large)
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
            .tag(2)
        }
        .accentColor(.blue)
    }
}
