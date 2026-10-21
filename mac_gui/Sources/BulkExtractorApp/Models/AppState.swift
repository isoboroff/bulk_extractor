import Foundation
import SwiftUI
import Combine

public enum SidebarTab: String, CaseIterable, Identifiable {
    case scan = "New Scan"
    case active = "Live Scan"
    case results = "Extracted Features"
    case histograms = "Histograms"
    case report = "DFXML Summary"
    case forensicPath = "Forensic Path Tool"
    case logs = "Console Logs"
    
    public var id: String { rawValue }
    
    public var systemImage: String {
        switch self {
        case .scan: return "play.circle.fill"
        case .active: return "waveform.path.ecg"
        case .results: return "doc.text.magnifyingglass"
        case .histograms: return "chart.bar.fill"
        case .report: return "doc.badge.gearshape"
        case .forensicPath: return "scope"
        case .logs: return "terminal.fill"
        }
    }
}

public struct LogLine: Identifiable, Hashable {
    public let id = UUID()
    public let timestamp = Date()
    public let text: String
    public let isError: Bool
    
    public init(_ text: String, isError: Bool = false) {
        self.text = text
        self.isError = isError
    }
}

@MainActor
public class AppState: ObservableObject {
    @Published public var selectedTab: SidebarTab = .scan
    @Published public var scanConfig = ScanConfiguration()
    @Published public var isScanning = false
    @Published public var scanProgress = ScanProgress()
    
    @Published public var logLines: [LogLine] = []
    @Published public var selectedOutputDir: URL? = nil
    @Published public var featureFiles: [FeatureFile] = []
    @Published public var selectedFeatureFile: FeatureFile? = nil
    @Published public var histograms: [HistogramData] = []
    @Published public var selectedHistogram: HistogramData? = nil
    @Published public var reportSummary: ReportSummary? = nil
    
    private var processRunner: ProcessRunner?
    private var outputParser = OutputParser()
    private var reportParser = ReportParser()
    private var timer: AnyCancellable?
    private var scanStartTime: Date?
    
    public init() {}
    
    public func resolveBulkExtractorBinary() -> String? {
        return EngineVersion.resolveBinary()
    }
    
    public func startScan() {
        guard let binaryPath = resolveBulkExtractorBinary() else {
            appendLog("Error: bulk_extractor binary could not be found. Please ensure it is bundled or installed.", isError: true)
            return
        }
        
        let args = scanConfig.buildArguments()
        if scanConfig.outputPath.isEmpty {
            appendLog("Error: Output directory must be specified.", isError: true)
            return
        }
        if scanConfig.inputPath.isEmpty {
            appendLog("Error: Input target image or directory must be specified.", isError: true)
            return
        }
        
        isScanning = true
        selectedTab = .active
        scanProgress = ScanProgress()
        scanProgress.phase = .initializing
        scanStartTime = Date()
        
        appendLog("🚀 Starting bulk_extractor: \(binaryPath) \(args.joined(separator: " "))")
        
        let runner = ProcessRunner()
        self.processRunner = runner
        
        // Progress timer
        timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect().sink { [weak self] _ in
            guard let self = self, self.isScanning, let start = self.scanStartTime else { return }
            self.scanProgress.elapsedSeconds = Date().timeIntervalSince(start)
        }
        
        Task { [weak self] in
            guard let self = self else { return }
            do {
                try await runner.run(
                    executablePath: binaryPath,
                    arguments: args,
                    onStdout: { [weak self] line in
                        Task { @MainActor [weak self] in
                            self?.handleOutputLine(line, isError: false)
                        }
                    },
                    onStderr: { [weak self] line in
                        Task { @MainActor [weak self] in
                            self?.handleOutputLine(line, isError: true)
                        }
                    }
                )
                
                self.finishScan(success: true)
            } catch {
                self.appendLog("Execution error: \(error.localizedDescription)", isError: true)
                self.finishScan(success: false)
            }
        }
    }
    
    public func cancelScan() {
        guard isScanning else { return }
        appendLog("Stopping bulk_extractor scan...")
        processRunner?.terminate()
        scanProgress.phase = .cancelled
        isScanning = false
        timer?.cancel()
    }
    
    private func handleOutputLine(_ line: String, isError: Bool) {
        appendLog(line, isError: isError)
        outputParser.parseLine(line, progress: &scanProgress)
    }
    
    private func finishScan(success: Bool) {
        isScanning = false
        timer?.cancel()
        
        if success {
            scanProgress.phase = .completed
            scanProgress.percentComplete = 100.0
            appendLog("Scan completed successfully!")
            
            // Load results
            let outURL = URL(fileURLWithPath: scanConfig.outputPath)
            self.selectedOutputDir = outURL
            self.loadResultsFromDirectory(outURL)
        } else {
            scanProgress.phase = .failed
            appendLog("Scan finished with errors.", isError: true)
        }
    }
    
    public func loadResultsFromDirectory(_ dirURL: URL) {
        self.selectedOutputDir = dirURL
        Task {
            let (features, histos, rep) = await self.reportParser.scanOutputDirectory(dirURL)
            self.featureFiles = features
            self.histograms = histos
            self.reportSummary = rep
            self.selectedFeatureFile = features.first
            self.selectedHistogram = histos.first
        }
    }
    
    public func appendLog(_ text: String, isError: Bool = false) {
        logLines.append(LogLine(text, isError: isError))
    }
    
    public func clearLogs() {
        logLines.removeAll()
    }
}
