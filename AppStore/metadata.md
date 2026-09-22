# Çeyizim — App Store Connect Metaverisi (1.0)

## Temel bilgiler
- **Uygulama adı:** Çeyizim
- **Alt başlık (30 karakter):** Çeyiz listesi ve bütçe takibi
- **Birincil dil:** Türkçe
- **Kategori:** Yaşam Tarzı (Lifestyle) · İkincil: Alışveriş (Shopping)
- **Fiyat:** Ücretsiz
- **Bundle ID (projede):** `com.tahacaliskan.ceyizim` — gerekiyorsa Xcode > Signing & Capabilities'ten değiştir.
- **Sürüm / Build:** 1.0 (1)
- **Cihaz:** Yalnızca iPhone, iOS 17.0+

## Tanıtım metni (170 karakter)
Çeyizini kategori kategori planla, aldıklarını işaretle, hediyeleri not et, harcamalarını tek bakışta gör. Tamamen çevrimdışı, sadece sana ait.

## Açıklama
Çeyizim, çeyiz hazırlığını sakin ve düzenli hale getiren kişisel çeyiz takip uygulamasıdır. Hangi eşyalar alındı, hangileri eksik, kim ne hediye etti, ne kadar harcandı; hepsi tek yerde.

HAZIR ÇEYİZ LİSTESİ
• Mutfak, yatak odası, banyo, salon, beyaz eşya, mobilya, dantel & el işi, kişisel, elektronik ve temizlik olmak üzere 10 kategori
• 100'den fazla öneri eşya ile saniyeler içinde başla
• İstediğini sil, kendi eşyalarını ve kategorilerini ekle

TAKİP ETMESİ KOLAY
• Eşyaları Alınacak, Alındı veya Hediye olarak işaretle
• Adet, öncelik ve "olmazsa olmaz" yıldızı ile önemlileri öne çıkar
• Fotoğraf, mağaza ve not ekle; beğendiğin modeli unutma
• Hızlı kaydırma ile tek harekette "Alındı" yap

HARCAMALARIN OTOMATİK TOPLANSIN
• Aldığın eşyaların fiyatı harcamalara otomatik eklenir, sen hesap yapma
• Planlanan alımlarla birlikte tahmini toplamı gör
• Kategorilere göre harcama grafiği ve en büyük harcamalar
• Hediyelerle ne kadar tasarruf ettiğini öğren

DÜĞÜNE GERİ SAYIM
• Düğün tarihini gir, kalan günleri ana ekranda takip et

GİZLİLİK ÖNCE GELİR
• Tüm verilerin yalnızca telefonunda saklanır; hesap yok, sunucu yok, reklam yok
• Listeni CSV olarak dışa aktarıp ailenle paylaşabilirsin

Mutlu yuvana giden yolda yanındayız. 🌸

## Anahtar kelimeler (100 karakter)
çeyiz,çeyiz listesi,düğün,gelin,evlilik,harcama,alışveriş listesi,ev eşyası,hediye,planlayıcı

## URL'ler (ZORUNLU — yayına almadan önce gerçek adreslerle değiştir)
- **Gizlilik politikası URL:** https://tahaknd.github.io/ceyizim/gizlilik  (`AppConfig.privacyPolicyURL`)
- **Destek URL:** https://tahaknd.github.io/ceyizim/destek  (`AppConfig.supportURL`)
- **Pazarlama URL:** isteğe bağlı

## Yaş derecelendirmesi
Tüm sorulara "Hayır" → **4+**. Sınırsız web erişimi yok, kumar yok, kullanıcı üretimi içerik paylaşımı yok.

## App Privacy (Gizlilik Etiketi)
> **1.3'ten itibaren geçersiz** — PostHog analitik eklendiği için artık "Data Not Collected" değil. Güncel etiket ve İnceleme Notları için `AppStore/asc-fields.md` içindeki "GÜNCELLEME (1.3)" notlarına bak.

- ~~Veri toplanıyor mu? → Hayır, veri toplamıyoruz (Data Not Collected).~~ (1.0–1.2 için geçerliydi)
- Çeyiz listesi verisi (eşya, fiyat, foto, isim, tarih) hâlâ yalnızca cihazda; ağa hiç çıkmıyor.
- Ekran görüntüleme/buton tıklaması gibi kimliksiz kullanım verisi artık PostHog'a (AB) gidiyor. `PrivacyInfo.xcprivacy` güncellendi (`NSPrivacyCollectedDataTypeProductInteraction`, linked: false, tracking: false).

## Dışa aktarım uyumluluğu (Export Compliance)
`ITSAppUsesNonExemptEncryption = NO` Info.plist'te ayarlı; App Store Connect bu soruyu sormaz.

