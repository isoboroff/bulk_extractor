import SwiftUI

@main
struct BulkExtractorApp: App {
    private let engineVersion = EngineVersion.getVersion()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About Bulk Extractor") {
                    showAboutPanel()
                }
            }
            CommandGroup(replacing: .help) {
                Link("Bulk Extractor Mac Repository", destination: URL(string: "https://github.com/isoboroff/bulk_extractor")!)
                Link("bulk_extractor \(engineVersion) Release", destination: EngineVersion.releaseURL(for: engineVersion))
            }
            SidebarCommands()
        }
    }
    
    private func showAboutPanel() {
        let currentVersion = EngineVersion.getVersion()
        let releaseURL = EngineVersion.releaseURL(for: currentVersion)
        
        let credits = NSMutableAttributedString()
        
        let headerAttr: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 12),
            .foregroundColor: NSColor.labelColor
        ]
        let bodyAttr: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 11),
            .foregroundColor: NSColor.secondaryLabelColor
        ]
        let linkAttr: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 11),
            .foregroundColor: NSColor.linkColor,
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]
        
        // App Section
        credits.append(NSAttributedString(string: "macOS Graphical App\n", attributes: headerAttr))
        credits.append(NSAttributedString(string: "Developed by Ian Soboroff\n", attributes: bodyAttr))
        
        let appLink = NSMutableAttributedString(string: "https://github.com/isoboroff/bulk_extractor\n\n", attributes: linkAttr)
        if let appURL = URL(string: "https://github.com/isoboroff/bulk_extractor") {
            appLink.addAttribute(.link, value: appURL, range: NSRange(location: 0, length: "https://github.com/isoboroff/bulk_extractor".count))
        }
        credits.append(appLink)
        
        // Engine Section with Dynamic Release Version
        credits.append(NSAttributedString(string: "bulk_extractor Core Engine (v\(currentVersion))\n", attributes: headerAttr))
        credits.append(NSAttributedString(string: "Created by Simson L. Garfinkel and contributors\n", attributes: bodyAttr))
        
        let origLinkStr = releaseURL.absoluteString
        let origLink = NSMutableAttributedString(string: origLinkStr, attributes: linkAttr)
        origLink.addAttribute(.link, value: releaseURL, range: NSRange(location: 0, length: origLinkStr.count))
        credits.append(origLink)
        
        var options: [NSApplication.AboutPanelOptionKey: Any] = [
            .credits: credits,
            .applicationVersion: "2.2.0"
        ]
        
        let copyright = "Copyright © 2026 Ian Soboroff, Simson L. Garfinkel, and contributors"
        options[NSApplication.AboutPanelOptionKey(rawValue: "Copyright")] = copyright
        
        NSApplication.shared.orderFrontStandardAboutPanel(options: options)
    }
}
