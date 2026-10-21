import SwiftUI
import UniformTypeIdentifiers

public struct FileDropBox: View {
    let title: String
    let subtitle: String
    let icon: String
    @Binding var selectedPath: String
    var isDirectoryAllowed: Bool = true
    var isFilesAllowed: Bool = true
    var canCreateDirectories: Bool = true
    var onPathSelected: ((String, Bool) -> Void)? = nil
    
    @State private var isTargeted = false
    
    public init(
        title: String,
        subtitle: String,
        icon: String = "doc.badge.plus",
        selectedPath: Binding<String>,
        isDirectoryAllowed: Bool = true,
        isFilesAllowed: Bool = true,
        canCreateDirectories: Bool = true,
        onPathSelected: ((String, Bool) -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self._selectedPath = selectedPath
        self.isDirectoryAllowed = isDirectoryAllowed
        self.isFilesAllowed = isFilesAllowed
        self.canCreateDirectories = canCreateDirectories
        self.onPathSelected = onPathSelected
    }
    
    public var body: some View {
        VStack(spacing: 8) {
            Image(systemName: isTargeted ? "arrow.down.doc.fill" : icon)
                .font(.system(size: 28))
                .foregroundColor(isTargeted ? .accentColor : .secondary)
            
            Text(title)
                .font(.headline)
            
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
            
            if !selectedPath.isEmpty {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text(selectedPath)
                        .font(.caption)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    
                    Button(action: { selectedPath = "" }) {
                        Image(systemName: "xmark.circle")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(6)
            }
            
            Button("Browse…") {
                openFilePanel()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isTargeted ? Color.accentColor : Color.gray.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [6]))
                .background(isTargeted ? Color.accentColor.opacity(0.05) : Color(NSColor.controlBackgroundColor).opacity(0.5))
        )
        .cornerRadius(10)
        .onDrop(of: [UTType.fileURL.identifier], isTargeted: $isTargeted) { providers in
            guard let provider = providers.first else { return false }
            _ = provider.loadObject(ofClass: URL.self) { url, _ in
                guard let url = url else { return }
                DispatchQueue.main.async {
                    self.selectedPath = url.path
                    let isDir = (try? url.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
                    self.onPathSelected?(url.path, isDir)
                }
            }
            return true
        }
    }
    
    private func openFilePanel() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = isFilesAllowed
        panel.canChooseDirectories = isDirectoryAllowed
        panel.canCreateDirectories = canCreateDirectories
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url {
            selectedPath = url.path
            let isDir = (try? url.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
            onPathSelected?(url.path, isDir)
        }
    }
}
