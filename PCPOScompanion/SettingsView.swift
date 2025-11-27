import SwiftUI

struct SettingsView: View {
    @ObservedObject var personalityEngine: PersonalityEngine
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Form {
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
                
                Section(header: Text("Reset")) {
                    Button("Reset to Heroic Default") {
                        personalityEngine.personality = .heroic
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Preferences")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
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
