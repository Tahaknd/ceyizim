#if DEBUG
import Foundation
import SwiftData

/// Screenshot fixtures. Excluded from release builds by the `#if DEBUG` guard.
///
/// Run the app with the launch argument `-ceyizimDemoData`
/// (Xcode ▸ Edit Scheme… ▸ Run ▸ Arguments) and the store is replaced, before
/// the first frame, with a trousseau that has been in use for months: a named
/// profile, a wedding date, purchases with prices and shops, a few gifts, and
/// an estimate on every remaining item.
///
/// Without this the App Store captures show 5 purchases out of 111 and an empty
/// spending chart, which reads as an empty app. See `Tools/make-appstore-screenshots.py`.
enum DemoData {

    static var isRequested: Bool {
        CommandLine.arguments.contains("-ceyizimDemoData")
    }

    /// Wipes the store, re-seeds the template, prices everything and marks a
    /// believable share of it as bought or gifted.
    static func apply(to context: ModelContext) {
        wipe(context)
        SeedData.apply(to: context)

        let categories = (try? context.fetch(FetchDescriptor<CeyizCategory>())) ?? []
        for category in categories {
            let base = estimateBase[category.name] ?? 2_000
            for item in category.items {
                item.estimatedPrice = estimate(for: item.name, base: base)
            }
        }

        var byName: [String: CeyizItem] = [:]
        for category in categories {
            for item in category.items where byName[item.name.lowercased()] == nil {
                byName[item.name.lowercased()] = item
            }
        }

        for fixture in fixtures {
            guard let item = byName[fixture.name.lowercased()] else { continue }
            item.status = fixture.status
            item.store = fixture.store
            item.notes = fixture.notes
            item.giftedBy = fixture.giftedBy
            switch fixture.status {
            case .purchased:
                item.actualPrice = fixture.price
                item.purchaseDate = Calendar.current.date(byAdding: .day, value: -fixture.daysAgo, to: .now)
            case .gifted:
                item.estimatedPrice = fixture.price
                item.purchaseDate = Calendar.current.date(byAdding: .day, value: -fixture.daysAgo, to: .now)
            case .planned:
                item.purchaseDate = nil
            }
            if fixture.priority != .normal { item.priority = fixture.priority }
        }

        try? context.save()

        let defaults = UserDefaults.standard
        defaults.set(true, forKey: SettingsKeys.hasOnboarded)
        defaults.set(true, forKey: SettingsKeys.seededTemplate)
        defaults.set("Zeynep", forKey: SettingsKeys.userName)
        defaults.set("TRY", forKey: SettingsKeys.currency)
        let wedding = Calendar.current.date(byAdding: .day, value: 168, to: .now) ?? .now
        defaults.set(wedding.timeIntervalSince1970, forKey: SettingsKeys.weddingDate)
    }

    private static func wipe(_ context: ModelContext) {
        for item in (try? context.fetch(FetchDescriptor<CeyizItem>())) ?? [] { context.delete(item) }
        for category in (try? context.fetch(FetchDescriptor<CeyizCategory>())) ?? [] { context.delete(category) }
        try? context.save()
    }

    // MARK: - Estimates

    /// Rough 2026 retail level per category, in ₺.
    private static let estimateBase: [String: Double] = [
        "Mutfak": 2_400,
        "Yatak Odası": 3_100,
        "Banyo": 1_500,
        "Salon": 3_600,
        "Beyaz Eşya": 26_000,
        "Mobilya": 21_000,
        "Dantel & El İşi": 1_200,
        "Kişisel": 1_400,
        "Elektronik": 9_000,
        "Temizlik & Düzen": 900,
    ]

