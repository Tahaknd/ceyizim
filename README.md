# Çeyizim — iOS Çeyiz Takip Uygulaması

SwiftUI + SwiftData ile yazılmış, tamamen çevrimdışı çalışan çeyiz planlama ve bütçe takip uygulaması. iOS 17+, yalnızca iPhone, Türkçe.

## Proje yapısı
```
Ceyizim.xcodeproj/            Xcode projesi (Xcode 16+ synchronized folder)
Ceyizim/
  CeyizimApp.swift            Giriş, ModelContainer, RootView (onboarding ↔ sekmeler)
  Info.plist                  ITSAppUsesNonExemptEncryption=NO, tr bölgesi
  PrivacyInfo.xcprivacy       Gizlilik manifestosu (UserDefaults CA92.1)
  Models/                     CeyizCategory, CeyizItem (@Model), CeyizStats (hesaplar)
  Support/                    AppSettings (anahtarlar, para/tarih formatı), SeedData (hazır liste), CSVExport, DemoData (yalnız DEBUG, ekran görüntüsü verisi), Analytics (PostHog capture)
  Theme/Theme.swift           Palette (aydınlık/karanlık), CategoryColor, Typo (Nunito), kart modifier
  Theme/AccentTheme.swift     Kullanıcının seçtiği vurgu rengi ve ondan türeyen tonlar
  Fonts/                      Nunito (OFL lisanslı) — Info.plist UIAppFonts ile kayıtlı
  Views/
    Onboarding/               3 adımlı karşılama (isim, düğün tarihi, şablon)
    Home/                     Özet: geri sayım, ilerleme halkası, harcama kartı, kategoriler, öncelikliler, son tamamlananlar
    Items/                    Listem (arama/filtre/sıralama), eşya detay & form, kategori detay & form
    Budget/                   Harcamalar: toplam harcanan, tahmini toplam, Swift Charts grafiği, en büyük harcamalar, hediyeler
    Settings/                 Profil, para birimi, hazır liste, CSV dışa aktar, verileri sil, hakkında
    Components/               ProgressRing, ProgressBar, ItemRow, EmptyStateView, StatPill, ...
Tools/make-icon.py            App icon üretici (üç görünüm: aydınlık/karanlık/tinted)
Tools/make-appstore-screenshots.py  Ham simülatör kayıtlarını mağaza görsellerine çevirir
AppStore/                     Metaveri, gizlilik politikası, ekran görüntüleri
  screenshots/raw/            Ham simülatör kayıtları (girdi)
  screenshots/*.png           Yüklenecek son görseller (üretilir, elle düzenlenmez)
```

## İş mantığı
- **Durumlar:** Alınacak → Alındı / Hediye. Alındı ve Hediye "tamamlanmış" sayılır.
- **Harcanan:** yalnızca *Alındı* eşyalar; ödenen fiyat boşsa tahmini fiyat kullanılır.
- **Planlanan:** *Alınacak* eşyaların tahmini fiyatları. Tahmini toplam = harcanan + planlanan.
- **Hediye:** harcamaya girmez; değeri "hediyelerle tasarruf" olarak gösterilir.
- **Toplam bütçe yok:** kullanıcıdan bütçe istenmez; harcanan, planlanan ve tahmini toplam eşyalardan otomatik türetilir.
- **Kategori silme:** içindeki eşyalarla birlikte (cascade), onay sorulur.
- **Hazır liste:** idempotent; var olan kategori/eşya adları tekrar eklenmez.

