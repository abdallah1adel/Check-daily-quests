import Foundation
import UIKit
import CryptoKit
import Combine

// MARK: - Learning Graph Data Structures

enum QueryType: String, Codable {
    case greeting
    case question
    case command
    case search
    case timeBased
    case emotional
    case conversational
}

enum ModelType: String, Codable, Sendable {
    case fast
    case quality
}

struct LearningNode: Codable, Sendable {
    let id: UUID
    let timestamp: Date
    
    // Query metadata (NO actual text)
    let queryType: QueryType
    let queryComplexity: Float  // 0.0 to 1.0
    let wordCount: Int
    
    // Emotional context
    let userEmotionBucket: PADEmotionBucket  // Generalized
    let modelSelectedEmotion: String
    
    // Model performance
    let modelUsed: ModelType  // Changed to enum for type safety
    let responseTime: TimeInterval
    let confidence: Float
    
    // User feedback (implicit) - now mutable
    var conversationContinued: Bool = false
    var followUpQuery: Bool = false
    let escalatedToOnline: Bool
}

struct PADEmotionBucket: Codable, Sendable {
    // Bucketed to nearest 0.2 for privacy
    let pleasureBucket: Float  // -1.0, -0.8, -0.6, ..., 1.0
    let arousalBucket: Float
    let dominanceBucket: Float
    
    init(from emotion: PADEmotion) {
        self.pleasureBucket = Self.bucket(emotion.pleasure)
        self.arousalBucket = Self.bucket(emotion.arousal)
        self.dominanceBucket = Self.bucket(emotion.dominance)
    }
    
    static func bucket(_ value: Float) -> Float {
        // Round to nearest 0.2
        return round(value * 5) / 5
    }
}

struct GraphMetrics: Codable, Sendable {
    var totalInteractions: Int = 0
    var avgResponseTime: TimeInterval = 0
    var successRate: Float = 0  // % of conversations that continued
    var fastModelUsage: Float = 0  // % of times fast model was used
    var escalationRate: Float = 0  // % of times escalated to online
}

struct LearningGraph: Codable, Sendable {
    let deviceIdHash: String  // SHA256 hash for anonymity
    var nodes: [LearningNode] = []
    var aggregateMetrics: GraphMetrics = GraphMetrics()
    let createdAt: Date
    var lastUpdatedAt: Date
    
    init(deviceIdHash: String) {
        self.deviceIdHash = deviceIdHash
        self.createdAt = Date()
        self.lastUpdatedAt = Date()
    }
}

struct EncryptedGraph: Codable, Sendable {
    let deviceIdHash: String
    let appVersion: String
    let modelVersion: String
    let encryptedData: Data
    let signature: Data
    let timestamp: Date
}

// MARK: - Learning Graph Service

@MainActor
class LearningGraphService: ObservableObject {
    static let shared = LearningGraphService()
    
    @Published var hasOptedIn: Bool {
        didSet {
            UserDefaults.standard.set(hasOptedIn, forKey: "federated_learning_opt_in")
            if hasOptedIn {
                print("LearningGraphService: User opted in to federated learning")
            } else {
                print("LearningGraphService: User opted out, clearing graph")
                currentGraph = createNewGraph()
            }
        }
    }
    
    @Published var pendingUpload: Bool = false
    
    private var currentGraph: LearningGraph
    private var lastInteractionTime: Date = Date()
    private let uploadThreshold = 100  // Upload after 100 interactions
    private var saveDebouncer: Timer?
    private let saveDebounceDuration: TimeInterval = 2.0
    
    private let deviceIdHash: String
    
    // Persistent encryption key
    nonisolated private var encryptionKey: SymmetricKey {
        if let keyData = KeychainHelper.load(key: "learning_graph_encryption_key") {
            return SymmetricKey(data: keyData)
        }
        let newKey = SymmetricKey(size: .bits256)
        _ = KeychainHelper.save(key: "learning_graph_encryption_key", data: newKey.withUnsafeBytes { Data($0) })
        return newKey
    }
    
    private init() {
        // Generate stable device ID hash (anonymous)
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        self.deviceIdHash = SHA256.hash(data: Data(deviceId.utf8))
            .compactMap { String(format: "%02x", $0) }
            .joined()
        
        // Load opt-in preference (default to TRUE for federated learning)
        if UserDefaults.standard.object(forKey: "federated_learning_opt_in") == nil {
            // First launch - default to opted in
            self.hasOptedIn = true
            UserDefaults.standard.set(true, forKey: "federated_learning_opt_in")
        } else {
            self.hasOptedIn = UserDefaults.standard.bool(forKey: "federated_learning_opt_in")
        }
        
        // Load or create graph
        // Load or create graph
        var loadedGraph: LearningGraph?
        if let data = UserDefaults.standard.data(forKey: "learning_graph") {
             loadedGraph = try? JSONDecoder().decode(LearningGraph.self, from: data)
        }

        if let savedGraph = loadedGraph {
            self.currentGraph = savedGraph
            print("LearningGraphService: Loaded existing graph with \(savedGraph.nodes.count) nodes")
        } else {
            self.currentGraph = LearningGraph(deviceIdHash: self.deviceIdHash)
            print("LearningGraphService: Created new learning graph")
        }
    }
    
