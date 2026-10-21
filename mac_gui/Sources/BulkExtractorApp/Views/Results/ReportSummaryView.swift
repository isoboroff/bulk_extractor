import SwiftUI

public struct ReportSummaryView: View {
    @ObservedObject var appState: AppState
    
    public init(appState: AppState) {
        self.appState = appState
    }
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("DFXML Scan Summary")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("Metadata and execution details parsed from report.xml")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                if let rep = appState.reportSummary {
                    // Summary metrics
                    GroupBox(label: Label("Run Provenance", systemImage: "info.circle.fill")) {
                        Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 10) {
                            GridRow {
                                Text("bulk_extractor Version:").fontWeight(.medium)
                                Text(rep.version.isEmpty ? "Unknown" : rep.version).font(.system(.body, design: .monospaced))
                            }
                            GridRow {
                                Text("Start Time:").fontWeight(.medium)
                                Text(rep.startTime.isEmpty ? "Unknown" : rep.startTime)
                            }
                            GridRow {
                                Text("Elapsed Time:").fontWeight(.medium)
                                Text(String(format: "%.2f seconds", rep.elapsedSeconds))
                            }
                            GridRow {
                                Text("Total Bytes Processed:").fontWeight(.medium)
                                Text("\(rep.formattedSize) (\(rep.totalBytesScanned) bytes)")
                            }
                        }
                        .padding(8)
                    }
                    
                    // Discovered Feature Summary
                    GroupBox(label: Label("Extracted Feature Files", systemImage: "doc.text.fill")) {
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(appState.featureFiles) { file in
                                HStack {
                                    Image(systemName: "doc.plaintext")
                                        .foregroundColor(.accentColor)
                                    Text(file.name)
                                        .font(.system(.body, design: .monospaced))
                                    Spacer()
                                    Text("\(file.recordCount) features")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(file.formattedSize)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Divider()
                            }
                        }
                        .padding(8)
                    }
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "doc.badge.gearshape")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        Text("No report.xml available for this output directory.")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(40)
                }
            }
            .padding(24)
        }
    }
}
