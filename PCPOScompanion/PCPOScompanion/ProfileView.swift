import SwiftUI

// MARK: - Profile View
/// Modern, coherent profile page with biometrics, social integration, and preferences

struct ProfileView: View {
    @StateObject private var biometricManager = BiometricManager()
    @State private var showBiometricEnrollment = false
    @State private var currentUser: UserProfile?
    
    // Preferences
    @AppStorage("tts_enabled") private var ttsEnabled = true
    @AppStorage("stt_enabled") private var sttEnabled = true
    @AppStorage("tts_voice") private var ttsVoice = "com.apple.voice.compact.en-US.Samantha"
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Header
                    profileHeader
                    
                    // Biometric Status
                    biometricSection
                    
                    // Social Accounts
                    socialSection
                    
                    // Personality & Mood
                    personalitySection
                    
                    // Voice I/O Settings
                    voiceSettingsSection
                    
                    // Sign Out
                    signOutButton
                }
                .padding()
            }
            .background(
                LinearGradient(
                    colors: [Color.black, Color(red: 0.05, green: 0.05, blue: 0.15)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showBiometricEnrollment) {
            BiometricEnrollmentView(manager: biometricManager)
        }
        .onAppear {
            loadUser()
        }
    }
    
    // MARK: - Profile Header
    
    private var profileHeader: some View {
        VStack(spacing: 12) {
            // Avatar
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.cyan, .blue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 100, height: 100)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.white)
                )
            
            Text(currentUser?.displayName ?? "User")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(currentUser?.email ?? "")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
    }
    
    // MARK: - Biometric Section
    
    private var biometricSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Biometric Enrollment")
                .font(.headline)
                .foregroundColor(.white)
            
            HStack(spacing: 20) {
                BiometricStatusCard(
                    icon: "faceid",
                    label: "Face",
                    isEnrolled: currentUser?.faceEmbedding != nil
                )
                
                BiometricStatusCard(
                    icon: "waveform",
                    label: "Voice",
                    isEnrolled: currentUser?.voiceEmbedding != nil
                )
            }
            
            Button(action: {
                showBiometricEnrollment = true
            }) {
                HStack {
                    Image(systemName: "camera.fill")
                    Text("Enroll Biometrics")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        colors: [.cyan, .blue],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
            }
        }
        .padding()
        .background(glassMorphismCard)
    }
    
    // MARK: - Social Section
    
    private var socialSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Social Accounts")
                .font(.headline)
                .foregroundColor(.white)
            
            SocialLinkRow(
                icon: "f.square.fill",
                service: "Facebook",
                isLinked: currentUser?.socialAccounts.facebookID != nil,
                color: .blue
            )
            
            SocialLinkRow(
                icon: "camera.fill",
                service: "Instagram",
                isLinked: currentUser?.socialAccounts.instagramHandle != nil,
                color: Color(red: 0.8, green: 0.3, blue: 0.5)
            )
        }
        .padding()
        .background(glassMorphismCard)
    }
    
    // MARK: - Personality Section
    
    private var personalitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Personality")
                .font(.headline)
                .foregroundColor(.white)
            
            if let mood = currentUser?.personalityPreset {
                HStack {
                    Text(mood.emoji)
                        .font(.system(size: 40))
                    
                    VStack(alignment: .leading) {
                        Text(mood.displayName)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        Text("Energy: \(mood.energy.percentage)%")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    Button("Change") {
                        // TODO: Show mood picker
                    }
                    .font(.subheadline)
                    .foregroundColor(.cyan)
                }
            }
        }
        .padding()
        .background(glassMorphismCard)
    }
    
    // MARK: - Voice Settings Section
    
    private var voiceSettingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Voice I/O")
                .font(.headline)
                .foregroundColor(.white)
            
            Toggle("Text-to-Speech (TTS)", isOn: $ttsEnabled)
                .foregroundColor(.white)
            
            Toggle("Speech-to-Text (STT)", isOn: $sttEnabled)
                .foregroundColor(.white)
        }
        .padding()
        .background(glassMorphismCard)
    }
    
    // MARK: - Sign Out
    
    private var signOutButton: some View {
        Button(action: {
            // TODO: Sign out logic
        }) {
            HStack {
                Image(systemName: "arrow.right.square")
                Text("Sign Out")
            }
            .font(.headline)
            .foregroundColor(.red)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(white: 0.2))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Helpers
    
    private var glassMorphismCard: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color(white: 0.1, opacity: 0.6))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
    }
    
    private func loadUser() {
        // Simulated user load (will be from Firebase in Phase 2B)
        currentUser = UserProfile(email: "creator@pcpos.com", displayName: "Creator")
    }
}

// MARK: - Biometric Status Card

struct BiometricStatusCard: View {
    let icon: String
    let label: String
    let isEnrolled: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 30))
                .foregroundColor(isEnrolled ? .green : .gray)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.white)
            
            Image(systemName: isEnrolled ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isEnrolled ? .green : .gray)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(white: 0.15))
        )
    }
}

// MARK: - Social Link Row

struct SocialLinkRow: View {
    let icon: String
    let service: String
    let isLinked: Bool
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(service)
                .foregroundColor(.white)
            
            Spacer()
            
            Button(isLinked ? "Unlink" : "Link") {
                // TODO: OAuth flow
            }
            .font(.subheadline)
            .foregroundColor(isLinked ? .red : .cyan)
        }
    }
}

// MARK: - Biometric Enrollment Sheet

struct BiometricEnrollmentView: View {
    @ObservedObject var manager: BiometricManager
    @Environment(\.dismiss) var dismiss
    @State private var cameraManager: CameraManager?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Text("Enroll Your Biometrics")
                    .font(.title)
                    .fontWeight(.bold)
                
                if manager.enrollmentState == .idle {
                    Button("Start Enrollment") {
                        if let camera = cameraManager {
                            manager.startEnrollment(for: "temp-user-id", cameraManager: camera)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    VStack {
                        ProgressView(value: manager.faceCaptureProgress + manager.voiceCaptureProgress, total: 2.0)
                            .tint(.cyan)
                        
                        Text(manager.progressMessage)
                            .foregroundColor(.secondary)
                    }
                }
                
                if manager.enrollmentState == .completed {
                    Button("Done") {
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            cameraManager = CameraManager()
            cameraManager?.start()
        }
        .onDisappear {
            cameraManager?.stop()
        }
    }
}