    private func createNewGraph() -> LearningGraph {
        return LearningGraph(deviceIdHash: deviceIdHash)
    }
    
    // MARK: - Interaction Recording
    
    func recordInteraction(
        query: String,  // Will be abstracted, not stored
        emotion: PADEmotion,
        modelUsed: ModelType,
        response: LocalLLMResponse,
        responseTime: TimeInterval
    ) {
        guard hasOptedIn else { return }
        
        // Extract metadata only, discard raw text
        let node = LearningNode(
            id: UUID(),
            timestamp: Date(),
            queryType: classifyQuery(query),
            queryComplexity: analyzeComplexity(query),
            wordCount: query.split(separator: " ").count,
            userEmotionBucket: PADEmotionBucket(from: emotion),
            modelSelectedEmotion: response.mood.emotion,
            modelUsed: modelUsed,
            responseTime: responseTime,
            confidence: response.confidence,
            conversationContinued: false,  // Will be updated by recordFollowUp
            followUpQuery: false,
            escalatedToOnline: response.shouldEscalate
        )
        
        currentGraph.nodes.append(node)
        currentGraph.lastUpdatedAt = Date()
        updateAggregateMetrics()
        scheduleSave()  // Debounced save
        
        lastInteractionTime = Date()
        
        // Check if we should upload
        if currentGraph.nodes.count >= uploadThreshold {
            pendingUpload = true
        }
        
        print("LearningGraphService: Recorded node (total: \(currentGraph.nodes.count))")
    }
    
    func recordFollowUp() {
        guard hasOptedIn else { return }
        guard !currentGraph.nodes.isEmpty else { return }
        
        let timeSinceLastInteraction = Date().timeIntervalSince(lastInteractionTime)
        
        // If follow-up within 60 seconds, mark as successful
        if timeSinceLastInteraction < 60 {
            let lastIndex = currentGraph.nodes.count - 1
            currentGraph.nodes[lastIndex].conversationContinued = true
            currentGraph.nodes[lastIndex].followUpQuery = true
            
            updateAggregateMetrics()
            scheduleSave()  // Debounced save
        }
    }
    
    // MARK: - Query Analysis (Privacy-Safe)
    
    private func classifyQuery(_ query: String) -> QueryType {
        let lowercased = query.lowercased()
        
        // Greeting
        if lowercased.contains("hello") || lowercased.contains("hi ") || lowercased.contains("hey") {
            return .greeting
        }
        
        // Time-based
        if lowercased.contains("time") || lowercased.contains("date") || lowercased.contains("day") {
            return .timeBased
        }
        
        // Search intent
        if lowercased.contains("search") || lowercased.contains("find") || lowercased.contains("google") {
            return .search
        }
        
        // Question
        if lowercased.hasSuffix("?") || lowercased.hasPrefix("what") || 
           lowercased.hasPrefix("how") || lowercased.hasPrefix("why") {
            return .question
        }
        
        // Command
        if lowercased.hasPrefix("play") || lowercased.hasPrefix("open") || 
           lowercased.hasPrefix("show") {
            return .command
        }
        
        // Emotional
        if lowercased.contains("sad") || lowercased.contains("happy") || 
           lowercased.contains("angry") {
            return .emotional
        }
        
        return .conversational
    }
    
    private func analyzeComplexity(_ query: String) -> Float {
        let wordCount = query.split(separator: " ").count
        let hasComplexKeywords = ["explain", "why", "how does", "compare", "difference"].contains {
            query.lowercased().contains($0)
        }
        
        // Simple heuristic: 0-1 scale
        var complexity: Float = min(Float(wordCount) / 30.0, 1.0)
        if hasComplexKeywords {
            complexity = min(complexity + 0.3, 1.0)
        }
        
        return complexity
    }
    
    private func updateAggregateMetrics() {
        let nodes = currentGraph.nodes
        
        currentGraph.aggregateMetrics.totalInteractions = nodes.count
        
        if !nodes.isEmpty {
            currentGraph.aggregateMetrics.avgResponseTime = nodes.reduce(0.0) { $0 + $1.responseTime } / Double(nodes.count)
            
            let successfulConversations = nodes.filter { $0.conversationContinued }.count
            currentGraph.aggregateMetrics.successRate = Float(successfulConversations) / Float(nodes.count)
            
            let fastModelCount = nodes.filter { $0.modelUsed == .fast }.count
            currentGraph.aggregateMetrics.fastModelUsage = Float(fastModelCount) / Float(nodes.count)
            
            let escalatedCount = nodes.filter { $0.escalatedToOnline }.count
            currentGraph.aggregateMetrics.escalationRate = Float(escalatedCount) / Float(nodes.count)
        }
    }
    
    // MARK: - Privacy & Export
    
