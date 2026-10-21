import SwiftUI

public struct ForensicPathView: View {
    @ObservedObject var appState: AppState
    @State private var imagePath = ""
    @State private var forensicPathString = ""
    @State private var mode = "hex" // "hex", "raw"
    @State private var isExtracting = false
    @State private var outputText = ""
    @State private var isError = false
    
    private let service = ForensicPathService()
    
    public init(appState: AppState) {
        self.appState = appState
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Input controls
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Forensic Path Inspector (-p)")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("Inspect and carve exact byte sequences, compressed streams, or forensic paths.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                GroupBox(label: Label("Target Image & Path", systemImage: "scope")) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            TextField("Forensic Image Path", text: $imagePath)
                            Button("Browse…") { selectImage() }
                        }
                        
                        HStack(spacing: 12) {
                            TextField("Forensic Path (e.g., 1024-EMAIL-500, 512, etc.)", text: $forensicPathString)
                            
                            Picker("Format", selection: $mode) {
                                Text("Hexadecimal Dump (/h)").tag("hex")
                                Text("Raw Stream (/r)").tag("raw")
                            }
                            .frame(maxWidth: 200)
                            
                            Button(action: extractForensicPath) {
                                if isExtracting {
                                    ProgressView().controlSize(.small)
                                } else {
                                    Label("Inspect Path", systemImage: "magnifyingglass")
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(imagePath.isEmpty || forensicPathString.isEmpty || isExtracting)
                        }
                    }
                    .padding(8)
                }
            }
            .padding(20)
            
            Divider()
            
            // Output view
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("Carved Data Output")
                        .font(.headline)
                    
                    Spacer()
                    
                    if !outputText.isEmpty {
                        Button(action: copyOutput) {
                            Label("Copy", systemImage: "doc.on.doc")
                        }
                        .controlSize(.small)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(NSColor.windowBackgroundColor))
                
                Divider()
                
                ScrollView {
                    Text(outputText.isEmpty ? "Output will appear here after extraction." : outputText)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(isError ? .red : (outputText.isEmpty ? .secondary : .primary))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                }
                .background(Color(NSColor.textBackgroundColor))
            }
        }
        .onAppear {
            if imagePath.isEmpty && !appState.scanConfig.inputPath.isEmpty {
                imagePath = appState.scanConfig.inputPath
            }
        }
    }
    
    private func selectImage() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        if panel.runModal() == .OK, let url = panel.url {
            imagePath = url.path
        }
    }
    
    private func extractForensicPath() {
        guard let bin = appState.resolveBulkExtractorBinary() else {
            outputText = "Error: bulk_extractor binary could not be found."
            isError = true
            return
        }
        
        isExtracting = true
        outputText = "Extracting forensic path..."
        isError = false
        
        Task {
            let res = await service.extractPath(
                binaryPath: bin,
                imagePath: imagePath,
                forensicPath: forensicPathString,
                mode: mode
            )
            
            await MainActor.run {
                self.outputText = res.rawOutput
                self.isError = res.isError
                self.isExtracting = false
            }
        }
    }
    
    private func copyOutput() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(outputText, forType: .string)
    }
}
