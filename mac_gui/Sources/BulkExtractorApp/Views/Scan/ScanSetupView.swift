import SwiftUI

public struct ScanSetupView: View {
    @ObservedObject var appState: AppState
    @State private var showingAdvancedOptions = false
    
    public init(appState: AppState) {
        self.appState = appState
    }
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Configure Extraction")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("Select a disk image, file, or directory to scan for forensic features.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Targets Box
                GroupBox(label: Label("Input Source", systemImage: "cylinder.split.1x2.fill")) {
                    VStack(alignment: .leading, spacing: 12) {
                        FileDropBox(
                            title: "Select or Drag Forensic Target",
                            subtitle: "Disk images (RAW, DMG, E01), files, or directories",
                            icon: "opticaldiscdrive.fill",
                            selectedPath: $appState.scanConfig.inputPath,
                            onPathSelected: { _, isDir in
                                appState.scanConfig.isDirectory = isDir
                            }
                        )
                        
                        Toggle("Scan target recursively as a directory of files (-R)", isOn: $appState.scanConfig.isDirectory)
                            .font(.callout)
                    }
                    .padding(8)
                }
                
                // Output Destination Box
                GroupBox(label: Label("Output Destination", systemImage: "folder.fill")) {
                    VStack(alignment: .leading, spacing: 12) {
                        FileDropBox(
                            title: "Select Output Directory",
                            subtitle: "Folder where feature files and DFXML report will be saved",
                            icon: "folder.badge.plus",
                            selectedPath: $appState.scanConfig.outputPath,
                            isDirectoryAllowed: true,
                            isFilesAllowed: false,
                            canCreateDirectories: true
                        )
                        
                        Toggle("Zap existing directory contents if it exists (-Z)", isOn: $appState.scanConfig.zapExisting)
                            .font(.callout)
                    }
                    .padding(8)
                }
                
                // Tuning & Performance
                GroupBox(label: Label("Performance & Threads", systemImage: "cpu.fill")) {
                    HStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Worker Threads (-j)")
                                .font(.callout)
                            Stepper("\(appState.scanConfig.threadCount) Threads", value: $appState.scanConfig.threadCount, in: 1...64)
                        }
                        
                        Spacer()
                    }
                    .padding(8)
                }
                
                // Scanner Selection Disclosure
                DisclosureGroup("Scanners & Filter Lists", isExpanded: $showingAdvancedOptions) {
                    ScannerTogglesView(appState: appState)
                        .padding(.top, 8)
                }
                .padding(.horizontal, 4)
                
                // Action Buttons
                HStack {
                    Spacer()
                    
                    Button(action: {
                        appState.startScan()
                    }) {
                        Label("Start Extraction", systemImage: "play.fill")
                            .font(.headline)
                            .frame(minWidth: 160, minHeight: 32)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(appState.scanConfig.inputPath.isEmpty || appState.scanConfig.outputPath.isEmpty)
                }
                .padding(.top, 10)
            }
            .padding(24)
        }
    }
}
