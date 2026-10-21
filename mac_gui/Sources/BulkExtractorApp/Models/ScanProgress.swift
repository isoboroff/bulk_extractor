import Foundation

public enum ScanPhase: String, Equatable {
    case idle = "Ready"
    case initializing = "Initializing Scanners"
    case scanning = "Phase 1: Scanning Data"
    case histograms = "Phase 2: Generating Histograms"
    case finalizing = "Finalizing DFXML Report"
    case completed = "Completed"
    case failed = "Failed"
    case cancelled = "Cancelled"
}

public struct ScanProgress: Equatable {
    public var phase: ScanPhase = .idle
    public var percentComplete: Double = 0.0 // 0.0 to 100.0
    public var currentOffsetString: String = ""
    public var totalBytesString: String = ""
    public var elapsedSeconds: TimeInterval = 0
    public var estimatedRemainingSeconds: TimeInterval? = nil
    public var throughputMBs: Double? = nil
    public var currentScanner: String? = nil
    public var statusText: String = "Ready to start extraction."

    public init() {}
    
    public var formattedElapsedTime: String {
        let mins = Int(elapsedSeconds) / 60
        let secs = Int(elapsedSeconds) % 60
        return String(format: "%02d:%02d", mins, secs)
    }

    public var formattedRemainingTime: String {
        guard let rem = estimatedRemainingSeconds, rem.isFinite, rem > 0 else {
            return "--:--"
        }
        let mins = Int(rem) / 60
        let secs = Int(rem) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}
