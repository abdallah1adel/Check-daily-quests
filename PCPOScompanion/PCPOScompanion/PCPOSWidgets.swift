import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Shared Data
// Ensure you have an App Group set up (e.g., "group.com.pcpos.companion") to share data between App and Widgets

struct SharedData {
    static let suiteName = "group.com.pcpos.companion"
    
    struct Keys {
        static let lastSearchQuery = "lastSearchQuery"
        static let lastSearchSummary = "lastSearchSummary"
        static let lastSearchTime = "lastSearchTime"
    }
    
    static var defaults: UserDefaults? {
        UserDefaults(suiteName: suiteName)
    }
}

// MARK: - Search Widget (Home Screen)

struct SearchEntry: TimelineEntry {
    let date: Date
    let query: String
    let summary: String
}

struct SearchProvider: TimelineProvider {
    func placeholder(in context: Context) -> SearchEntry {
        SearchEntry(date: Date(), query: "Quantum Physics", summary: "Quantum physics is the study of matter and energy at the most fundamental level...")
    }

    func getSnapshot(in context: Context, completion: @escaping (SearchEntry) -> ()) {
        let entry = SearchEntry(date: Date(), query: "Recent Search", summary: "Search summary will appear here.")
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SearchEntry>) -> ()) {
        let defaults = SharedData.defaults
        let query = defaults?.string(forKey: SharedData.Keys.lastSearchQuery) ?? "No recent searches"
        let summary = defaults?.string(forKey: SharedData.Keys.lastSearchSummary) ?? "Ask PCPOS something to see it here."
        
        let entry = SearchEntry(date: Date(), query: query, summary: summary)
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
}

struct SearchWidgetEntryView : View {
    var entry: SearchProvider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .font(.caption)
                    .foregroundColor(.green)
                Text(entry.query)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
                    .lineLimit(1)
            }
            
            Text(entry.summary)
                .font(.system(size: 12))
                .foregroundColor(.white)
                .lineLimit(4)
                .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .padding()
        .containerBackground(Color.black, for: .widget)
    }
}

struct PCPOSSearchWidget: Widget {
    let kind: String = "PCPOSSearchWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SearchProvider()) { entry in
            SearchWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Recent Search")
        .description("View the summary of your last PCPOS search.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Control Center Widget (iOS 18+)

@available(iOS 18.0, *)
struct PCPOSControlWidget: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(
            kind: "com.pcpos.companion.control",
            provider: ControlProvider()
        ) { value in
            ControlWidgetButton(action: LaunchAppIntent()) {
                Label("PCPOS", systemImage: "faceid")
            }
        }
        .displayName("PCPOS Companion")
        .description("Quick access to PCPOS")
    }
}

@available(iOS 18.0, *)
struct ControlProvider: ControlValueProvider {
    typealias Value = Bool
    
    var previewValue: Bool {
        return false
    }

    func currentValue() async -> Bool {
        return false // State not really needed for a launcher
    }
}

@available(iOS 18.0, *)
struct LaunchAppIntent: AppIntent {
    static var title: LocalizedStringResource = "Launch PCPOS"
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        return .result()
    }
    
    // Required init
    init() {}
}
