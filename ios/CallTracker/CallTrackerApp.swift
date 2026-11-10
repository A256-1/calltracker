import SwiftUI

@main
struct CallTrackerApp: App {
    @StateObject private var monitor = CallMonitor.shared
    @Environment(\.scenePhase) private var phase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(monitor)
        }
        .onChange(of: phase) { newPhase in
            // Uygulama on plana gelince bekleyen olaylari gonder
            if newPhase == .active { monitor.flush() }
        }
    }
}
