import SwiftUI
import UIKit

/// Uygulama konum olayiyla arka planda yeniden baslatilsa bile cagri izleyicisi
/// ve canli tutma hemen devreye girsin diye burada baslatilir.
final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        _ = CallMonitor.shared
        if UserDefaults.standard.bool(forKey: "keepAlive") {
            KeepAlive.shared.enable()
        }
        return true
    }
}

@main
struct CallTrackerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
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
