import Foundation

public struct KnownScanner: Identifiable, Hashable {
    public var id: String { name }
    public let name: String
    public let description: String
    public let defaultEnabled: Bool
}

public struct ScanConfiguration: Equatable {
    public var inputPath: String = ""
    public var isDirectory: Bool = false
    public var outputPath: String = ""
    public var zapExisting: Bool = false
    public var threadCount: Int = ProcessInfo.processInfo.activeProcessorCount
    
    // Scanners
    public var enabledScanners: Set<String> = []
    public var disabledScanners: Set<String> = []
    
    // Lists
    public var alertListPath: String = ""
    public var stopListPath: String = ""
    public var bannerFilePath: String = ""
    
    // Tuning & Offsets
    public var scanOffsetStart: String = ""
    public var scanOffsetEnd: String = ""
    public var pageStart: String = ""
    public var maxPageSizeMB: Int = 16
    public var customFlags: String = ""

    public static let standardScanners: [KnownScanner] = [
        KnownScanner(name: "accts", description: "Scans for credit card numbers, track 2, PII", defaultEnabled: true),
        KnownScanner(name: "base16", description: "Scans for base16 (hex) encoded data", defaultEnabled: true),
        KnownScanner(name: "email", description: "Scans for email addresses and RFC822 headers", defaultEnabled: true),
        KnownScanner(name: "exif", description: "Scans for EXIF metadata in JPEGs, TIFFs, etc.", defaultEnabled: true),
        KnownScanner(name: "find", description: "Searches for regex/string patterns", defaultEnabled: true),
        KnownScanner(name: "gps", description: "Scans for GPS coordinates (Garmin, KML, EXIF)", defaultEnabled: true),
        KnownScanner(name: "gzip", description: "Carves and decompresses GZIP streams", defaultEnabled: true),
        KnownScanner(name: "hiberfile", description: "Scans Windows hibernation files", defaultEnabled: true),
        KnownScanner(name: "httplog", description: "Scans for HTTP log entries", defaultEnabled: true),
        KnownScanner(name: "json", description: "Scans for JSON objects and fragments", defaultEnabled: true),
        KnownScanner(name: "kml", description: "Scans for KML / XML geolocation data", defaultEnabled: true),
        KnownScanner(name: "msxml", description: "Scans for Microsoft Office XML structures", defaultEnabled: true),
        KnownScanner(name: "net", description: "Scans for IP addresses, TCP/UDP packets", defaultEnabled: true),
        KnownScanner(name: "pdf", description: "Scans and decompresses PDF objects", defaultEnabled: true),
        KnownScanner(name: "rar", description: "Carves and decompresses RAR archives", defaultEnabled: true),
        KnownScanner(name: "sqlite", description: "Scans for SQLite databases and records", defaultEnabled: true),
        KnownScanner(name: "vcard", description: "Scans for vCard contacts", defaultEnabled: true),
        KnownScanner(name: "windirs", description: "Scans for FAT/NTFS directory entries", defaultEnabled: true),
        KnownScanner(name: "winlnk", description: "Scans for Windows Shell LNK shortcuts", defaultEnabled: true),
        KnownScanner(name: "winpe", description: "Scans for Windows Portable Executable headers", defaultEnabled: true),
        KnownScanner(name: "winprefetch", description: "Scans for Windows Prefetch artifacts", defaultEnabled: true),
        KnownScanner(name: "zip", description: "Carves and decompresses ZIP / JAR / Office archives", defaultEnabled: true)
    ]

    public init() {}

    public func buildArguments() -> [String] {
        var args: [String] = []
        
        // Output directory is required
        if !outputPath.trimmingCharacters(in: .whitespaces).isEmpty {
            args.append("-o")
            args.append(outputPath)
        }
        
        // Directory recursion
        if isDirectory {
            args.append("-R")
        }
        
        // Zap existing output
        if zapExisting {
            args.append("-Z")
        }
        
        // Thread count
        if threadCount > 0 {
            args.append("-j")
            args.append("\(threadCount)")
        }
        
        // Enabled / Disabled scanners
        for scanner in enabledScanners {
            args.append("-e")
            args.append(scanner)
        }
        for scanner in disabledScanners {
            args.append("-x")
            args.append(scanner)
        }
        
        // Wordlists & files
        if !alertListPath.trimmingCharacters(in: .whitespaces).isEmpty {
            args.append("-r")
            args.append(alertListPath)
        }
        if !stopListPath.trimmingCharacters(in: .whitespaces).isEmpty {
            args.append("-w")
            args.append(stopListPath)
        }
        if !bannerFilePath.trimmingCharacters(in: .whitespaces).isEmpty {
            args.append("-b")
            args.append(bannerFilePath)
        }
        
        // Offsets
        if !scanOffsetStart.isEmpty {
            if !scanOffsetEnd.isEmpty {
                args.append("-Y")
                args.append("\(scanOffsetStart)-\(scanOffsetEnd)")
            } else {
                args.append("-Y")
                args.append(scanOffsetStart)
            }
        }
        if !pageStart.isEmpty {
            args.append("-z")
            args.append(pageStart)
        }
        
        // Custom flags
        if !customFlags.trimmingCharacters(in: .whitespaces).isEmpty {
            let split = customFlags.split(separator: " ").map { String($0) }
            args.append(contentsOf: split)
        }
        
        // Target image / input path
        if !inputPath.trimmingCharacters(in: .whitespaces).isEmpty {
            args.append(inputPath)
        }
        
        return args
    }
}
