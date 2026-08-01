#if DEBUG
import Darwin
#endif
import SwiftUI

@main
struct XQFinanceApp: App {
    init() {
        PortfolioStore.resetUITestDataIfRequested()
        #if DEBUG
        PersistenceSmokeTestRunner.runIfRequested()
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView(summary: FinanceAppSummary.default)
        }
    }
}
