import SwiftUI

public struct ResultsView: View {
    @ObservedObject var appState: AppState
    
    public init(appState: AppState) {
        self.appState = appState
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Output directory selection bar
            HStack {
                Image(systemName: "folder.fill")
                    .foregroundColor(.accentColor)
                
                if let dir = appState.selectedOutputDir {
                    Text(dir.path)
                        .font(.callout)
                        .lineLimit(1)
                        .truncationMode(.middle)
                } else {
                    Text("No output directory loaded")
                        .font(.callout)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Open Directory…") {
                    selectOutputDirectory()
                }
                .controlSize(.small)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Main feature browser layout
            if appState.featureFiles.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("No feature files found.")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("Run an extraction or open an existing bulk_extractor output directory above.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                HSplitView {
                    // Feature files list
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Feature Files (\(appState.featureFiles.count))")
                            .font(.headline)
                            .padding(12)
                        
                        Divider()
                        
                        List(appState.featureFiles, id: \.id, selection: $appState.selectedFeatureFile) { file in
                            HStack {
                                Image(systemName: "doc.text")
                                    .foregroundColor(.accentColor)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(file.name)
                                        .font(.callout)
                                        .fontWeight(.medium)
                                    Text("\(file.recordCount) features • \(file.formattedSize)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                            .tag(file)
                        }
                        .listStyle(.sidebar)
                    }
                    .frame(minWidth: 220, maxWidth: 300)
                    
                    // Detail Table
                    if let selected = appState.selectedFeatureFile ?? appState.featureFiles.first {
                        FeatureTableView(featureFile: selected)
                    } else {
                        Text("Select a feature file on the left.")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            }
        }
    }
    
    private func selectOutputDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url {
            appState.loadResultsFromDirectory(url)
        }
    }
}
