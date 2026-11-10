import SwiftUI

struct ContentView: View {
    @EnvironmentObject var monitor: CallMonitor
    @AppStorage("serverURL") private var serverURL = ""
    @AppStorage("apiKey") private var apiKey = "deneme123"
    @AppStorage("employee") private var employee = ""

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
                Section(header: Text("Durum"),
                        footer: Text("Bu uygulama sadece aramanın cevaplanıp cevaplanmadığını ve süresini gönderir. Arayan numarası ve konuşma içeriği gönderilmez.")) {
                    Text("Gönderilmeyi bekleyen: \(monitor.pending)")
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