## Derleme
```bash
xcodebuild -project Ceyizim.xcodeproj -scheme Ceyizim -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

## Yayın öncesi kontrol listesi (1.0)
1. **Signing:** Xcode > Ceyizim target > Signing & Capabilities → Team seç. Bundle ID `com.tahacaliskan.ceyizim` (kişisel Apple Developer hesabın; App Store Connect'te aynı ID ile kayıt oluştur).
2. **URL'ler:** `Ceyizim/Support/AppSettings.swift` içindeki `privacyPolicyURL` ve `supportURL` gerçek adreslerle değiştir. `AppStore/privacy-policy.md` içeriğini o adreste yayınla (zorunlu).
3. **App Store Connect:** Yeni uygulama → ad "Çeyizim", birincil dil Türkçe, SKU serbest. `AppStore/metadata.md` içeriğini kopyala.
4. **Gizlilik etiketi:** 1.0–1.2'de "Veri toplanmıyor" idi. 1.3'ten itibaren PostHog analitiği eklendiği için değişti — bkz. `AppStore/asc-fields.md` "App Privacy" bölümü. Yaş: 4+.
5. **Ekran görüntüleri:** `AppStore/screenshots/*.png` (6.9"). Aşağıdaki akışla üret, sonra yükle.
6. **Archive:** Xcode > Product > Archive (Any iOS Device) → Distribute → App Store Connect → Upload. Export compliance sorusu Info.plist sayesinde çıkmaz.
7. **Build'i sürüme bağla**, inceleme notlarını yapıştır, "Submit for Review".

## App Store görselleri

İkisi de Pillow ile çalışır, macOS/Linux fark etmez: `python3 -m pip install pillow`.

**Uygulama ikonu**
```bash
python3 Tools/make-icon.py        # Assets.xcassets/AppIcon.appiconset içine üç PNG yazar
```
Sandık + altın kalp; ölçüler `MARK_SCALE` / `MARK_DY` ile tek yerden ayarlanıyor. Renkler `Theme.swift` paletiyle aynı (gül `#BD5069→#A13E58`, fildişi `#F8F1E9`, altın `#D7A65C`).

**Mağaza ekran görüntüleri**
```bash
# 1) Simülatörü dolu veriyle aç: Xcode ▸ Edit Scheme ▸ Run ▸ Arguments ▸ "-ceyizimDemoData"
#    (DemoData yalnız DEBUG'ta derlenir; mağaza binary'sine girmez)
# 2) iPhone 17 Pro Max (6.9") simülatöründe ⌘S ile 5 ekranı yakala, 1320×2868 PNG olarak
#    AppStore/screenshots/raw/ içine aynı isimlerle koy
# 3) Çerçeve + başlık bas:
python3 Tools/make-appstore-screenshots.py            # hepsi
python3 Tools/make-appstore-screenshots.py 02-listem.png   # tek dosya
```
Altı kare tek bir 7920×2868 panoramadan kesiliyor: zemin, ışık, akan şeritler ve dantel madalyonlar galeri boyunca kesintisiz devam ediyor, yani mağazada kaydırınca altı ayrı kart değil tek bir kompozisyon gibi duruyor. Cihazlar sırayla ±2,5° eğilip bir aşağı bir yukarı kayıyor; başlıklar sabit hizada kalıyor ki kaydırırken zıplamasın.

Her karede: başlıkta altın vurgulu anahtar kelime, alt başlık, ortak altın ince çizgi, yan tuşları ve parlak iç kenarı olan cihaz gövdesi, normalize edilmiş durum çubuğu (9:41, dolu sinyal). Son kare (`06-gizlilik.png`) ham kayıt istemiyor — ikon, uygulama adı, gizlilik vaadi ve alttan yükselen bir telefonla galeriyi kapatıyor.

Ayarların hepsi betiğin içinde:

| Ne | Nerede |
|---|---|
| Başlık, alt başlık, eğim, dikey kayma | `SHOTS` |
| Başlıkta altın vurgu | Metni `*yıldız*` arasına al |
| Zemin renk geçişi | `GROUND_STOPS` |
| Akan şeritler | `RIBBONS` |
| Dantel madalyonlar | `MEDALLIONS` |
| Cihaz arkasındaki ışık | `GLOW` |

Betik iki boyut birden yazıyor, çünkü App Store Connect her ekran boyutu için ayrı kutu tutuyor ve tam eşleşmeyeni reddediyor:

| Klasör | Boyut | ASC kutusu |
|---|---|---|
| `AppStore/screenshots/` | 1320×2868 | iPhone 6.9" |
| `AppStore/screenshots/6.5-inch/` | 1284×2778 | iPhone 6.5" |

Yeni bir boyut gerekirse `EXTRA_SIZES` sözlüğüne bir satır ekle, kareler o boyutta da üretilir. 6.9" yüklediğinde Apple daha küçük iPhone'lar için onu kullanır; 6.5" kutusu ancak uygulama listesinde ayrıca istendiğinde gerekiyor.

`AppStore/screenshots/*.png` elle düzenlenmez. Kareler aynı panoramadan kesildiği için sırayı bozma — 01…06 numaraları galeri sırasıdır.

`-ceyizimDemoData` olmadan yakalarsan mağaza sayfası 111 eşyanın 5'i alınmış, grafiği boş bir uygulama gösterir; dönüşümü asıl düşüren şey bu.

## Tema rengi

Kullanıcı Ayarlar ▸ Görünüm'den vurgu rengini serbestçe seçiyor (iOS renk çarkı + 9 hazır ton). Seçim `Ceyizim/Theme/AccentTheme.swift` içinde tek bir `AccentTheme` değerine indirgeniyor: **ton (hue) ve doygunluk kullanıcının, parlaklık uygulamanın.**

Sebep şu: serbest renk seçiminin tek gerçek arızası buton üstündeki beyaz yazı. Açık sarı seçilse beyaz yazı okunmaz olurdu. `AccentTheme` bu yüzden parlaklığı kullanıcıdan almıyor; seçilen ton ve doygunlukta, hedef WCAG bağıl parlaklığına oturan parlaklığı ikili aramayla çözüyor. Hedef aralık `luminanceRange = 0.17...0.26`, yani beyaz kontrastı her zaman **3,4:1 – 4,8:1** arasında. (Tema özelliğinden önceki gül 3,5:1'di — yani hiçbir seçim mevcut duruma göre kötüleşemiyor.) Doygunluk da `0.30...0.82` bandına sıkıştırılıyor ki ne ölü gri ne de neon çıksın.

Vurgudan türeyen altı ton (`accentLight/Dark`, `deepLight/Dark`, `softLight/Dark`) ve kart tonu (`cardTintLight/Dark`), orijinal paletteki ölçülmüş oranlarla üretiliyor. Varsayılan tema (`AccentTheme.brand`) tam olarak eski gülü veriyor: `#D4667F / #B84D67 / #FBE4EA` ve karanlık karşılıkları.

Uygulama tarafında `Palette.rose`, `roseDeep`, `roseSoft` ve `cardSecondary` artık sabit değil, `ThemeStore.shared.accent`'ten hesaplanan property'ler. `ThemeStore` `@Observable` olduğu için vurgu rengi kullanan her ekran tema değişince kendiliğinden yeniden çiziliyor — yeniden başlatma yok. Metin, arka plan ve durum renkleri (`textPrimary`, `background`, `success`, `warning`, `danger`, `gold`) temadan bağımsız sabit; nötr oldukları için her tonla çalışıyorlar.

## Analitik (1.3'ten itibaren)

`Ceyizim/Support/Analytics.swift`, PostHog SDK'sı eklemek yerine onların HTTP capture endpoint'ine (`eu.i.posthog.com`, AB barındırma) doğrudan istek atan minik bir yardımcı. Kimlik, cihazda rastgele üretilip `UserDefaults`'ta saklanan bir UUID — isim, e-posta veya girilen hiçbir veriyle asla eşleşmiyor. Çeyiz listesinin **içeriği** (eşya adı, fiyat, foto, not) hiçbir zaman gönderilmiyor; yalnızca ekran görüntülemeleri ve buton tıklamaları (`item_marked_purchased`, `category_added`, `theme_changed` vb.) izleniyor.

Bu, 1.0–1.2'de verilen "hiç ağ isteği yok / veri toplanmıyor" beyanını değiştiriyor. Yeni bir sürüm gönderirken **App Store Connect'teki App Privacy etiketini ve App Review notlarını güncellemeyi unutma** — ayrıntı ve kopyala-yapıştır metinler `AppStore/asc-fields.md` içinde "GÜNCELLEME (1.3)" başlığı altında.

## Bilinen sınırlar / 1.1 fikirleri
- iCloud senkronizasyonu yok (CloudKit + entitlements gerekir).
- Yalnızca Türkçe; String Catalog eklenerek İngilizce kolayca eklenebilir.
- Widget / bildirim yok.

## Gizlilik / destek sayfalarını yayınlama (GitHub Pages)
`docs/` klasörü GitHub Pages için hazır: `docs/index.html` (tanıtım), `docs/gizlilik/index.html`, `docs/destek/index.html`.

`tahaknd/ceyizim` adlı bir GitHub reposu aç, projeyi push et, ardından **Settings > Pages > Source = `main` dalı + `/docs` klasörü** seç. Adresler tam olarak `AppSettings.swift` içindeki URL'lere denk gelir:

| Sayfa | Adres |
|---|---|
| Tanıtım (Marketing URL) | `https://tahaknd.github.io/ceyizim/` |
| Gizlilik politikası | `https://tahaknd.github.io/ceyizim/gizlilik` |
| Destek | `https://tahaknd.github.io/ceyizim/destek` |

Repo adı `ceyizim` DIŞINDA bir şey olursa adresler kayar; o durumda `AppSettings.swift` ve `metadata.md` içindeki iki URL'yi güncelle. E-posta `tahakndcaliskan@gmail.com` bir öneridir; kendi adresinle değiştir.
