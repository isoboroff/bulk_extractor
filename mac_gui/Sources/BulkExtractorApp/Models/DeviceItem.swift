import Foundation

public struct DeviceItem: Identifiable, Hashable {
    public var id: String { deviceIdentifier }
    public let deviceIdentifier: String // e.g. "disk2"
    public let deviceNode: String       // e.g. "/dev/disk2"
    public let rawDeviceNode: String    // e.g. "/dev/rdisk2"
    public let name: String             // e.g. "SanDisk Extreme Pro" or volume name
    public let volumeName: String
    public let mountPoint: String
    public let sizeBytes: UInt64
    public let isRemovable: Bool
    public let isInternal: Bool
    public let busProtocol: String
    
    public init(
        deviceIdentifier: String,
        deviceNode: String,
        rawDeviceNode: String,
        name: String,
        volumeName: String = "",
        mountPoint: String = "",
        sizeBytes: UInt64 = 0,
        isRemovable: Bool = true,
        isInternal: Bool = false,
        busProtocol: String = "USB"
    ) {
        self.deviceIdentifier = deviceIdentifier
        self.deviceNode = deviceNode
        self.rawDeviceNode = rawDeviceNode
        self.name = name
        self.volumeName = volumeName
        self.mountPoint = mountPoint
        self.sizeBytes = sizeBytes
        self.isRemovable = isRemovable
        self.isInternal = isInternal
        self.busProtocol = busProtocol
    }
    
    public var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: Int64(sizeBytes), countStyle: .file)
    }
    
    public var displayTitle: String {
        if !volumeName.isEmpty {
            return "\(volumeName) (\(deviceIdentifier)) – \(formattedSize)"
        }
        return "\(name) (\(deviceIdentifier)) – \(formattedSize)"
    }
}
