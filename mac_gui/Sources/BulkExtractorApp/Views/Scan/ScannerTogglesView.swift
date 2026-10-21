import SwiftUI

public struct ScannerTogglesView: View {
    @ObservedObject var appState: AppState
    @State private var filterQuery = ""
    
    public init(appState: AppState) {
        self.appState = appState
    }
    
    var filteredScanners: [KnownScanner] {
        if filterQuery.isEmpty {
            return ScanConfiguration.standardScanners
        }
        return ScanConfiguration.standardScanners.filter {
            $0.name.localizedCaseInsensitiveContains(filterQuery) ||
            $0.description.localizedCaseInsensitiveContains(filterQuery)
        }
    }
    
    var activeScannerCount: Int {
        ScanConfiguration.standardScanners.count - appState.scanConfig.disabledScanners.count
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Scanner filter and toolbar
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 12) {
                    TextField("Filter detectors…", text: $filterQuery)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 220)
                    
                    Text("\(activeScannerCount) of \(ScanConfiguration.standardScanners.count) Active")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(6)
                    
                    Spacer()
                    
                    Button("Enable All") {
                        appState.scanConfig.disabledScanners.removeAll()
                    }
                    .controlSize(.small)
                    
                    Button("Disable All") {
                        for s in ScanConfiguration.standardScanners {
                            appState.scanConfig.disabledScanners.insert(s.name)
                        }
                    }
                    .controlSize(.small)
                    
                    Button("Reset Defaults") {
                        appState.scanConfig.disabledScanners.removeAll()
                        appState.scanConfig.enabledScanners.removeAll()
                    }
                    .controlSize(.small)
                }
                
                // Uniform 2-Column Grid
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 10),
                    GridItem(.flexible(), spacing: 10)
                ], spacing: 10) {
                    ForEach(filteredScanners) { scanner in
                        let isEnabled = !appState.scanConfig.disabledScanners.contains(scanner.name)
                        
                        ScannerTile(
                            scanner: scanner,
                            isEnabled: isEnabled,
                            onToggle: {
                                if isEnabled {
                                    appState.scanConfig.disabledScanners.insert(scanner.name)
                                } else {
                                    appState.scanConfig.disabledScanners.remove(scanner.name)
                                }
                            }
                        )
                    }
                }
            }
            
            Divider()
            
            // Alert and Stop Lists
            VStack(alignment: .leading, spacing: 10) {
                Text("Alert and Stop Lists")
                    .font(.headline)
                
                Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 8) {
                    GridRow {
                        Text("Alert List (-r):")
                            .font(.callout)
                            .foregroundColor(.secondary)
                            .gridColumnAlignment(.trailing)
                        
                        HStack(spacing: 8) {
                            TextField("Path to alert keywords / regex list", text: $appState.scanConfig.alertListPath)
                                .textFieldStyle(.roundedBorder)
                            Button("Browse…") { selectFile(for: \.alertListPath) }
                                .controlSize(.small)
                        }
                    }
                    
                    GridRow {
                        Text("Stop List (-w):")
                            .font(.callout)
                            .foregroundColor(.secondary)
                            .gridColumnAlignment(.trailing)
                        
                        HStack(spacing: 8) {
                            TextField("Path to stop list", text: $appState.scanConfig.stopListPath)
                                .textFieldStyle(.roundedBorder)
                            Button("Browse…") { selectFile(for: \.stopListPath) }
                                .controlSize(.small)
                        }
                    }
                    
                    GridRow {
                        Text("Banner File (-b):")
                            .font(.callout)
                            .foregroundColor(.secondary)
                            .gridColumnAlignment(.trailing)
                        
                        HStack(spacing: 8) {
                            TextField("Path to banner text file", text: $appState.scanConfig.bannerFilePath)
                                .textFieldStyle(.roundedBorder)
                            Button("Browse…") { selectFile(for: \.bannerFilePath) }
                                .controlSize(.small)
                        }
                    }
                }
            }
            
            Divider()
            
            // Scan Range & Custom Arguments
            VStack(alignment: .leading, spacing: 10) {
                Text("Scan Range & Offsets")
                    .font(.headline)
                
                Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 8) {
                    GridRow {
                        Text("Byte Range (-Y):")
                            .font(.callout)
                            .foregroundColor(.secondary)
                            .gridColumnAlignment(.trailing)
                        
                        HStack(spacing: 8) {
                            TextField("Start offset", text: $appState.scanConfig.scanOffsetStart)
                                .textFieldStyle(.roundedBorder)
                            Text("–")
                                .foregroundColor(.secondary)
                            TextField("End offset (optional)", text: $appState.scanConfig.scanOffsetEnd)
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                    
                    GridRow {
                        Text("Start Page (-z):")
                            .font(.callout)
                            .foregroundColor(.secondary)
                            .gridColumnAlignment(.trailing)
                        
                        TextField("Page number", text: $appState.scanConfig.pageStart)
                            .textFieldStyle(.roundedBorder)
                            .frame(maxWidth: 180)
                    }
                    
                    GridRow {
                        Text("Extra CLI Flags:")
                            .font(.callout)
                            .foregroundColor(.secondary)
                            .gridColumnAlignment(.trailing)
                        
                        TextField("Additional arguments (e.g. -S ssn_mode=1)", text: $appState.scanConfig.customFlags)
                            .textFieldStyle(.roundedBorder)
                    }
                }
            }
        }
    }
    
    private func selectFile(for keyPath: WritableKeyPath<ScanConfiguration, String>) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        if panel.runModal() == .OK, let url = panel.url {
            appState.scanConfig[keyPath: keyPath] = url.path
        }
    }
}

private struct ScannerTile: View {
    let scanner: KnownScanner
    let isEnabled: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack(alignment: .top, spacing: 10) {
                Toggle("", isOn: Binding(get: { isEnabled }, set: { _ in onToggle() }))
                    .labelsHidden()
                    .toggleStyle(.checkbox)
                    .padding(.top, 1)
                
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(scanner.name)
                            .font(.system(.subheadline, design: .monospaced))
                            .fontWeight(.semibold)
                            .foregroundColor(isEnabled ? .primary : .secondary)
                        
                        if !isEnabled {
                            Text("DISABLED")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(3)
                        }
                    }
                    
                    Text(scanner.description)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, minHeight: 52, alignment: .topLeading)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isEnabled ? Color.accentColor.opacity(0.07) : Color(NSColor.controlBackgroundColor).opacity(0.5))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isEnabled ? Color.accentColor.opacity(0.25) : Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
