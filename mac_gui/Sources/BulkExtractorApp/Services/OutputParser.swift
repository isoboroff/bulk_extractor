import Foundation

public struct OutputParser {
    public init() {}
    
    public func parseLine(_ line: String, progress: inout ScanProgress) {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Detect phases
        if trimmed.localizedCaseInsensitiveContains("Phase 1") || trimmed.localizedCaseInsensitiveContains("Scanning data") {
            progress.phase = .scanning
            progress.statusText = "Scanning input for forensic features..."
        } else if trimmed.localizedCaseInsensitiveContains("Phase 2") || trimmed.localizedCaseInsensitiveContains("Histogram") {
            progress.phase = .histograms
            progress.percentComplete = max(progress.percentComplete, 90.0)
            progress.statusText = "Generating frequency histograms..."
        } else if trimmed.localizedCaseInsensitiveContains("Phase 3") || trimmed.localizedCaseInsensitiveContains("Finalizing") {
            progress.phase = .finalizing
            progress.percentComplete = 98.0
            progress.statusText = "Finalizing DFXML report..."
        }
        
        // Match percentage: e.g. "45.2%" or "( 45.2%)" or "45%"
        if let percent = extractPercentage(from: trimmed) {
            progress.percentComplete = min(max(percent, 0.0), 100.0)
            
            // Estimate remaining time based on elapsed and percent
            if progress.percentComplete > 1.0 && progress.elapsedSeconds > 2.0 {
                let totalEstimated = (progress.elapsedSeconds / progress.percentComplete) * 100.0
                progress.estimatedRemainingSeconds = max(0, totalEstimated - progress.elapsedSeconds)
            }
        }
        
        // Match throughput: e.g. "42.5 MB/s" or "12.3 MB/sec"
        if let mbSec = extractThroughput(from: trimmed) {
            progress.throughputMBs = mbSec
        }
        
        // Match offsets or scanner activity
        if trimmed.hasPrefix("Scanner:") || trimmed.contains("scanner:") {
            progress.statusText = trimmed
        }
    }
    
    private func extractPercentage(from text: String) -> Double? {
        // Look for pattern like "12.34%" or "( 50.0%)"
        let pattern = #"(\d+(\.\d+)?)%"#
        if let regex = try? NSRegularExpression(pattern: pattern) {
            let nsString = text as NSString
            let results = regex.matches(in: text, range: NSRange(location: 0, length: nsString.length))
            if let match = results.last, match.numberOfRanges > 1 {
                let matchRange = match.range(at: 1)
                let numStr = nsString.substring(with: matchRange)
                return Double(numStr)
            }
        }
        return nil
    }
    
    private func extractThroughput(from text: String) -> Double? {
        // Look for pattern like "123.4 MB/s" or "123 MB/s"
        let pattern = #"(\d+(\.\d+)?)\s*MB\/s"#
        if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
            let nsString = text as NSString
            let results = regex.matches(in: text, range: NSRange(location: 0, length: nsString.length))
            if let match = results.last, match.numberOfRanges > 1 {
                let matchRange = match.range(at: 1)
                let numStr = nsString.substring(with: matchRange)
                return Double(numStr)
            }
        }
        return nil
    }
}
