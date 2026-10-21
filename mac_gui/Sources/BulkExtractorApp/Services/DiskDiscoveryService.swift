import Foundation

public struct DiskDiscoveryService {
    public init() {}
    
    public func discoverDevices() async -> [DeviceItem] {
        return await Task.detached(priority: .userInitiated) {
            var devices: [DeviceItem] = []
            
            let proc = Process()
            proc.executableURL = URL(fileURLWithPath: "/usr/sbin/diskutil")
            proc.arguments = ["list", "-plist"]
            
            let pipe = Pipe()
            proc.standardOutput = pipe
            
            do {
                try proc.run()
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                proc.waitUntilExit()
                
                guard let plist = try PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
                      let allDisks = plist["AllDisks"] as? [String] else {
                    return devices
                }
                
                for diskId in allDisks {
                    // Only process whole disks (e.g. disk0, disk2) or external partition mounts
                    if let item = self.inspectDisk(diskId) {
                        devices.append(item)
                    }
                }
            } catch {
                // Return whatever was collected
            }
            
            // Sort: external/removable first, then by identifier
            devices.sort { d1, d2 in
                if d1.isInternal != d2.isInternal {
                    return !d1.isInternal && d2.isInternal
                }
                return d1.deviceIdentifier < d2.deviceIdentifier
            }
            
            return devices
        }.value
    }
    
    private func inspectDisk(_ diskId: String) -> DeviceItem? {
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/sbin/diskutil")
        proc.arguments = ["info", "-plist", diskId]
        
        let pipe = Pipe()
        proc.standardOutput = pipe
        
        do {
            try proc.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            proc.waitUntilExit()
            
            guard let info = try PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] else {
                return nil
            }
            
            let isWholeDisk = (info["WholeDisk"] as? Bool) ?? false
            let isInternal = (info["Internal"] as? Bool) ?? true
            let volumeName = (info["VolumeName"] as? String) ?? ""
            let mountPoint = (info["MountPoint"] as? String) ?? ""
            
            // We want all whole disks, plus any mounted external volumes
            if !isWholeDisk && mountPoint.isEmpty {
                return nil
            }
            
            let devNode = (info["DeviceNode"] as? String) ?? "/dev/\(diskId)"
            let rawNode = devNode.replacingOccurrences(of: "/dev/disk", with: "/dev/rdisk")
            let mediaName = (info["MediaName"] as? String) ?? (info["IORegistryEntryName"] as? String) ?? diskId
            let size = (info["TotalSize"] as? UInt64) ?? (info["Size"] as? UInt64) ?? 0
            let isRemovable = (info["RemovableMedia"] as? Bool) ?? (info["Ejectable"] as? Bool) ?? !isInternal
            let proto = (info["BusProtocol"] as? String) ?? (isInternal ? "Internal" : "External")
            
            return DeviceItem(
                deviceIdentifier: diskId,
                deviceNode: devNode,
                rawDeviceNode: rawNode,
                name: mediaName,
                volumeName: volumeName,
                mountPoint: mountPoint,
                sizeBytes: size,
                isRemovable: isRemovable,
                isInternal: isInternal,
                busProtocol: proto
            )
        } catch {
            return nil
        }
    }
}
