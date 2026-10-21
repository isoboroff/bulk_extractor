import Foundation

public struct ForensicPathResult {
    public let rawOutput: String
    public let hexDump: String
    public let isError: Bool
    
    public init(rawOutput: String, hexDump: String = "", isError: Bool = false) {
        self.rawOutput = rawOutput
        self.hexDump = hexDump
        self.isError = isError
    }
}

public struct ForensicPathService {
    public init() {}
    
    public func extractPath(
        binaryPath: String,
        imagePath: String,
        forensicPath: String,
        mode: String = "hex" // "hex", "raw", "standard"
    ) async -> ForensicPathResult {
        guard !imagePath.isEmpty, !forensicPath.isEmpty else {
            return ForensicPathResult(rawOutput: "Error: Image path and forensic path are required.", isError: true)
        }
        
        var pathArg = forensicPath
        if mode == "hex" && !pathArg.hasSuffix("/h") {
            pathArg += "/h"
        } else if mode == "raw" && !pathArg.hasSuffix("/r") {
            pathArg += "/r"
        }
        
        let args = ["-p", pathArg, imagePath]
        
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: binaryPath)
        proc.arguments = args
        
        let stdout = Pipe()
        let stderr = Pipe()
        proc.standardOutput = stdout
        proc.standardError = stderr
        
        do {
            try proc.run()
            let outData = stdout.fileHandleForReading.readDataToEndOfFile()
            let errData = stderr.fileHandleForReading.readDataToEndOfFile()
            proc.waitUntilExit()
            
            let outStr = String(data: outData, encoding: .utf8) ?? String(data: outData, encoding: .isoLatin1) ?? ""
            let errStr = String(data: errData, encoding: .utf8) ?? ""
            
            if proc.terminationStatus != 0 {
                return ForensicPathResult(rawOutput: errStr.isEmpty ? "Extraction failed." : errStr, isError: true)
            }
            
            return ForensicPathResult(rawOutput: outStr, hexDump: outStr, isError: false)
        } catch {
            return ForensicPathResult(rawOutput: "Failed to execute: \(error.localizedDescription)", isError: true)
        }
    }
}
