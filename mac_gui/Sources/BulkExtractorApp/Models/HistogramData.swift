import Foundation

public struct HistogramEntry: Identifiable, Hashable {
    public var id: String { "\(count)-\(value)" }
    public let count: Int
    public let value: String
    
    public init(count: Int, value: String) {
        self.count = count
        self.value = value
    }
}

public struct HistogramData: Identifiable, Hashable {
    public var id: String { name }
    public let name: String
    public let fileURL: URL
    public let entries: [HistogramEntry]
    
    public var totalOccurrences: Int {
        entries.reduce(0) { $0 + $1.count }
    }
    
    public init(name: String, fileURL: URL, entries: [HistogramEntry]) {
        self.name = name
        self.fileURL = fileURL
        self.entries = entries
    }
}

public struct ReportSummary: Equatable {
    public var version: String = ""
    public var startTime: String = ""
    public var elapsedSeconds: Double = 0
    public var totalBytesScanned: UInt64 = 0
    public var featureCounts: [String: Int] = [:]
    
    public init(version: String = "", startTime: String = "", elapsedSeconds: Double = 0, totalBytesScanned: UInt64 = 0, featureCounts: [String: Int] = [:]) {
        self.version = version
        self.startTime = startTime
        self.elapsedSeconds = elapsedSeconds
        self.totalBytesScanned = totalBytesScanned
        self.featureCounts = featureCounts
    }
    
    public var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: Int64(totalBytesScanned), countStyle: .file)
    }
}
