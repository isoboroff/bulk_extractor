import Foundation

public struct ImagingProgress: Equatable {
    public var percentComplete: Double = 0.0
    public var bytesCopied: UInt64 = 0
    public var totalBytes: UInt64 = 0
    public var throughputMBs: Double = 0.0
    public var elapsedSeconds: TimeInterval = 0.0
    public var remainingSeconds: TimeInterval? = nil
    public var statusText: String = "Starting disk imaging…"
    
    public init() {}
    
    public var formattedCopied: String {
        ByteCountFormatter.string(fromByteCount: Int64(bytesCopied), countStyle: .file)
    }
    
    public var formattedTotal: String {
        ByteCountFormatter.string(fromByteCount: Int64(totalBytes), countStyle: .file)
    }
    
    public var formattedTime: String {
        let mins = Int(elapsedSeconds) / 60
        let secs = Int(elapsedSeconds) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
    
    public var formattedRemaining: String {
        guard let rem = remainingSeconds, rem.isFinite, rem > 0 else { return "--:--" }
        let mins = Int(rem) / 60
        let secs = Int(rem) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}

public enum ImagingError: LocalizedError {
    case userCancelled
    case deviceNotFound(String)
    case executionFailed(String)
    case destinationInvalid(String)
    
    public var errorDescription: String? {
        switch self {
        case .userCancelled:
            return "Administrator authentication was cancelled."
        case .deviceNotFound(let dev):
            return "Source device node not found: \(dev)"
        case .executionFailed(let msg):
            return "Disk imaging failed: \(msg)"
        case .destinationInvalid(let dest):
            return "Invalid image destination path: \(dest)"
        }
    }
}

public class DiskImagingService {
    private var isCancelled = false
    private var monitorTimer: Timer?
    
    public init() {}
    
    public func imageDevice(
        sourceDevice: String, // e.g. "/dev/rdisk2"
        destinationPath: String, // e.g. "/Users/.../cf_card.raw"
        totalSizeBytes: UInt64,
        blockSize: String = "1m",
        onProgress: @escaping (ImagingProgress) -> Void
    ) async throws {
        isCancelled = false
        
        let fileManager = FileManager.default
        let destURL = URL(fileURLWithPath: destinationPath)
        
        // Ensure parent directory exists
        let parentDir = destURL.deletingLastPathComponent().path
        guard fileManager.fileExists(atPath: parentDir) else {
            throw ImagingError.destinationInvalid(parentDir)
        }
        
        // Remove existing file if present
        if fileManager.fileExists(atPath: destinationPath) {
            try? fileManager.removeItem(atPath: destinationPath)
        }
        
        var progress = ImagingProgress()
        progress.totalBytes = totalSizeBytes
        progress.statusText = "Authenticating with administrator privileges…"
        onProgress(progress)
        
        let startTime = Date()
        
        // Progress monitor in background
        let monitor = Task.detached(priority: .background) { [weak self] in
            while true {
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s
                if Task.isCancelled || (self?.isCancelled ?? true) { break }
                
                let currentSize: UInt64
                if let attrs = try? fileManager.attributesOfItem(atPath: destinationPath),
                   let sz = attrs[.size] as? UInt64 {
                    currentSize = sz
                } else {
                    currentSize = 0
                }
                
                let elapsed = Date().timeIntervalSince(startTime)
                let throughput = elapsed > 0 ? (Double(currentSize) / (1024 * 1024)) / elapsed : 0.0
                
                var prog = ImagingProgress()
                prog.bytesCopied = currentSize
                prog.totalBytes = totalSizeBytes
                prog.elapsedSeconds = elapsed
                prog.throughputMBs = throughput
                
                if totalSizeBytes > 0 {
                    let pct = (Double(currentSize) / Double(totalSizeBytes)) * 100.0
                    prog.percentComplete = min(max(pct, 0.0), 100.0)
                    if prog.percentComplete > 0.5 && throughput > 0 {
                        let remainingBytes = Double(totalSizeBytes > currentSize ? totalSizeBytes - currentSize : 0)
                        prog.remainingSeconds = remainingBytes / (throughput * 1024 * 1024)
                    }
                }
                
                prog.statusText = "Imaging \(sourceDevice) → \(destURL.lastPathComponent)"
                let snapshot = prog
                
                await MainActor.run {
                    onProgress(snapshot)
                }
            }
        }
        
        // Construct AppleScript command with administrator privileges
        // dd if=/dev/rdiskN of="/path/to/image.raw" bs=1m
        let cleanDest = destinationPath.replacingOccurrences(of: "\"", with: "\\\"")
        let script = "do shell script \"dd if=\(sourceDevice) of=\\\"\(cleanDest)\\\" bs=\(blockSize)\" with administrator privileges"
        
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        proc.arguments = ["-e", script]
        
        let errPipe = Pipe()
        proc.standardError = errPipe
        
        do {
            try proc.run()
            proc.waitUntilExit()
            monitor.cancel()
            
            if proc.terminationStatus != 0 {
                let errData = errPipe.fileHandleForReading.readDataToEndOfFile()
                let errStr = String(data: errData, encoding: .utf8) ?? ""
                
                if errStr.contains("User canceled") || errStr.contains("-128") {
                    throw ImagingError.userCancelled
                }
                throw ImagingError.executionFailed(errStr.isEmpty ? "Process exited with code \(proc.terminationStatus)" : errStr)
            }
            
            // Final progress update
            var finalProgress = ImagingProgress()
            if let attrs = try? fileManager.attributesOfItem(atPath: destinationPath),
               let sz = attrs[.size] as? UInt64 {
                finalProgress.bytesCopied = sz
                finalProgress.totalBytes = sz
            }
            finalProgress.percentComplete = 100.0
            finalProgress.statusText = "Disk image created successfully!"
            finalProgress.elapsedSeconds = Date().timeIntervalSince(startTime)
            onProgress(finalProgress)
            
        } catch {
            monitor.cancel()
            throw error
        }
    }
    
    public func cancel() {
        isCancelled = true
    }
}
