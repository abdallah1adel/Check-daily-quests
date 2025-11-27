import Foundation
import SwiftUI
import Combine
import Darwin

// MARK: - App Debugger & Performance Monitor
/// Comprehensive debugging and performance monitoring system

@MainActor
class AppDebugger: ObservableObject {
    static let shared = AppDebugger()
    
    @Published var isDebugMode = false
    @Published var performanceMetrics: PerformanceMetrics = PerformanceMetrics()
    @Published var systemStatus: SystemStatus = SystemStatus()
    @Published var errorLog: [ErrorEntry] = []
    
    private var cancellables = Set<AnyCancellable>()
    private var performanceTimer: Timer?
    
    struct PerformanceMetrics {
        var fps: Double = 60.0
        var memoryUsage: Double = 0.0
        var cpuUsage: Double = 0.0
        var frameTime: Double = 16.67 // ms
        var faceRecognitionTime: Double = 0.0
        var voiceProcessingTime: Double = 0.0
    }
    
    struct SystemStatus {
        var cameraActive: Bool = false
        var microphoneActive: Bool = false
        var protocol22Enrolled: Bool = false
        var protocol22Active: Bool = false
        var faceModelLoaded: Bool = false
        var speechRecognitionReady: Bool = false
        var llmServiceReady: Bool = false
    }
    
    struct ErrorEntry: Identifiable {
        let id = UUID()
        let timestamp: Date
        let message: String
        let severity: Severity
        
        enum Severity {
            case info, warning, error, critical
        }
    }
    
    private init() {
        startPerformanceMonitoring()
    }
    
    // MARK: - Performance Monitoring
    
    private func startPerformanceMonitoring() {
        performanceTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updatePerformanceMetrics()
        }
    }
    
    private func updatePerformanceMetrics() {
        // Update memory usage
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            let memoryUsageMB = Double(info.resident_size) / 1024.0 / 1024.0
            performanceMetrics.memoryUsage = memoryUsageMB
        }
        
        // Update FPS (simplified - would need frame timing in real implementation)
        // For now, assume 60 FPS if no issues
        performanceMetrics.fps = 60.0
    }
    
    // MARK: - Error Logging
    
    func log(_ message: String, severity: ErrorEntry.Severity = .info) {
        let entry = ErrorEntry(timestamp: Date(), message: message, severity: severity)
        errorLog.append(entry)
        
        // Keep only last 100 entries
        if errorLog.count > 100 {
            errorLog.removeFirst()
        }
        
        // Print to console
        let prefix = severity == .error || severity == .critical ? "❌" : "ℹ️"
        print("\(prefix) [\(severity)] \(message)")
    }
    
    // MARK: - System Status Updates
    
    func updateCameraStatus(_ active: Bool) {
        systemStatus.cameraActive = active
    }
    
    func updateMicrophoneStatus(_ active: Bool) {
        systemStatus.microphoneActive = active
    }
    
    func updateProtocol22Status(enrolled: Bool, active: Bool) {
        systemStatus.protocol22Enrolled = enrolled
        systemStatus.protocol22Active = active
    }
    
    func updateFaceModelStatus(_ loaded: Bool) {
        systemStatus.faceModelLoaded = loaded
    }
    
    func updateSpeechRecognitionStatus(_ ready: Bool) {
        systemStatus.speechRecognitionReady = ready
    }
    
    func updateLLMServiceStatus(_ ready: Bool) {
        systemStatus.llmServiceReady = ready
    }
    
    // MARK: - Performance Tracking
    
    func trackFaceRecognitionTime(_ time: Double) {
        performanceMetrics.faceRecognitionTime = time
    }
    
    func trackVoiceProcessingTime(_ time: Double) {
        performanceMetrics.voiceProcessingTime = time
    }
    
    // MARK: - Debug Mode
    
    func toggleDebugMode() {
        isDebugMode.toggle()
        log("Debug mode \(isDebugMode ? "enabled" : "disabled")")
    }
    
    func clearErrorLog() {
        errorLog.removeAll()
        log("Error log cleared")
    }
}

// MARK: - Debug View

struct DebugView: View {
    @ObservedObject var debugger = AppDebugger.shared
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                // Performance Section
                Section("Performance") {
                    HStack {
                        Text("FPS")
                        Spacer()
                        Text(String(format: "%.1f", debugger.performanceMetrics.fps))
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Memory")
                        Spacer()
                        Text(String(format: "%.1f MB", debugger.performanceMetrics.memoryUsage))
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Face Recognition")
                        Spacer()
                        Text(String(format: "%.2f ms", debugger.performanceMetrics.faceRecognitionTime))
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Voice Processing")
                        Spacer()
                        Text(String(format: "%.2f ms", debugger.performanceMetrics.voiceProcessingTime))
                            .foregroundColor(.secondary)
                    }
                }
                
                // System Status Section
                Section("System Status") {
                    StatusRow(title: "Camera", isActive: debugger.systemStatus.cameraActive)
                    StatusRow(title: "Microphone", isActive: debugger.systemStatus.microphoneActive)
                    StatusRow(title: "Protocol 22 Enrolled", isActive: debugger.systemStatus.protocol22Enrolled)
                    StatusRow(title: "Protocol 22 Active", isActive: debugger.systemStatus.protocol22Active)
                    StatusRow(title: "Face Model", isActive: debugger.systemStatus.faceModelLoaded)
                    StatusRow(title: "Speech Recognition", isActive: debugger.systemStatus.speechRecognitionReady)
                    StatusRow(title: "LLM Service", isActive: debugger.systemStatus.llmServiceReady)
                }
                
                // Error Log Section
                Section("Error Log (\(debugger.errorLog.count))") {
                    if debugger.errorLog.isEmpty {
                        Text("No errors")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(debugger.errorLog.suffix(20)) { entry in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(entry.message)
                                    Spacer()
                                    Text(entry.timestamp, style: .time)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Text(entry.severity.rawValue.uppercased())
                                    .font(.caption2)
                                    .foregroundColor(severityColor(entry.severity))
                            }
                        }
                    }
                    
                    if !debugger.errorLog.isEmpty {
                        Button("Clear Log") {
                            debugger.clearErrorLog()
                        }
                        .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Debug Console")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func severityColor(_ severity: AppDebugger.ErrorEntry.Severity) -> Color {
        switch severity {
        case .info: return .blue
        case .warning: return .orange
        case .error: return .red
        case .critical: return .purple
        }
    }
}

struct StatusRow: View {
    let title: String
    let isActive: Bool
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Image(systemName: isActive ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(isActive ? .green : .red)
        }
    }
}

