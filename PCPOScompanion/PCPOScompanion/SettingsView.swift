import SwiftUI
import AVFoundation

struct SettingsView: View {
    @ObservedObject var personalityEngine: PersonalityEngine
    @ObservedObject var speechManager: SpeechManager
    @Environment(\.presentationMode) var presentationMode
    @AppStorage("avatar_mode") private var avatarMode = 0
    @State private var showingNameEditor = false
    @State private var tempCompanionName = ""
    @State private var availableVoices: [AVSpeechSynthesisVoice] = []
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Companion Identity")) {
                    HStack {
                        Text("Name")
                        Spacer()
                        Text(personalityEngine.companionName)
                            .foregroundColor(.gray)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        tempCompanionName = personalityEngine.companionName
                        showingNameEditor = true
                    }
                }
                
                Section(header: Text("Avatar System")) {
                    Picker("Model", selection: $avatarMode) {
                        Text("Dynamic Core").tag(0)
                        Text("Face ID").tag(1)
                        Text("PCPOS").tag(2)
                        Text("Custom Rig").tag(3)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section(header: Text("Personality Matrix")) {
                    PersonalitySlider(label: "Cheerfulness", value: $personalityEngine.personality.cheerfulness, color: .yellow)
                    PersonalitySlider(label: "Empathy", value: $personalityEngine.personality.empathy, color: .green)
                    PersonalitySlider(label: "Curiosity", value: $personalityEngine.personality.curiosity, color: .blue)
                    PersonalitySlider(label: "Calmness", value: $personalityEngine.personality.calmness, color: .purple)
                    PersonalitySlider(label: "Confidence", value: $personalityEngine.personality.confidence, color: .orange)
                }
                
                Section(header: Text("Expression Range")) {
                    Toggle("Exaggerated Expressions", isOn: $personalityEngine.exaggeratedExpressions)
                        .toggleStyle(SwitchToggleStyle(tint: .blue))
                }
                
                Section(header: Text("Voice Provider")) {
                    Picker("Provider", selection: Binding(
                        get: { speechManager.currentProvider },
                        set: { speechManager.updateProvider($0) }
                    )) {
                        ForEach(TTSProvider.allCases, id: \.self) { provider in
                            Text(provider.rawValue).tag(provider)
                        }
                    }
                    
                    if speechManager.currentProvider != .apple {
                        SecureField("API Key", text: Binding(
                            get: { speechManager.apiKey },
                            set: { speechManager.updateApiKey($0) }
                        ))
                        .textContentType(.password)
                        
                        if speechManager.currentProvider == .elevenLabs {
                            Text("Requires ElevenLabs API Key")
                                .font(.caption)
                                .foregroundColor(.gray)
                        } else if speechManager.currentProvider == .openAI {
                            Text("Leave empty to use System Key")
                                .font(.caption)
                                .foregroundColor(.green)
                        } else if speechManager.currentProvider == .xtts {
                            Text("Requires Coqui XTTS API Key or local server URL")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                Section(header: Text("Voice Settings")) {
                    if speechManager.currentProvider == .apple {
                        Picker("Voice", selection: Binding(
                            get: { speechManager.selectedVoiceIdentifier ?? "default" },
                            set: { speechManager.updateVoice(identifier: $0 == "default" ? nil : $0) }
                        )) {
                            Text("Default").tag("default")
                            ForEach(availableVoices, id: \.identifier) { voice in
                                Text(voice.name).tag(voice.identifier)
                            }
                        }
                    }
                    
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Speech Rate")
                            Spacer()
                            Text(String(format: "%.1fx", speechManager.speechRate))
                                .foregroundColor(.gray)
                        }
                        Slider(value: Binding(
                            get: { speechManager.speechRate },
                            set: { speechManager.updateSpeechRate($0) }
                        ), in: 0.3...0.8, step: 0.05)
                        .accentColor(.blue)
                    }
                }
                
                Section(header: Text("Rewards")) {
                    NavigationLink(destination: ReferralView()) {
                        Label("Invite Friends & Save", systemImage: "gift.fill")
                    }
                }
                
                Section(header: Text("Reset")) {
                    Button("Reset to Heroic Default") {
                        personalityEngine.personality = .heroic
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Preferences")
            .navigationBarItems(trailing: Button("Done") {
                // Save all preferences
                PersistenceManager.shared.savePersonality(personalityEngine.personality)
                PersistenceManager.shared.saveCompanionName(personalityEngine.companionName)
                PersistenceManager.shared.saveVoiceIdentifier(speechManager.selectedVoiceIdentifier ?? "")
                PersistenceManager.shared.saveSpeechRate(speechManager.speechRate)
                PersistenceManager.shared.saveTTSProvider(speechManager.currentProvider)
                PersistenceManager.shared.saveTTSApiKey(speechManager.apiKey)
                
                presentationMode.wrappedValue.dismiss()
            })
            .alert("Rename Companion", isPresented: $showingNameEditor) {
                TextField("Companion Name", text: $tempCompanionName)
                    .textInputAutocapitalization(.words)
                Button("Cancel", role: .cancel) { }
                Button("Save") {
                    let trimmed = tempCompanionName.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty {
                        personalityEngine.companionName = trimmed
                    }
                }
            } message: {
                Text("Enter a new name for your companion.")
            }
            .onAppear {
                loadAvailableVoices()
            }
        }
    }
    
    private func loadAvailableVoices() {
        // Get all English voices, prioritizing enhanced quality
        // According to Apple docs, speechVoices() returns all available voices
        let allVoices = AVSpeechSynthesisVoice.speechVoices()
        let englishVoices = allVoices.filter { $0.language.hasPrefix("en") }
        
        let sortedVoices: [AVSpeechSynthesisVoice]
        if #available(iOS 13.0, *) {
            // Prioritize enhanced quality voices (iOS 13+)
            sortedVoices = englishVoices.sorted { voice1, voice2 in
                let enhanced1 = voice1.quality == .enhanced
                let enhanced2 = voice2.quality == .enhanced
                if enhanced1 != enhanced2 {
                    return enhanced1 // Enhanced voices first
                }
                return voice1.name.localizedCaseInsensitiveCompare(voice2.name) == .orderedAscending
            }
        } else {
            // iOS 12 and below - just sort by name
            sortedVoices = englishVoices.sorted { 
                $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
        }
        
        availableVoices = Array(sortedVoices.prefix(20)) // Limit to top 20
    }
}

struct PersonalitySlider: View {
    var label: String
    @Binding var value: CGFloat
    var color: Color
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(label)
                Spacer()
                Text("\(Int(value * 100))%")
                    .foregroundColor(.gray)
            }
            Slider(value: $value, in: 0...1)
                .accentColor(color)
        }
    }
}
