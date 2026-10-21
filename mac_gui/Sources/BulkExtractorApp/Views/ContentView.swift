import SwiftUI

public struct ContentView: View {
    @StateObject private var appState = AppState()
    
    public init() {}
    
    public var body: some View {
        NavigationSplitView {
            List(SidebarTab.allCases, selection: $appState.selectedTab) { tab in
                NavigationLink(value: tab) {
                    Label(tab.rawValue, systemImage: tab.systemImage)
                }
            }
            .navigationTitle("Bulk Extractor")
            .listStyle(.sidebar)
        } detail: {
            switch appState.selectedTab {
            case .scan:
                ScanSetupView(appState: appState)
            case .active:
                ActiveScanView(appState: appState)
            case .results:
                ResultsView(appState: appState)
            case .histograms:
                HistogramView(appState: appState)
            case .report:
                ReportSummaryView(appState: appState)
            case .forensicPath:
                ForensicPathView(appState: appState)
            case .logs:
                LogConsoleView(appState: appState)
            }
        }
        .frame(minWidth: 900, minHeight: 620)
    }
}
