import SwiftUI
import Charts

public struct HistogramView: View {
    @ObservedObject var appState: AppState
    @State private var searchQuery = ""
    
    public init(appState: AppState) {
        self.appState = appState
    }
    
    var selectedHistogram: HistogramData? {
        appState.selectedHistogram ?? appState.histograms.first
    }
    
    var filteredEntries: [HistogramEntry] {
        guard let hist = selectedHistogram else { return [] }
        if searchQuery.isEmpty {
            return hist.entries
        }
        return hist.entries.filter { $0.value.localizedCaseInsensitiveContains(searchQuery) }
    }
    
    var topEntriesForChart: [HistogramEntry] {
        Array(filteredEntries.prefix(15))
    }
    
    public var body: some View {
        HSplitView {
            // Sidebar with histogram files
            VStack(alignment: .leading, spacing: 0) {
                Text("Histograms")
                    .font(.headline)
                    .padding(12)
                
                Divider()
                
                List(appState.histograms, id: \.id, selection: $appState.selectedHistogram) { hist in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(hist.name)
                                .font(.callout)
                                .fontWeight(.medium)
                            Text("\(hist.entries.count) unique (\(hist.totalOccurrences) total)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .tag(hist)
                }
                .listStyle(.sidebar)
            }
            .frame(minWidth: 200, maxWidth: 280)
            
            // Detail / Chart Area
            if let hist = selectedHistogram {
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(hist.name)
                                .font(.title3)
                                .fontWeight(.semibold)
                            Text("\(hist.totalOccurrences) occurrences across \(hist.entries.count) items")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        TextField("Search…", text: $searchQuery)
                            .textFieldStyle(.roundedBorder)
                            .frame(maxWidth: 180)
                    }
                    .padding(12)
                    .background(Color(NSColor.windowBackgroundColor))
                    
                    Divider()
                    
                    // Chart Area
                    if !topEntriesForChart.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Top 15 Most Frequent")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Chart(topEntriesForChart) { entry in
                                BarMark(
                                    x: .value("Count", entry.count),
                                    y: .value("Value", entry.value)
                                )
                                .foregroundStyle(Color.accentColor.gradient)
                            }
                            .frame(height: 200)
                        }
                        .padding(12)
                        .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
                        
                        Divider()
                    }
                    
                    // Table of all entries
                    Table(filteredEntries) {
                        TableColumn("Count") { entry in
                            Text("\(entry.count)")
                                .font(.system(.body, design: .monospaced))
                                .fontWeight(.semibold)
                        }
                        .width(min: 80, ideal: 100)
                        
                        TableColumn("Value / Pattern") { entry in
                            Text(entry.value)
                                .font(.system(.body, design: .monospaced))
                                .textSelection(.enabled)
                        }
                    }
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text("No histograms found in output directory.")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}