## İnceleme notları (App Review Notes)
Çeyizim, geleneksel Türk çeyiz hazırlığı için tamamen çevrimdışı çalışan bir liste ve bütçe uygulamasıdır. Hesap oluşturma veya giriş gerektirmez. Tüm veriler yalnızca cihazda saklanır. Test için: uygulamayı açın, onboarding'de "Hazır çeyiz listesiyle başla"yı seçin; ardından Listem sekmesinden herhangi bir eşyayı sağa kaydırarak "Alındı" yapabilir, Harcamalar sekmesinde özet ve grafiği görebilirsiniz. Fotoğraf ekleme özelliği PhotosPicker kullanır ve izin gerektirmez.

**App Review Notes (English — App Store Connect'e BU sürümü yapıştır):**

Çeyizim is a fully offline checklist and budget app for preparing a traditional Turkish trousseau ("çeyiz"), which families assemble before a wedding. The app is in Turkish only.

No account, login, or network connection is required or used. The app makes zero network requests; all data is stored locally on the device with SwiftData. There is no analytics, advertising, or tracking SDK, and no in-app purchase.

How to test:
1. Launch the app and complete the 3-step onboarding. On the last step choose "Hazır çeyiz listesiyle başla" (start with the ready-made list) and tap "Hadi Başlayalım". This seeds 10 categories and 111 sample items.
2. Open the "Listem" (My List) tab and tap the circle next to any item to mark it as purchased, or swipe the row right for the same action.
3. Tap an item, choose the "..." menu > "Düzenle" (Edit), set "Durum" (Status) to "Alındı" (Purchased) and enter a price in "Ödenen" (Paid). Tap "Kaydet" (Save).
4. Open the "Harcamalar" (Spending) tab to see the total, the per-category chart, and the largest purchases.
5. "Ayarlar" (Settings) contains the currency picker, CSV export, delete-all-data, and the privacy policy and support links.

Photo attachment uses PhotosPicker, which requires no photo library permission prompt.

## Ekran görüntüleri
`AppStore/screenshots/` içindeki 6 PNG doğrudan yüklenir: iPhone 6.9" (1320×2868), başlıklı ve cihaz çerçeveli. 6.5" kutusu için aynı kareler `AppStore/screenshots/6.5-inch/` altında 1284×2778 olarak hazır — ASC tam eşleşmeyen boyutu reddediyor, o yüzden kutuya uygun klasörü kullan. Altısı tek bir panoramadan kesildiği için **sırayı bozma** — 01…06 numaraları galeri sırasıdır, zemin o sırada akıyor. App Store Connect 6.9" yüklendiğinde diğer iPhone boyutları için de kullanır.

Bunlar üretilmiş dosyalar — elle düzenleme. Ham simülatör kayıtları `AppStore/screenshots/raw/` altında; başlıkları veya düzeni değiştirmek için `Tools/make-appstore-screenshots.py` içindeki `SHOTS` listesini düzenleyip betiği tekrar çalıştır (ayrıntı: README ▸ App Store görselleri).

| # | Ekran | Başlık | Alt başlık |
|---|---|---|---|
| 1 | Özet | Çeyizin **tek bakışta** | İlerleme, harcama ve düğüne kalan gün |
| 2 | Listem | **Hazır listeyle** hemen başla | 10 kategori, 111 eşya — tek dokunuşla işaretle |
| 3 | Kategori | **Kategori kategori** ilerle | Mutfaktan yatak odasına, eksik kalan hiçbir şey yok |
| 4 | Harcamalar | Hesabı **uygulama tutsun** | Toplam, kategori grafiği ve en büyük harcamalar |
| 5 | Eşya detayı | Her eşyanın **kendi kartı** | Fotoğraf, mağaza, fiyat, hediye eden ve not |
| 6 | Kapanış | Çeyiz listen **sende** kalır | Eşyaların, fotoğrafların cihazında kalır. Hesap yok, reklam yok. |

Kalın yazılan kelimeler görselde altın renkte. 6. kare ham kayıt istemez: ikon, uygulama adı, üç vaat rozeti ve alttan yükselen bir telefonla kapanış kartı olarak üretilir.

Yeniden yakalarken şemaya `-ceyizimDemoData` argümanını ekle; aksi halde ekranlar neredeyse boş bir liste ve boş bir grafik gösterir.

## Uygulama ikonu
`Ceyizim/Assets.xcassets/AppIcon.appiconset` içindeki üç PNG (aydınlık / karanlık / tinted) `python3 Tools/make-icon.py` ile üretilir. 1024×1024 pazarlama ikonu olarak aydınlık sürüm kullanılır; Xcode arşivle birlikte otomatik yükler.
