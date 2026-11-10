# Çağrı Takip (iOS) - deneme sürümü

Uygulama CallKit `CXCallObserver` ile telefondaki aramaların durumunu izler ve
sunucuya `cevaplandı / cevapsız / giden` + süre gönderir. Numara ve içerik GÖNDERİLMEZ.

## Derleme (Windows'ta Mac olmadan kontrol)
1. Klasörü GitHub'a it. `.github/workflows/ios-build.yml` macOS üzerinde derleme kontrolü yapar.
   (Kod Windows'ta derlenmedi; ilk hatayı burada göreceksin.)

## iPhone'a kurma (Mac gerekir, bir kereliğine)
1. Mac'te Xcode kur, `brew install xcodegen`, `cd ios && xcodegen generate`.
2. `CallTracker.xcodeproj` aç → Signing & Capabilities → kendi Apple Kimliğini (Personal Team) seç,
   `project.yml` içindeki bundle id'yi benzersiz yap.
3. iPhone'u kabloyla bağla, Run. (Ücretsiz Apple Kimliği ile imza 7 gün geçerli; 99$ hesapla 1 yıl.)
4. iPhone: Ayarlar → Genel → VPN ve Aygıt Yönetimi → geliştiriciye güven.

## Uygulamada
Sunucu adresi (https://...trycloudflare.com), anahtar (deneme123) ve personel adını gir.
Uygulamayı bir kez aç ve arka planda bırak. Başka telefondan ara; cevapla veya cevaplama.
Rapor: `<adres>/?key=deneme123`

## Bilinen sınırlar
- Uygulama çalışmıyorsa (iOS kapattıysa) o sırada gelen aramalar kaçar. Test et.
- Reddedilen arama da "cevapsız" görünür.
- Numara yok; "dönüş yapıldı" personelin sonraki giden aramasına göre yaklaşık hesaplanır.
