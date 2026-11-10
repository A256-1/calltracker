import Foundation
import CoreLocation

/// Uygulamayi arka planda canli tutar. Konum VERISI KULLANILMAZ ve SUNUCUYA GONDERILMEZ;
/// konum servisi sadece iOS'un uygulamayi askiya almasini engellemek icin acik tutulur.
/// (Dusuk dogruluk + cok buyuk mesafe filtresi = en az pil tuketimi.)
final class KeepAlive: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = KeepAlive()

    @Published var status: String = "Kapalı"
    private let lm = CLLocationManager()
    private var wanted = false

    override init() {
        super.init()
        lm.delegate = self
    }

    func enable() {
        wanted = true
        apply(lm.authorizationStatus)
    }

    func disable() {
        wanted = false
        lm.stopUpdatingLocation()
        lm.stopMonitoringSignificantLocationChanges()
        lm.allowsBackgroundLocationUpdates = false
        status = "Kapalı"
    }

    private func apply(_ auth: CLAuthorizationStatus) {
        guard wanted else { return }
        switch auth {
        case .notDetermined:
            status = "İzin bekleniyor..."
            lm.requestWhenInUseAuthorization()
        case .authorizedWhenInUse:
            // "Her zaman" izni icin ikinci istek
            lm.requestAlwaysAuthorization()
            start()
            status = "Açık (Ayarlar → Konum → 'Her Zaman' seçin)"
        case .authorizedAlways:
            start()
            status = "Açık ✓"
        default:
            status = "Konum izni yok (Ayarlar → Çağrı Takip → Konum)"
        }
    }

    private func start() {
        lm.desiredAccuracy = kCLLocationAccuracyThreeKilometers
        lm.distanceFilter = 3000
        lm.pausesLocationUpdatesAutomatically = false
        lm.allowsBackgroundLocationUpdates = true      // Info.plist'te UIBackgroundModes=location gerekir
        lm.showsBackgroundLocationIndicator = true     // mavi cubuk: personel acik oldugunu gorur
        lm.startUpdatingLocation()
        // Uygulama sistem tarafindan kapatilirsa konum degisiminde yeniden baslatilir
        lm.startMonitoringSignificantLocationChanges()
    }

    // MARK: CLLocationManagerDelegate
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        apply(manager.authorizationStatus)
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // Bilerek bos: konum kullanilmaz, saklanmaz, gonderilmez.
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {}
}