    /// Spreads prices around the category level so lists and charts look real.
    /// Uses FNV-1a rather than `hashValue`, which is seeded per launch and would
    /// give a different price on every run.
    private static func estimate(for name: String, base: Double) -> Double {
        var hash: UInt64 = 0xcbf2_9ce4_8422_2325
        for byte in name.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 0x0000_0100_0000_01B3
        }
        let spread = 0.55 + Double(hash % 110) / 100.0       // 0.55 … 1.64
        return (base * spread / 50).rounded() * 50
    }

    // MARK: - Fixtures

    private struct Fixture {
        let name: String
        let status: ItemStatus
        let price: Double
        var store: String = ""
        var notes: String = ""
        var giftedBy: String = ""
        var daysAgo: Int = 30
        var priority: ItemPriority = .normal
    }

    private static let fixtures: [Fixture] = [
        // Beyaz eşya — the big-ticket purchases that carry the spending chart
        Fixture(name: "Buzdolabı", status: .purchased, price: 42_900, store: "Vestel", notes: "Çift kapılı, no-frost. 3 yıl garantili.", daysAgo: 96, priority: .high),
        Fixture(name: "Çamaşır makinesi", status: .purchased, price: 24_500, store: "Arçelik", notes: "9 kg, kampanyada alındı.", daysAgo: 96),
        Fixture(name: "Bulaşık makinesi", status: .purchased, price: 19_750, store: "Arçelik", daysAgo: 96),
        Fixture(name: "Ütü", status: .purchased, price: 2_850, store: "Teknosa", daysAgo: 41),
        Fixture(name: "Kettle", status: .gifted, price: 1_650, giftedBy: "Ayşe teyze", daysAgo: 34),
        Fixture(name: "Mikrodalga", status: .purchased, price: 6_400, store: "MediaMarkt", daysAgo: 62),

        // Mobilya
        Fixture(name: "Yatak odası takımı", status: .purchased, price: 58_000, store: "İstikbal", notes: "Ceviz rengi, bazalı. Teslimat düğünden 2 hafta önce.", daysAgo: 78, priority: .high),
        Fixture(name: "Koltuk takımı", status: .purchased, price: 46_500, store: "Bellona", notes: "Gri kumaş, yataklı.", daysAgo: 55, priority: .high),
        Fixture(name: "Komodin", status: .purchased, price: 4_200, store: "İstikbal", daysAgo: 78),
        Fixture(name: "TV ünitesi", status: .purchased, price: 9_800, store: "Bellona", daysAgo: 55),

        // Mutfak
        Fixture(name: "Yemek takımı", status: .gifted, price: 8_900, notes: "86 parça, porselen.", giftedBy: "Halam", daysAgo: 21, priority: .high),
        Fixture(name: "Tencere seti", status: .purchased, price: 12_400, store: "Karaca", notes: "Granit, 7 parça.", daysAgo: 47, priority: .high),
        Fixture(name: "Çay takımı", status: .purchased, price: 3_250, store: "Paşabahçe", daysAgo: 47),
        Fixture(name: "Kahve fincanı takımı", status: .gifted, price: 2_100, giftedBy: "Kuzenim Elif", daysAgo: 21),
        Fixture(name: "Çatal bıçak kaşık seti", status: .purchased, price: 4_600, store: "Karaca", daysAgo: 47),
        Fixture(name: "Çaydanlık", status: .purchased, price: 1_950, store: "Karaca", daysAgo: 47),
        Fixture(name: "Bıçak seti", status: .purchased, price: 2_300, store: "Karaca", daysAgo: 30),
        Fixture(name: "Su bardağı seti", status: .purchased, price: 1_150, store: "Paşabahçe", daysAgo: 30),
        Fixture(name: "Saklama kabı seti", status: .purchased, price: 1_480, store: "Karaca", daysAgo: 18),
        Fixture(name: "Cezve", status: .gifted, price: 850, giftedBy: "Anneannem", daysAgo: 21),

        // Yatak odası
        Fixture(name: "Nevresim takımı (çift kişilik)", status: .purchased, price: 6_900, store: "English Home", notes: "3 takım, pamuk saten.", daysAgo: 36, priority: .high),
        Fixture(name: "Yorgan", status: .purchased, price: 3_400, store: "English Home", daysAgo: 36),
        Fixture(name: "Yastık", status: .purchased, price: 2_200, store: "English Home", daysAgo: 36),
        Fixture(name: "Pike takımı", status: .gifted, price: 2_750, giftedBy: "Ablam", daysAgo: 14),

        // Banyo
        Fixture(name: "Havlu seti", status: .purchased, price: 3_100, store: "Madame Coco", notes: "Pudra rengi, 2 takım.", daysAgo: 25),
        Fixture(name: "Bornoz takımı", status: .gifted, price: 2_400, giftedBy: "Kayınvalidem", daysAgo: 14),
        Fixture(name: "Banyo paspası", status: .purchased, price: 780, store: "Madame Coco", daysAgo: 25),
        Fixture(name: "Hamam takımı", status: .purchased, price: 1_350, store: "Çarşı", daysAgo: 25),

        // Salon
        Fixture(name: "Halı", status: .purchased, price: 14_200, store: "Merinos", notes: "160×230, krem.", daysAgo: 52, priority: .high),
        Fixture(name: "Perde", status: .purchased, price: 8_600, store: "Yerel perdeci", notes: "Ölçü alındı, salon + yatak odası.", daysAgo: 29, priority: .high),
        Fixture(name: "Tül", status: .purchased, price: 4_300, store: "Yerel perdeci", daysAgo: 29),
        Fixture(name: "Kırlent", status: .purchased, price: 1_200, store: "Madame Coco", daysAgo: 25),

        // Dantel & el işi — the pieces that are made rather than bought
        Fixture(name: "Dantel masa örtüsü", status: .gifted, price: 3_500, notes: "El işi, anneannemin çeyizinden.", giftedBy: "Anneannem", daysAgo: 60),
        Fixture(name: "İşlemeli havlu", status: .gifted, price: 1_400, giftedBy: "Annem", daysAgo: 60),
        Fixture(name: "Dantel runner", status: .purchased, price: 650, store: "Çarşı", daysAgo: 25),

        // Kişisel & elektronik
        Fixture(name: "Televizyon", status: .purchased, price: 28_400, store: "MediaMarkt", notes: "55\", 4K.", daysAgo: 62, priority: .high),
        Fixture(name: "Takı kutusu", status: .gifted, price: 1_100, giftedBy: "Kuzenim Elif", daysAgo: 14),
        Fixture(name: "Pijama takımı", status: .purchased, price: 1_850, store: "Penti", daysAgo: 18),

        // Still on the list, but with the shop already picked
        Fixture(name: "Yemek masası & sandalye", status: .planned, price: 0, store: "Bellona", notes: "6 kişilik, açılır. Fiyat soruldu.", priority: .high),
        Fixture(name: "Elektrikli süpürge", status: .planned, price: 0, store: "Dyson", notes: "Kablosuz model bekleniyor, indirim takipte.", priority: .high),
        Fixture(name: "Duvar saati", status: .planned, price: 0, store: "Madame Coco", priority: .low),
    ]
}
#endif
