import SwiftUI

public struct ActiveScanView: View {
    @ObservedObject var appState: AppState
    
    public init(appState: AppState) {
        self.appState = appState
    }
    
    public var body: some View {
        VStack(spacing: 20) {
            // Header Status Card
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(appState.scanProgress.phase.rawValue)
                            .font(.title2)
                            .fontWeight(.bold)
                        Text(appState.scanProgress.statusText)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if appState.isScanning {
                        ProgressView()
                            .controlSize(.regular)
                    } else if appState.scanProgress.phase == .completed {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.green)
                    } else if appState.scanProgress.phase == .failed {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.red)
                    }
                }
                
                // Progress Bar
                VStack(spacing: 6) {
                    ProgressView(value: appState.scanProgress.percentComplete, total: 100.0)
                        .progressViewStyle(.linear)
                    
                    HStack {
                        Text(String(format: "%.1f%% Complete", appState.scanProgress.percentComplete))
                            .font(.caption)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        if let mbSec = appState.scanProgress.throughputMBs {
                            Text(String(format: "%.1f MB/s", mbSec))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Divider()
                
                // Metrics grid
                HStack(spacing: 24) {
                    MetricBox(title: "Elapsed Time", value: appState.scanProgress.formattedElapsedTime, icon: "clock.fill")
                    MetricBox(title: "Time Remaining", value: appState.scanProgress.formattedRemainingTime, icon: "hourglass")
                    if let mbSec = appState.scanProgress.throughputMBs {
                        MetricBox(title: "Throughput", value: String(format: "%.1f MB/s", mbSec), icon: "bolt.fill")
                    }
                }
            }
            .padding(16)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)
            
            // Live Console Preview
            GroupBox(label: Label("Live Console Stream", systemImage: "terminal.fill")) {
                LogConsoleView(appState: appState)
                    .frame(minHeight: 240)
            }
            
            // Bottom Action Controls
            HStack {
                if appState.isScanning {
                    Button(role: .destructive, action: {
                        appState.cancelScan()
                    }) {
                        Label("Cancel Extraction", systemImage: "stop.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                } else if appState.scanProgress.phase == .completed {
                    Button(action: {
                        appState.selectedTab = .results
                    }) {
                        Label("Explore Extracted Features", systemImage: "arrow.right.circle.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
                
                Spacer()
                
                if !appState.isScanning {
                    Button("Start New Extraction") {
                        appState.selectedTab = .scan
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .padding(20)
    }
}

private struct MetricBox: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.accentColor)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.callout)
                    .fontWeight(.semibold)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
