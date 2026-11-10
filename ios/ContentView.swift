import SwiftUI

struct ContentView: View {
    @EnvironmentObject var monitor: CallMonitor
    @AppStorage("serverURL") private var serverURL = ""
    @AppStorage("apiKey") private var apiKey = "deneme123"
    @AppStorage("employee") private var employee = ""
    @AppStorage("keepAlive") private var keepAlive = false
    @ObservedObject private var keep = KeepAlive.shared

    private func label(_ type: String) -> String {
        switch type {
        case "answered": return "Cevaplandı"
        case "missed": return "Cevapsız"
        case "outgoing": return "Giden"
        default: return type
        }
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Ayarlar")) {
                    TextField("Sunucu adresi (https://...)", text: $serverURL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                    TextField("Anahtar", text: $apiKey)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField("Personel adı", text: $employee)
                }
                Section(header: Text("Arka plan"),
                        footer: Text("Açıkken uygulama arka planda canlı kalır ve kilitli ekranda da aramaları görür. Konum bilgisi kullanılmaz, kaydedilmez, gönderilmez; mavi konum çubuğu bunun açık olduğunu gösterir. Pil kullanımı biraz artar.")) {
                    Toggle("Arka planda çalış", isOn: $keepAlive)
                        .onChange(of: keepAlive) { on in
                            if on { KeepAlive.shared.enable() } else { KeepAlive.shared.disable() }
                        }
                    Text("Durum: \(keep.status)").font(.footnote)
                }
                Section(header: Text("Durum"),
                        footer: Text("Bu uygulama sadece aramanın cevaplanıp cevaplanmadığını ve süresini gönderir. Arayan numarası ve konuşma içeriği gönderilmez.")) {
                    Text("Gönderilmeyi bekleyen: \(monitor.pending)")
                    Text("Son durum: \(monitor.lastStatus)")
                        .font(.footnote)
                    Button("Şimdi gönder") { monitor.flush() }
                }
                Section(header: Text("Son aramalar")) {
                    ForEach(monitor.history) { e in
                        HStack {
                            Text(label(e.type))
                            Spacer()
                            Text(e.ts.replacingOccurrences(of: "T", with: " ").replacingOccurrences(of: "Z", with: ""))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Çağrı Takip")
        }
        .navigationViewStyle(.stack)
    }
}
