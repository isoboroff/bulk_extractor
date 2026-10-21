import SwiftUI

public struct DiskImagerView: View {
    @ObservedObject var appState: AppState
    
    @State private var devices: [DeviceItem] = []
    @State private var selectedDevice: DeviceItem? = nil
    @State private var customDeviceNode: String = ""
    @State private var destinationPath: String = ""
    @State private var showAllDisks: Bool = false
    @State private var isRefreshing: Bool = false
    @State private var isImaging: Bool = false
    @State private var imagingProgress = ImagingProgress()
    @State private var errorMessage: String? = nil
    @State private var isCompleted: Bool = false
    
    private let discoveryService = DiskDiscoveryService()
    private let imagingService = DiskImagingService()
    
    public init(appState: AppState) {
        self.appState = appState
    }
    
    var visibleDevices: [DeviceItem] {
        if showAllDisks {
            return devices
        }
        return devices.filter { $0.isRemovable || !$0.isInternal }
    }
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Forensic Disk Imager")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("Create a bitstream raw disk image (.raw) of an inserted CF card, SD card, or USB drive using dd with administrator privileges.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Source Device Box
                GroupBox(label: Label("1. Select Source Device", systemImage: "externaldrive.fill")) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Available Disks & Cards:")
                                .font(.headline)
                            
                            Spacer()
                            
                            Toggle("Show Internal Disks", isOn: $showAllDisks)
                                .font(.caption)
                                .toggleStyle(.checkbox)
                            
