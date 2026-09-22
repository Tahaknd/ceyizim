# Çeyizim — App Store Connect alan referansı

App Store Connect arayüzü İngilizce olduğu için başlıklar orada gördüğün İngilizce isimlerle eşleşiyor. İçerik (uygulama adı, açıklama vb.) Türkçe kalıyor çünkü **Primary Language = Turkish** seçeceğiz — App Store'da Türk kullanıcılara Türkçe görünecek.

---

## 1. New App (Apps → + → New App)

| Alan | Değer |
|---|---|
| Platforms | iOS |
| Name | `Çeyizim` |
| Primary Language | `Turkish` |
| Bundle ID | `com.tahacaliskan.ceyizim` (listede yoksa önce developer.apple.com/account → Identifiers'tan kaydet) |
| SKU | serbest, örn. `ceyizim001` |
| Full Access | (varsayılan, dokunma) |

---

## 2. App Information

| Alan | Değer |
|---|---|
| Subtitle *(30 karakter)* | `Çeyiz listesi ve bütçe takibi` |
| Category — Primary | `Lifestyle` |
| Category — Secondary | `Shopping` |
| Content Rights | "Contains no third-party content" seç (kod/asset'lerin hepsi kendine ait) |
| Age Rating | Questionnaire'i aç, aşağıdaki tabloya göre hepsine **No/None** işaretle → sonuç **4+** çıkacak |

**Age Rating questionnaire — her satıra "None"/"No":**
Cartoon or Fantasy Violence, Realistic Violence, Sexual Content or Nudity, Profanity or Crude Humor, Alcohol/Tobacco/Drug Use, Mature/Suggestive Themes, Horror/Fear Themes, Medical/Treatment Information, Gambling (Simulated), Unrestricted Web Access → **No**, User Generated Content → **No**, Contests → **No**.

---

## 3. Pricing and Availability

| Alan | Değer |
|---|---|
| Price | `Free` |
| Availability | tüm ülkeler (varsayılan) bırakılabilir |

---

## 4. App Privacy

**GÜNCELLEME (1.3, PostHog eklendi):** Artık "Data Not Collected" DEĞİL. Etiketi yeniden doldurman gerekiyor:

| Soru | Cevap |
|---|---|
| "Do you or your third-party partners collect data from this app?" | **Yes** |
| Data type | **Product Interaction** (App Store Connect'te bu kategoriyi seç) |
| "Is this data linked to the user's identity?" | **No** — rastgele, cihazda üretilen bir kimlik kullanıyoruz, isim/e-posta/hesapla asla eşleşmiyor |
| "Is this data used to track users?" | **No** — reklam amaçlı değil, başka şirketlerin uygulama/siteleriyle paylaşılmıyor, ATT gerekmiyor |
| Purpose | **Analytics** |

Diğer tüm veri türleri (eşya adı, fiyat, fotoğraf, isim, düğün tarihi vb.) hâlâ **cihazda kalıyor**, bunlar için "collect" işaretlemiyoruz — sadece "Product Interaction" (ekran görüntüleme + buton tıklaması) PostHog'a gidiyor.

Kod tarafı: `PrivacyInfo.xcprivacy`'de `NSPrivacyCollectedDataTypeProductInteraction` girişi eklendi (linked: false, tracking: false, purpose: Analytics). `Ceyizim/Support/Analytics.swift` PostHog'un capture endpoint'ine (`eu.i.posthog.com`) doğrudan HTTP isteğiyle event gönderiyor.

---

## 5. 1.0 Prepare for Submission (sürüm sayfası)

| Alan (İngilizce) | Ne yazılacak |
|---|---|
| **Promotional Text** *(170 karakter, istediğin zaman değiştirilebilir)* | `Çeyizini kategori kategori planla, aldıklarını işaretle, hediyeleri not et, harcamalarını tek bakışta gör. Tamamen çevrimdışı, sadece sana ait.` |
| **Description** | metadata.md'deki "Açıklama" bölümünün tamamı (aşağıda tekrar var) |
| **Keywords** *(100 karakter, virgülle)* | `çeyiz,çeyiz listesi,düğün,gelin,evlilik,harcama,alışveriş listesi,ev eşyası,hediye,planlayıcı` |
| **Support URL** | `https://tahaknd.github.io/ceyizim/destek` |
| **Marketing URL** *(opsiyonel)* | `https://tahaknd.github.io/ceyizim/` |
| **Version** | `1.0` |
| **Copyright** | `2026 Taha Çalışkan` |
| **App Store Icon** | otomatik gelir (arşivden) |
| **Screenshots — iPhone 6.9" Display** | `AppStore/screenshots/*.png` (5 dosya, sırayla 01→05) |
| **Build** | arşiv yüklendikten sonra buradan seçilecek (henüz yok) |

### Description (kopyala-yapıştır)

```
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
```

---

## 6. App Review Information (sürüm sayfasının altında)

| Alan | Değer |
|---|---|
| Sign-in required | **No** (kapalı bırak — hesap yok) |
| Contact — First/Last Name | kendi adın |
| Contact — Phone | kendi numaran |
| Contact — Email | `tahakndcaliskan@gmail.com` |
| **Notes** | aşağıdaki İngilizce metni yapıştır |

**GÜNCELLEME (1.3):** Aşağıdaki metin artık "no analytics" diyor, ki 1.3'ten itibaren doğru değil — PostHog eklendi. Yeni sürümü göndermeden önce ikinci paragrafı şuna çevir:

```
No account or login is required or used. All trousseau-list data (item names, prices, notes, photos) is stored only on the device and never leaves it. The app sends anonymous product-interaction analytics (screen views and button taps, tied to a random on-device identifier — never linked to any personal data) to PostHog (EU-hosted) to help us understand feature usage. There is no advertising or tracking SDK, and no in-app purchase.
```

### Review Notes (1.0/1.1/1.2 için kullanılan eski metin, referans)

```
Çeyizim is a fully offline checklist and budget app for preparing a traditional Turkish trousseau ("çeyiz"), which families assemble before a wedding. The app is in Turkish only.

No account, login, or network connection is required or used. The app makes zero network requests; all data is stored locally on the device with SwiftData. There is no analytics, advertising, or tracking SDK, and no in-app purchase.

How to test:
1. Launch the app and complete the 3-step onboarding. On the last step choose "Hazır çeyiz listesiyle başla" (start with the ready-made list) and tap "Hadi Başlayalım". This seeds 10 categories and sample items.
2. Open the "Listem" (My List) tab and tap the circle next to any item to mark it as purchased, or swipe the row right for the same action.
3. Tap an item, choose the "..." menu > "Düzenle" (Edit), set "Durum" (Status) to "Alındı" (Purchased) and enter a price in "Ödenen" (Paid). Tap "Kaydet" (Save).
4. Open the "Harcamalar" (Spending) tab to see the total, the per-category chart, and the largest purchases.
5. "Ayarlar" (Settings) contains the currency picker, CSV export, delete-all-data, and the privacy policy and support links.

Photo attachment uses PhotosPicker, which requires no photo library permission prompt.
```

---

## 7. Version Release

| Alan | Değer |
|---|---|
| Version Release | `Manually release this version` (önerilir — Apple onayladıktan sonra sen ne zaman yayınlanacağına karar verirsin) |

---

## 8. Export Compliance

Bu soru muhtemelen otomatik geçilecek çünkü `ITSAppUsesNonExemptEncryption = false` zaten Info.plist'te. Sorarsa: **"No"** (özel/non-exempt şifreleme kullanmıyoruz, sadece standart HTTPS/iOS sistem şifrelemesi de yok çünkü ağ isteği hiç yok).
