import Foundation
import CallKit
import UIKit

/// Gonderilecek olay. Telefon numarasi YOKTUR: iOS uygulamaya numara vermez.
struct CallEvent: Codable, Identifiable {
    let uuid: String
    let ts: String          // ISO8601, aramanin basladigi an
    let type: String        // answered | missed | outgoing
    let direction: String   // in | out
    let duration: Int       // saniye (konusma suresi)
    let employee: String
    var id: String { uuid }
}

final class CallMonitor: NSObject, ObservableObject, CXCallObserverDelegate {
    static let shared = CallMonitor()

    @Published var history: [CallEvent] = []
    @Published var pending: Int = 0
    @Published var lastStatus: String = "Henüz gönderim yok"

    private let observer = CXCallObserver()
    private var started: [UUID: Date] = [:]
    private var connected: [UUID: Date] = [:]
    private var incoming: [UUID: Bool] = [:]
    private var queue: [CallEvent] = []

    private let iso = ISO8601DateFormatter()

    override init() {
        super.init()
        queue = load("queue")
        history = load("history")
        pending = queue.count
        observer.setDelegate(self, queue: nil) // nil = ana kuyruk
        flush()
    }

    // MARK: CXCallObserverDelegate
    func callObserver(_ callObserver: CXCallObserver, callChanged call: CXCall) {
        let id = call.uuid
        if started[id] == nil {
            started[id] = Date()
            incoming[id] = !call.isOutgoing
        }
        if call.hasConnected && connected[id] == nil {
            connected[id] = Date()
        }
        if call.hasEnded {
            finish(id: id)
        }
    }

    private func finish(id: UUID) {
        let start = started[id] ?? Date()
        let isIncoming = incoming[id] ?? false
        let conn = connected[id]
        let duration = conn.map { Int(Date().timeIntervalSince($0)) } ?? 0

        let type: String
        if isIncoming { type = (conn != nil) ? "answered" : "missed" }
        else { type = "outgoing" }

        let ev = CallEvent(
            uuid: id.uuidString,
            ts: iso.string(from: start),
            type: type,
            direction: isIncoming ? "in" : "out",
            duration: duration,
            employee: UserDefaults.standard.string(forKey: "employee") ?? ""
        )
        started[id] = nil; connected[id] = nil; incoming[id] = nil

        queue.append(ev)
        history.insert(ev, at: 0)
        if history.count > 50 { history.removeLast() }
        save(queue, "queue")
        save(history, "history")
        pending = queue.count
        flush()
    }

    // MARK: Sunucuya gonderme
    func flush() {
        let d = UserDefaults.standard
        guard !queue.isEmpty else { return }
        let ws = CharacterSet.whitespacesAndNewlines
        let base = (d.string(forKey: "serverURL") ?? "").trimmingCharacters(in: ws)
                     .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        // @AppStorage varsayilani diske yazilmaz; bos kalirsa varsayilan anahtari kullan
        let key = (d.string(forKey: "apiKey") ?? "deneme123").trimmingCharacters(in: ws)
        guard !base.isEmpty else { lastStatus = "Sunucu adresi boş"; return }
        guard var comps = URLComponents(string: base + "/event") else {
            lastStatus = "Adres geçersiz: \(base)"; return
        }
        comps.queryItems = [URLQueryItem(name: "key", value: key)]
        guard let url = comps.url else { lastStatus = "Adres geçersiz"; return }
        lastStatus = "Gönderiliyor..."

        let batch = queue
        var req = URLRequest(url: url, timeoutInterval: 20)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try? JSONEncoder().encode(batch)

        // Uygulama arka plana gecse bile gonderimi bitirmeye calis
        var bg = UIBackgroundTaskIdentifier.invalid
        bg = UIApplication.shared.beginBackgroundTask {
            UIApplication.shared.endBackgroundTask(bg)
        }
        URLSession.shared.dataTask(with: req) { [weak self] _, resp, err in
            DispatchQueue.main.async {
                if let err = err {
                    self?.lastStatus = "Hata: \(err.localizedDescription)"
                } else if let http = resp as? HTTPURLResponse {
                    if http.statusCode == 200, let self = self {
                        let sent = Set(batch.map { $0.uuid })
                        self.queue.removeAll { sent.contains($0.uuid) }
                        self.save(self.queue, "queue")
                        self.pending = self.queue.count
                        self.lastStatus = "Gönderildi ✓"
                    } else {
                        self?.lastStatus = "Sunucu HTTP \(http.statusCode) döndü"
                    }
                }
                if bg != .invalid { UIApplication.shared.endBackgroundTask(bg) }
            }
        }.resume()
    }

    // MARK: Kalici depolama (basit)
    private func save(_ events: [CallEvent], _ key: String) {
        if let data = try? JSONEncoder().encode(events) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
    private func load(_ key: String) -> [CallEvent] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let events = try? JSONDecoder().decode([CallEvent].self, from: data) else { return [] }
        return events
    }
}