                            Button(action: refreshDevices) {
                                Label("Refresh", systemImage: "arrow.clockwise")
                            }
                            .controlSize(.small)
                            .disabled(isRefreshing || isImaging)
                        }
                        
                        if isRefreshing {
                            HStack {
                                ProgressView().controlSize(.small)
                                Text("Scanning for devices…")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 8)
                        } else if visibleDevices.isEmpty {
                            VStack(alignment: .center, spacing: 8) {
                                Image(systemName: "externaldrive.badge.xmark")
                                    .font(.title2)
                                    .foregroundColor(.secondary)
                                Text("No external cards or removable drives detected.")
                                    .font(.callout)
                                    .foregroundColor(.secondary)
                                Text("Insert your CF / SD card or card reader and click Refresh.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                        } else {
                            VStack(spacing: 6) {
                                ForEach(visibleDevices) { dev in
                                    let isSelected = selectedDevice?.id == dev.id
                                    
                                    Button(action: {
                                        selectedDevice = dev
                                        customDeviceNode = dev.rawDeviceNode
                                    }) {
                                        HStack(spacing: 12) {
                                            Image(systemName: dev.isInternal ? "internaldrive" : "externaldrive.fill")
                                                .font(.title3)
                                                .foregroundColor(isSelected ? .accentColor : .secondary)
                                            
                                            VStack(alignment: .leading, spacing: 2) {
                                                HStack {
                                                    Text(dev.volumeName.isEmpty ? dev.name : "\(dev.volumeName) (\(dev.name))")
                                                        .font(.callout)
                                                        .fontWeight(.semibold)
                                                    
                                                    if dev.isRemovable {
                                                        Text("REMOVABLE")
                                                            .font(.system(size: 8, weight: .bold))
                                                            .padding(.horizontal, 4)
                                                            .padding(.vertical, 1)
                                                            .background(Color.green.opacity(0.15))
                                                            .foregroundColor(.green)
                                                            .cornerRadius(3)
                                                    }
                                                }
                                                
                                                HStack(spacing: 12) {
                                                    Text("Device: \(dev.rawDeviceNode)")
                                                        .font(.system(.caption, design: .monospaced))
                                                    Text("Size: \(dev.formattedSize)")
                                                        .font(.caption)
                                                    if !dev.mountPoint.isEmpty {
                                                        Text("Mounted at: \(dev.mountPoint)")
                                                            .font(.caption)
                                                    }
                                                }
                                                .foregroundColor(.secondary)
                                            }
                                            
                                            Spacer()
                                            
                                            if isSelected {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(.accentColor)
                                            }
                                        }
                                        .padding(10)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(isSelected ? Color.accentColor.opacity(0.08) : Color(NSColor.controlBackgroundColor).opacity(0.4))
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(isSelected ? Color.accentColor.opacity(0.3) : Color.gray.opacity(0.2), lineWidth: 1)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        
                        Divider()
                        
                        HStack {
                            Text("Raw Device Node:")
                                .font(.callout)
                                .foregroundColor(.secondary)
                            
                            TextField("e.g. /dev/rdisk2", text: $customDeviceNode)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(.body, design: .monospaced))
                        }
                    }
                    .padding(8)
                }
                
                // Destination Box
                GroupBox(label: Label("2. Save Image File Destination", systemImage: "folder.badge.plus")) {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 8) {
                            TextField("Path to output image file (e.g. ~/Desktop/cf_card.raw)", text: $destinationPath)
                                .textFieldStyle(.roundedBorder)
                            
                            Button("Save As…") {
                                selectSaveDestination()
                            }
                            .controlSize(.small)
                            .disabled(isImaging)
                        }
                    }
                    .padding(8)
                }
                
                // Error Display
                if let err = errorMessage {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text(err)
                            .font(.callout)
                            .foregroundColor(.red)
                    }
                    .padding(8)
                }
                
                // Imaging Progress & Action
                if isImaging || isCompleted {
                    VStack(spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(imagingProgress.statusText)
                                    .font(.headline)
                                Text("\(imagingProgress.formattedCopied) of \(imagingProgress.formattedTotal)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if isImaging {
                                ProgressView().controlSize(.small)
                            } else if isCompleted {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.title2)
                                    .foregroundColor(.green)
                            }
                        }
                        
                        ProgressView(value: imagingProgress.percentComplete, total: 100.0)
                            .progressViewStyle(.linear)
                        
                        HStack {
                            Text(String(format: "%.1f%% Complete", imagingProgress.percentComplete))
                                .font(.caption)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            if imagingProgress.throughputMBs > 0 {
                                Text(String(format: "%.1f MB/s", imagingProgress.throughputMBs))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Text("Time: \(imagingProgress.formattedTime) (ETA: \(imagingProgress.formattedRemaining))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        if isCompleted {
                            HStack {
                                Spacer()
                                Button(action: loopBackToScan) {
                                    Label("Start Extraction with this Image →", systemImage: "play.circle.fill")
                                        .font(.headline)
                                        .frame(minHeight: 28)
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.large)
                            }
                            .padding(.top, 6)
                        }
                    }
                    .padding(16)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(10)
                }
                
                // Action Buttons
                if !isCompleted {
                    HStack {
                        Spacer()
                        
                        Button(action: startImaging) {
                            HStack {
                                Image(systemName: "lock.shield.fill")
                                Text("Create Forensic Image (Admin Auth)")
                            }
                            .font(.headline)
                            .frame(minWidth: 240, minHeight: 32)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .disabled(customDeviceNode.isEmpty || destinationPath.isEmpty || isImaging)
                    }
                }
            }
            .padding(24)
        }
        .task {
            refreshDevices()
        }
    }
    
    private func refreshDevices() {
        isRefreshing = true
        Task {
            let list = await discoveryService.discoverDevices()
            await MainActor.run {
                self.devices = list
                self.isRefreshing = false
                if self.selectedDevice == nil {
                    // Preselect first removable external device
                    if let firstRemovable = list.first(where: { $0.isRemovable || !$0.isInternal }) {
                        self.selectedDevice = firstRemovable
                        self.customDeviceNode = firstRemovable.rawDeviceNode
                        if self.destinationPath.isEmpty {
                            let name = firstRemovable.volumeName.isEmpty ? firstRemovable.deviceIdentifier : firstRemovable.volumeName
                            let home = FileManager.default.homeDirectoryForCurrentUser.path
                            self.destinationPath = "\(home)/Desktop/\(name).raw"
                        }
                    }
                }
            }
        }
    }
    
    private func selectSaveDestination() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.data]
        let defaultName = selectedDevice?.volumeName.isEmpty == false ? "\(selectedDevice!.volumeName).raw" : "card_image.raw"
        panel.nameFieldStringValue = defaultName
        panel.canCreateDirectories = true
        if panel.runModal() == .OK, let url = panel.url {
            destinationPath = url.path
        }
    }
    
    private func startImaging() {
        errorMessage = nil
        isImaging = true
        isCompleted = false
        imagingProgress = ImagingProgress()
        
        let node = customDeviceNode.trimmingCharacters(in: .whitespaces)
        let dest = destinationPath.trimmingCharacters(in: .whitespaces)
        let size = selectedDevice?.sizeBytes ?? 0
        
        Task {
            do {
                try await imagingService.imageDevice(
                    sourceDevice: node,
                    destinationPath: dest,
                    totalSizeBytes: size,
                    onProgress: { prog in
                        self.imagingProgress = prog
                    }
                )
                
                await MainActor.run {
                    self.isImaging = false
                    self.isCompleted = true
                }
            } catch {
                await MainActor.run {
                    self.isImaging = false
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func loopBackToScan() {
        // Set the extracted image path in Scan Configuration
        appState.scanConfig.inputPath = destinationPath
        appState.scanConfig.isDirectory = false
        
        // Auto-suggest output folder if empty
        if appState.scanConfig.outputPath.isEmpty {
            let url = URL(fileURLWithPath: destinationPath)
            let dir = url.deletingLastPathComponent().path
            let base = url.deletingPathExtension().lastPathComponent
            appState.scanConfig.outputPath = "\(dir)/\(base)_extracted"
        }
        
        // Navigate back to Scan tab
        appState.selectedTab = .scan
    }
}
