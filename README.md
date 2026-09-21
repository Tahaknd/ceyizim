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
  Support/                    AppSettings (anahtarlar, para/tarih formatı), SeedData (hazır liste), CSVExport, DemoData (yalnız DEBUG, ekran görüntüsü verisi)
  Theme/Theme.swift           Palette (aydınlık/karanlık), CategoryColor, Typo (Nunito), kart modifier
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
4. **Gizlilik etiketi:** "Veri toplanmıyor". Yaş: 4+.
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
Beş kare tek bir 6600×2868 panoramadan kesiliyor: zemin, ışık ve şeritler galeri boyunca kesintisiz akıyor, yani mağazada kaydırınca beş ayrı kart değil tek bir kompozisyon gibi duruyor. Cihazlar sırayla ±2,5° eğiliyor ve bir aşağı bir yukarı kayıyor; başlıklar ise sabit hizada kalıyor ki kaydırırken zıplamasın. Her karede ayrıca Türkçe başlık + alt başlık, altın ince çizgi, cihaz gövdesi ve normalize edilmiş durum çubuğu (9:41, dolu sinyal) var.

Başlıklar, eğim açısı ve dikey kayma betiğin içindeki `SHOTS` listesinde; zemin renkleri `GROUND_STOPS`, akan şeritler `RIBBONS`. `AppStore/screenshots/*.png` elle düzenlenmez.

`-ceyizimDemoData` olmadan yakalarsan mağaza sayfası 111 eşyanın 5'i alınmış, grafiği boş bir uygulama gösterir; dönüşümü asıl düşüren şey bu.

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