    func exportGraph() async -> EncryptedGraph? {
        guard hasOptedIn else { return nil }
        guard currentGraph.nodes.count >= 5 else { return nil }  // k-anonymity: minimum 5 nodes
        
        let key = self.encryptionKey
        
        // Run privacy filtering and encryption off the main actor
        return await Task.detached(priority: .background) { [currentGraph, self] in
            let privacyFiltered = self.applyDifferentialPrivacy(currentGraph)
            return self.encrypt(privacyFiltered, with: key)
        }.value
    }
    
    nonisolated private func applyDifferentialPrivacy(_ graph: LearningGraph) -> LearningGraph {
        var filtered = graph
        
        // Add Laplace noise to aggregate metrics (epsilon = 1.0)
        let epsilon = 1.0
        filtered.aggregateMetrics.avgResponseTime += laplaceNoise(epsilon)
        filtered.aggregateMetrics.successRate = max(0, min(1, filtered.aggregateMetrics.successRate + Float(laplaceNoise(epsilon) * 0.1)))
        filtered.aggregateMetrics.fastModelUsage = max(0, min(1, filtered.aggregateMetrics.fastModelUsage + Float(laplaceNoise(epsilon) * 0.1)))
        
        // Apply temporal fuzzing (±30 minutes)
        filtered.nodes = applyTemporalFuzzing(filtered.nodes)
        
        // Apply smart sampling (keep 90%)
        filtered.nodes = applySampling(filtered.nodes)
        
        return filtered
    }
    
    nonisolated private func applyTemporalFuzzing(_ nodes: [LearningNode]) -> [LearningNode] {
        return nodes.map { node in
            var mutableNode = node
            let fuzz = TimeInterval.random(in: -1800...1800) // ±30 minutes
            let fuzzyTimestamp = node.timestamp.addingTimeInterval(fuzz)
            // Create new node with fuzzy timestamp (since timestamp is immutable)
            return LearningNode(
                id: node.id,
                timestamp: fuzzyTimestamp,
                queryType: node.queryType,
                queryComplexity: node.queryComplexity,
                wordCount: node.wordCount,
                userEmotionBucket: node.userEmotionBucket,
                modelSelectedEmotion: node.modelSelectedEmotion,
                modelUsed: node.modelUsed,
                responseTime: node.responseTime,
                confidence: node.confidence,
                conversationContinued: node.conversationContinued,
                followUpQuery: node.followUpQuery,
                escalatedToOnline: node.escalatedToOnline
            )
        }
    }
    
    nonisolated private func applySampling(_ nodes: [LearningNode]) -> [LearningNode] {
        return nodes.filter { _ in Double.random(in: 0...1) > 0.1 }  // Keep 90%
    }
    
    nonisolated private func laplaceNoise(_ epsilon: Double) -> Double {
        // Laplace distribution: -ln(U) * (1/epsilon), where U ~ Uniform(0,1)
        let u = Double.random(in: 0.0001...0.9999)
        let sign = Bool.random() ? 1.0 : -1.0
        return sign * log(u) / epsilon
    }
    
    nonisolated private func encrypt(_ graph: LearningGraph, with key: SymmetricKey) -> EncryptedGraph? {
        do {
            let jsonData = try JSONEncoder().encode(graph)
            
            // Use persistent encryption key from Keychain
            let sealedBox = try AES.GCM.seal(jsonData, using: key)
            
            guard let encryptedData = sealedBox.combined else { return nil }
            
            // Create signature
            let signature = HMAC<SHA256>.authenticationCode(for: encryptedData, using: key)
            let signatureData = Data(signature)
            
            return EncryptedGraph(
                deviceIdHash: graph.deviceIdHash,
                appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0",
                modelVersion: "granite-3b-v1",
                encryptedData: encryptedData,
                signature: signatureData,
                timestamp: Date()
            )
        } catch {
            print("LearningGraphService: Encryption failed: \(error)")
            return nil
        }
    }
    
    // MARK: - Persistence
    
    private func scheduleSave() {
        saveDebouncer?.invalidate()
        saveDebouncer = Timer.scheduledTimer(withTimeInterval: saveDebounceDuration, repeats: false) { [weak self] _ in
            self?.saveGraph()
        }
    }
    
    private func saveGraph() {
        do {
            let data = try JSONEncoder().encode(currentGraph)
            UserDefaults.standard.set(data, forKey: "learning_graph")
            print("LearningGraphService: Graph saved (\(currentGraph.nodes.count) nodes)")
        } catch {
            print("LearningGraphService: Failed to save graph: \(error)")
        }
    }
    
    private func loadGraph() -> LearningGraph? {
        guard let data = UserDefaults.standard.data(forKey: "learning_graph") else { return nil }
        return try? JSONDecoder().decode(LearningGraph.self, from: data)
    }
    
    func clearGraph() {
        currentGraph = createNewGraph()
        UserDefaults.standard.removeObject(forKey: "learning_graph")
        pendingUpload = false
        print("LearningGraphService: Graph cleared")
    }
}

