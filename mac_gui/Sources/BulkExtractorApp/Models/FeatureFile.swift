import Foundation

public struct FeatureRecord: Identifiable, Hashable {
    public var id: String { "\(offset)-\(feature)" }
    public let offset: String
    public let feature: String
    public let context: String
    
    public init(offset: String, feature: String, context: String = "") {
        self.offset = offset
        self.feature = feature
        self.context = context
    }
}

public struct FeatureFile: Identifiable, Hashable {
    public var id: String { name }
    public let name: String
    public let fileURL: URL
    public let sizeBytes: Int64
    public var recordCount: Int
    
    public var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: sizeBytes, countStyle: .file)
    }
    
    public init(name: String, fileURL: URL, sizeBytes: Int64, recordCount: Int = 0) {
        self.name = name
        self.fileURL = fileURL
        self.sizeBytes = sizeBytes
        self.recordCount = recordCount
    }
}
