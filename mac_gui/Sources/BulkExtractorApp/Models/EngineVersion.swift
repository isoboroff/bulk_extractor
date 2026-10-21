import Foundation

public struct EngineVersion {
    // Default version updated at build time or fallback
    public static var bundled: String = "2.2.0"
    
    public static func resolveBinary() -> String? {
        if let resURL = Bundle.main.resourceURL {
            let bundledBin = resURL.appendingPathComponent("bulk_extractor/bin/bulk_extractor")
            if FileManager.default.isExecutableFile(atPath: bundledBin.path) {
                return bundledBin.path
            }
        }
        let helperBin = Bundle.main.bundleURL.appendingPathComponent("Contents/Helpers/bulk_extractor")
        if FileManager.default.isExecutableFile(atPath: helperBin.path) {
            return helperBin.path
        }
        let macosBin = Bundle.main.bundleURL.appendingPathComponent("Contents/MacOS/bulk_extractor")
        if FileManager.default.isExecutableFile(atPath: macosBin.path) {
            return macosBin.path
        }
        let cwdDevBin = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("src/bulk_extractor")
        if FileManager.default.isExecutableFile(atPath: cwdDevBin.path) {
            return cwdDevBin.path
        }
        for path in ["/opt/homebrew/bin/bulk_extractor", "/usr/local/bin/bulk_extractor", "/usr/bin/bulk_extractor"] {
            if FileManager.default.isExecutableFile(atPath: path) {
                return path
            }
        }
        return nil
    }
    
    /// Queries the binary directly using `bulk_extractor -V` or falls back to bundled version
    public static func getVersion(binaryPath: String? = nil) -> String {
        guard let bin = binaryPath ?? resolveBinary(),
              FileManager.default.isExecutableFile(atPath: bin) else {
            return bundled
        }
        
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: bin)
        proc.arguments = ["-V"]
        let pipe = Pipe()
        proc.standardOutput = pipe
        
        do {
            try proc.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            proc.waitUntilExit()
            if let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
               !output.isEmpty {
                // Output format: "bulk_extractor 2.2.1-dev"
                let parts = output.split(separator: " ")
                if let ver = parts.last {
                    return String(ver)
                }
            }
        } catch {
            // Use bundled fallback
        }
        
        return bundled
    }
    
    /// Returns the GitHub release tag URL for the specified version
    /// e.g. https://github.com/simsong/bulk_extractor/releases/tag/v2.2.0
    public static func releaseURL(for version: String) -> URL {
        let tag = version.hasPrefix("v") ? version : "v\(version)"
        return URL(string: "https://github.com/simsong/bulk_extractor/releases/tag/\(tag)")
            ?? URL(string: "https://github.com/simsong/bulk_extractor/releases")!
    }
}
