import SwiftUI

public struct FeatureTableView: View {
    let featureFile: FeatureFile
    @State private var records: [FeatureRecord] = []
    @State private var searchQuery = ""
    @State private var isLoading = true
    
    private let parser = ReportParser()
    
    public init(featureFile: FeatureFile) {
        self.featureFile = featureFile
    }
    
    var filteredRecords: [FeatureRecord] {
        if searchQuery.isEmpty {
            return records
        }
        return records.filter {
            $0.feature.localizedCaseInsensitiveContains(searchQuery) ||
            $0.offset.localizedCaseInsensitiveContains(searchQuery) ||
            $0.context.localizedCaseInsensitiveContains(searchQuery)
        }
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header / search bar
            HStack {
                TextField("Search features…", text: $searchQuery)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 260)
                
                Text("\(filteredRecords.count) records")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button(action: exportToCSV) {
                    Label("Export CSV", systemImage: "square.and.arrow.up")
                }
                .controlSize(.small)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            if isLoading {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Loading records…")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if records.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "doc.text")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("No features recorded in \(featureFile.name)")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Table(filteredRecords) {
                    TableColumn("Offset") { record in
                        Text(record.offset)
                            .font(.system(.body, design: .monospaced))
                            .textSelection(.enabled)
                    }
                    .width(min: 120, ideal: 160)
                    
                    TableColumn("Feature") { record in
                        Text(record.feature)
                            .font(.system(.body, design: .monospaced))
                            .fontWeight(.medium)
                            .textSelection(.enabled)
                    }
                    .width(min: 200, ideal: 300)
                    
                    TableColumn("Context") { record in
                        Text(record.context)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.secondary)
                            .textSelection(.enabled)
                    }
                }
            }
        }
        .task(id: featureFile.id) {
            loadRecords()
        }
    }
    
    private func loadRecords() {
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async {
            let recs = self.parser.loadFeatureRecords(from: self.featureFile.fileURL, maxRecords: 5000)
            DispatchQueue.main.async {
                self.records = recs
                self.isLoading = false
            }
        }
    }
    
    private func exportToCSV() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.commaSeparatedText]
        panel.nameFieldStringValue = "\(featureFile.name.replacingOccurrences(of: ".txt", with: "")).csv"
        if panel.runModal() == .OK, let url = panel.url {
            var csv = "Offset,Feature,Context\n"
            for r in filteredRecords {
                let off = sanitizeCSV(r.offset)
                let feat = sanitizeCSV(r.feature)
                let ctx = sanitizeCSV(r.context)
                csv += "\(off),\(feat),\(ctx)\n"
            }
            try? csv.write(to: url, atomically: true, encoding: .utf8)
        }
    }
    
    private func sanitizeCSV(_ field: String) -> String {
        var str = field.replacingOccurrences(of: "\"", with: "\"\"")
        if str.contains(",") || str.contains("\n") || str.contains("\"") {
            str = "\"\(str)\""
        }
        return str
    }
}
