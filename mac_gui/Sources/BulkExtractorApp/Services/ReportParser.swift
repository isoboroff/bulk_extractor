import Foundation

public struct ReportParser {
    public init() {}
    
    public func scanOutputDirectory(_ dirURL: URL) async -> ([FeatureFile], [HistogramData], ReportSummary?) {
        guard let files = try? FileManager.default.contentsOfDirectory(at: dirURL, includingPropertiesForKeys: [.fileSizeKey, .isRegularFileKey]) else {
            return ([], [], nil)
        }
        
        var featureFiles: [FeatureFile] = []
        var histograms: [HistogramData] = []
        var reportSummary: ReportSummary? = nil
        
        for file in files {
            let filename = file.lastPathComponent
            
            if filename == "report.xml" {
                reportSummary = parseReportXML(file)
                continue
            }
            
            guard filename.hasSuffix(".txt") else { continue }
            
            let attrs = try? file.resourceValues(forKeys: [.fileSizeKey])
            let size = Int64(attrs?.fileSize ?? 0)
            
            if filename.hasSuffix("_histogram.txt") {
                let hData = parseHistogramFile(file)
                histograms.append(hData)
            } else {
                let count = estimateLineCount(file)
                let fFile = FeatureFile(name: filename, fileURL: file, sizeBytes: size, recordCount: count)
                featureFiles.append(fFile)
            }
        }
        
        featureFiles.sort { $0.name.lowercased() < $1.name.lowercased() }
        histograms.sort { $0.name.lowercased() < $1.name.lowercased() }
        
        return (featureFiles, histograms, reportSummary)
    }
    
    public func loadFeatureRecords(from fileURL: URL, maxRecords: Int = 1000) -> [FeatureRecord] {
        guard let data = try? String(contentsOf: fileURL, encoding: .utf8) else {
            // Fallback to latin1 / ascii
            guard let altData = try? String(contentsOf: fileURL, encoding: .isoLatin1) else {
                return []
            }
            return parseFeatureText(altData, maxRecords: maxRecords)
        }
        return parseFeatureText(data, maxRecords: maxRecords)
    }
    
    private func parseFeatureText(_ text: String, maxRecords: Int) -> [FeatureRecord] {
        var records: [FeatureRecord] = []
        let lines = text.split(separator: "\n", omittingEmptySubsequences: true)
        
        for line in lines {
            if line.hasPrefix("#") { continue } // Skip comments / banners
            
            let parts = line.split(separator: "\t", maxSplits: 2, omittingEmptySubsequences: false)
            if parts.count >= 2 {
                let offset = String(parts[0])
                let feature = String(parts[1])
                let context = parts.count > 2 ? String(parts[2]) : ""
                records.append(FeatureRecord(offset: offset, feature: feature, context: context))
            } else if !line.isEmpty {
                records.append(FeatureRecord(offset: "", feature: String(line)))
            }
            
            if records.count >= maxRecords { break }
        }
        return records
    }
    
    public func parseHistogramFile(_ fileURL: URL) -> HistogramData {
        let name = fileURL.lastPathComponent
        guard let content = try? String(contentsOf: fileURL, encoding: .utf8) else {
            return HistogramData(name: name, fileURL: fileURL, entries: [])
        }
        
        var entries: [HistogramEntry] = []
        let lines = content.split(separator: "\n", omittingEmptySubsequences: true)
        
        for line in lines {
            if line.hasPrefix("#") { continue }
            // Format: n=<count>\t<value> or <count>\t<value>
            let parts = line.split(separator: "\t", maxSplits: 1, omittingEmptySubsequences: false)
            if parts.count == 2 {
                var countStr = String(parts[0])
                if countStr.hasPrefix("n=") {
                    countStr.removeFirst(2)
                }
                let count = Int(countStr.trimmingCharacters(in: .whitespaces)) ?? 0
                let val = String(parts[1]).trimmingCharacters(in: .whitespaces)
                entries.append(HistogramEntry(count: count, value: val))
            }
        }
        
        return HistogramData(name: name, fileURL: fileURL, entries: entries)
    }
    
    private func estimateLineCount(_ fileURL: URL) -> Int {
        guard let content = try? String(contentsOf: fileURL, encoding: .utf8) else { return 0 }
        var count = 0
        content.enumerateLines { line, _ in
            if !line.hasPrefix("#") && !line.isEmpty {
                count += 1
            }
        }
        return count
    }
    
    private func parseReportXML(_ fileURL: URL) -> ReportSummary? {
        guard let xmlContent = try? String(contentsOf: fileURL, encoding: .utf8) else { return nil }
        
        var summary = ReportSummary()
        
        // Extract basic metadata with simple regexes
        if let vMatch = xmlContent.range(of: #"<bulk_extractor_version>(.*?)</bulk_extractor_version>"#, options: .regularExpression) {
            let tag = xmlContent[vMatch]
            summary.version = tag.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        }
        if let timeMatch = xmlContent.range(of: #"<start_time>(.*?)</start_time>"#, options: .regularExpression) {
            let tag = xmlContent[timeMatch]
            summary.startTime = tag.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        }
        if let elapsedMatch = xmlContent.range(of: #"<elapsed_seconds>(.*?)</elapsed_seconds>"#, options: .regularExpression) {
            let tag = xmlContent[elapsedMatch]
            let str = tag.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            summary.elapsedSeconds = Double(str) ?? 0
        }
        if let sizeMatch = xmlContent.range(of: #"<image_size>(.*?)</image_size>"#, options: .regularExpression) {
            let tag = xmlContent[sizeMatch]
            let str = tag.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            summary.totalBytesScanned = UInt64(str) ?? 0
        }
        
        return summary
    }
}
