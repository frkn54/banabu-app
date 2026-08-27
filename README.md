# Banabu — iOS kabuğu (Capacitor)

> banabu.com.tr'yi App Store uygulaması yapan Capacitor kabuğu. **Android = Bubblewrap/TWA (ayrı, Play incelemesinde)**; bu klasör yalnız iOS.
> Sistem: `_projeler/app-fabrikasi/` · red-yememe + native paket: `../../ugc/notlar/MAGAZA-YAYIN-MASTER.md` §4 · App content cevapları: `../notlar/APP-MAGAZA-PAKETI.md`.
> App Fabrikası 2. app'in iOS kanadı — 26.08.2026 başlandı (UGC iskeletinden uyarlandı).

## Durum
- ✅ Proje iskeleti: `package.json` · `capacitor.config.json` (server.url=banabu.com.tr) · `www/offline.html` (banabu markalı) · `codemagic.yaml`.
- ⬜ Native katman (§Native) `ios/App` üretildikten SONRA eklenir — yalnız macOS/Codemagic build döngüsüyle test edilir (Windows'ta körlemesine yazılmaz).

## Neden Capacitor (salt-webview değil)
App Store salt sarmalayıcıyı **4.2 "minimum functionality"** ile reddeder (reviewer uçak modunda açar → beyaz ekran = ret). Geçme paketi: native push + native tab bar + markalı offline ekran + splash + Face ID.

## §Native — `ios/App` üretildikten sonra (4.2 geçme paketi — e-ticaret uyarlaması)
1. **APNs push** (`@capacitor/push-notifications`): izin akışı + token. (Sunucu tarafı push gönderimi banabu'da ileride; APNs ORTAK anahtar `43U28Q3WAR`.)
2. **Native tab bar** (Anasayfa / Ürünler / Sepet / Hesabım): her sekme ilgili banabu.com.tr yoluna gider (`/`, `/kategori/elbiseler/` veya `/magaza-ac/`, `/sepet/`, `/hesabim/`). Salt-webview görüntüsünden çıkaran #1 sinyal.
3. **Markalı offline ekran**: server erişilemezse `www/offline.html` göster (reachability + `WKNavigationDelegate didFailProvisionalNavigation` → local fallback). Tarayıcı hata sayfası ASLA.
4. **Splash + native yükleme** (config'te) + login/çerez kalıcılığı + Safari izi sıfır.
5. **Face ID hızlı giriş** (`capacitor-native-biometric`): açılışta biyometrik → kayıtlı oturum. +1 native özellik şartı.

## Ödeme (App Store 3.1 — fiziksel ürün)
Banabu **fiziksel ürün** (kadın giyim) satar → **IAP GEREKMEZ** (Apple 3.1.3(a) fiziksel mal istisnası). Ödeme web checkout'ta lisanslı sağlayıcı (PayTR/iyzico) ile. `allowNavigation`'da ödeme domainleri açık (3DS bank yönlendirmeleri test sırasında gözden geçirilecek — gerekirse genişletilir).

## Build (Codemagic, macOS — Apple sözleşmesi kabulünden sonra)
1. Codemagic → frkn54/furkan repo bağlı (var) → **App Store Connect API key** ekle (Integrations; issuer `0abfcdd0-...`, key `9JD3AL5ZL7`, `.p8`=app-fabrikasi) → adı `codemagic.yaml`'daki `APP_FABRIKASI_ASC` ile aynı olsun.
2. App Store Connect'te app oluştur (Bundle ID `com.banabu.app`, isim "Banabu") — Claude API'den (fastlane produce / ASC API) → `APP_STORE_APPLE_ID`'yi yaml'a yaz.
3. `ios-testflight` workflow → `npm ci` → `cap add ios` → `cap sync` → `pod install` → arşivle → **TestFlight**.
4. TestFlight Internal (review'suz) ile tam akış testi → App Store Connect metadata → review submit.

## Yerel geliştirme (opsiyonel, macOS gerekir)
```
npm install && npx cap add ios && npx cap sync ios && npx cap open ios
```
Windows'ta yalnız config düzenlenir; `cap add ios` + build macOS/Codemagic'te.
