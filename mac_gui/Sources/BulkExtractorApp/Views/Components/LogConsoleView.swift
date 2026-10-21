import SwiftUI

public struct LogConsoleView: View {
    @ObservedObject var appState: AppState
    @State private var searchText = ""
    @State private var showErrorsOnly = false
    @State private var autoScroll = true
    
    public init(appState: AppState) {
        self.appState = appState
    }
    
    var filteredLogs: [LogLine] {
        appState.logLines.filter { line in
            if showErrorsOnly && !line.isError { return false }
            if !searchText.isEmpty && !line.text.localizedCaseInsensitiveContains(searchText) { return false }
            return true
        }
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Toolbar header
            HStack {
                TextField("Search logs…", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 220)
                
                Toggle("Errors Only", isOn: $showErrorsOnly)
                    .toggleStyle(.checkbox)
                    .font(.caption)
                
                Toggle("Auto-scroll", isOn: $autoScroll)
                    .toggleStyle(.checkbox)
                    .font(.caption)
                
                Spacer()
                
                Button(action: copyToClipboard) {
                    Label("Copy", systemImage: "doc.on.doc")
                }
                .controlSize(.small)
                
                Button(action: { appState.clearLogs() }) {
                    Label("Clear", systemImage: "trash")
                }
                .controlSize(.small)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // Console output area
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 2) {
                        ForEach(filteredLogs) { line in
                            Text(line.text)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(line.isError ? .red : .primary)
                                .textSelection(.enabled)
                                .id(line.id)
                        }
                    }
                    .padding(8)
                }
                .background(Color(NSColor.textBackgroundColor))
                .onChange(of: appState.logLines.count) { _ in
                    if autoScroll, let last = filteredLogs.last {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
        }
    }
    
    private func copyToClipboard() {
        let text = filteredLogs.map { $0.text }.joined(separator: "\n")
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }
}
