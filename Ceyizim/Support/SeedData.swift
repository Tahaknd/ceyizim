import Foundation
import SwiftData

/// A ready-made Turkish trousseau list. Users can start with it during onboarding
/// or add it later from Settings. Adding is idempotent: existing categories and
/// items (matched by name) are never duplicated.
enum SeedData {
    struct Item {
        let name: String
        let quantity: Int
        let mustHave: Bool
        init(_ name: String, qty: Int = 1, mustHave: Bool = false) {
            self.name = name; self.quantity = qty; self.mustHave = mustHave
        }
    }

    struct Category {
        let name: String
        let icon: String
        let color: CategoryColor
        let items: [Item]
    }

    static let categories: [Category] = [
        Category(name: "Mutfak", icon: "fork.knife", color: .rose, items: [
            Item("Yemek takımı", mustHave: true), Item("Çay takımı", mustHave: true),
            Item("Kahve fincanı takımı", mustHave: true), Item("Su bardağı seti"),
            Item("Tencere seti", mustHave: true), Item("Tava seti"),
            Item("Çatal bıçak kaşık seti", mustHave: true), Item("Servis tabakları"),
            Item("Kahvaltılık takımı"), Item("Baharatlık seti"), Item("Saklama kabı seti"),
            Item("Bıçak seti"), Item("Kesme tahtası"), Item("Çaydanlık", mustHave: true),
            Item("Cezve"), Item("Sürahi"), Item("Salata kasesi"), Item("Pasta tabağı"),
            Item("Ekmek sepeti"), Item("Tepsi seti"), Item("Kek kalıbı"), Item("Süzgeç"),
            Item("Mutfak havlusu", qty: 6), Item("Fırın eldiveni"),
        ]),
        Category(name: "Yatak Odası", icon: "bed.double.fill", color: .lilac, items: [
            Item("Nevresim takımı (çift kişilik)", qty: 3, mustHave: true), Item("Yastık", qty: 4, mustHave: true),
            Item("Yorgan", mustHave: true), Item("Battaniye", qty: 2), Item("Pike takımı", qty: 2),
            Item("Yatak örtüsü"), Item("Alez"), Item("Çarşaf", qty: 3), Item("Yastık kılıfı", qty: 6),
            Item("Yastık alezi", qty: 4), Item("Dekoratif kırlent", qty: 2),
        ]),
        Category(name: "Banyo", icon: "shower.fill", color: .sky, items: [
            Item("Havlu seti", qty: 2, mustHave: true), Item("Bornoz takımı", mustHave: true),
            Item("Banyo paspası", qty: 2), Item("Duş perdesi"), Item("Sabunluk seti"),
            Item("Çamaşır sepeti"), Item("Hamam takımı"), Item("Kese & lif"),
            Item("Ev terliği", qty: 2), Item("El havlusu", qty: 6),
        ]),
        Category(name: "Salon", icon: "sofa.fill", color: .peach, items: [
            Item("Kırlent", qty: 4), Item("Halı", mustHave: true), Item("Perde", mustHave: true),
            Item("Tül", mustHave: true), Item("Runner"), Item("Abajur"), Item("Sehpa örtüsü"),
            Item("Vazo"), Item("Mumluk seti"), Item("Duvar saati"), Item("Tablo"),
            Item("Koltuk şalı"), Item("Dekoratif tabak"),
        ]),
        Category(name: "Beyaz Eşya", icon: "refrigerator.fill", color: .mint, items: [
            Item("Buzdolabı", mustHave: true), Item("Çamaşır makinesi", mustHave: true),
            Item("Bulaşık makinesi", mustHave: true), Item("Fırın", mustHave: true), Item("Ocak"),
            Item("Davlumbaz"), Item("Elektrikli süpürge"), Item("Ütü", mustHave: true),
            Item("Mikrodalga"), Item("Kettle"), Item("Tost makinesi"), Item("Blender seti"),
            Item("Kahve makinesi"), Item("Mutfak robotu"), Item("Saç kurutma makinesi"),
        ]),
        Category(name: "Mobilya", icon: "chair.lounge.fill", color: .gold, items: [
            Item("Yatak odası takımı", mustHave: true), Item("Yatak", mustHave: true),
            Item("Koltuk takımı", mustHave: true), Item("Yemek masası & sandalye"),
            Item("TV ünitesi"), Item("Orta sehpa"), Item("Yan sehpa", qty: 2),
            Item("Ayakkabılık"), Item("Portmanto"), Item("Komodin", qty: 2),
        ]),
        Category(name: "Dantel & El İşi", icon: "scissors", color: .plum, items: [
            Item("Dantel masa örtüsü"), Item("Dantel sehpa takımı"), Item("Yatak başlığı işlemesi"),
            Item("İşlemeli havlu", qty: 4), Item("Peçete seti"), Item("Kanaviçe pano"),
            Item("Dantel runner"), Item("Vitrin danteli"),
        ]),
        Category(name: "Kişisel", icon: "sparkles", color: .coral, items: [
            Item("Gecelik", qty: 2), Item("Pijama takımı", qty: 3), Item("Sabahlık"),
            Item("Ev kıyafeti", qty: 2), Item("Parfüm"), Item("Takı kutusu"),
            Item("Makyaj aynası"),
        ]),
        Category(name: "Elektronik", icon: "tv.fill", color: .lavender, items: [
            Item("Televizyon", mustHave: true), Item("Ses sistemi"), Item("Saç düzleştirici"),
            Item("Elektrikli battaniye"), Item("Isıtıcı / vantilatör"),
        ]),
        Category(name: "Temizlik & Düzen", icon: "basket.fill", color: .sage, items: [
            Item("Ütü masası", mustHave: true), Item("Çamaşır kurutma askısı"), Item("Kova & paspas seti"),
            Item("Çöp kovası", qty: 2), Item("Kavanoz seti"), Item("Askı seti"),
            Item("Dolap düzenleyici"), Item("Süpürge & faraş"),
        ]),
    ]

    /// Inserts the template. Returns the number of items added.
    @discardableResult
    static func apply(to context: ModelContext) -> Int {
        let existingCategories = (try? context.fetch(FetchDescriptor<CeyizCategory>())) ?? []
        var byName = Dictionary(uniqueKeysWithValues: existingCategories.map { ($0.name.lowercased(), $0) })
        var nextOrder = (existingCategories.map(\.sortOrder).max() ?? -1) + 1
        var added = 0

        for (index, template) in categories.enumerated() {
            let key = template.name.lowercased()
            let category: CeyizCategory
            if let found = byName[key] {
                category = found
            } else {
                category = CeyizCategory(name: template.name, icon: template.icon,
                                         color: template.color, sortOrder: nextOrder + index)
                context.insert(category)
                byName[key] = category
            }
            let existingItemNames = Set(category.items.map { $0.name.lowercased() })
            for item in template.items where !existingItemNames.contains(item.name.lowercased()) {
                let model = CeyizItem(name: item.name, quantity: item.quantity,
                                      isMustHave: item.mustHave, category: category)
                context.insert(model)
                added += 1
            }
        }
        nextOrder += categories.count
        try? context.save()
        return added
    }

    /// Curated SF Symbols offered in the category editor.
    static let iconChoices: [String] = [
        "fork.knife", "cup.and.saucer.fill", "bed.double.fill", "shower.fill", "sofa.fill",
        "refrigerator.fill", "chair.lounge.fill", "scissors", "sparkles", "tv.fill", "basket.fill",
        "lamp.table.fill", "washer.fill", "oven.fill", "frying.pan.fill", "wineglass.fill",
        "birthday.cake.fill", "gift.fill", "heart.fill", "house.fill", "lightbulb.fill",
        "shippingbox.fill", "bag.fill", "tshirt.fill", "curtains.closed", "leaf.fill",
        "star.fill", "paintpalette.fill", "book.fill", "pawprint.fill", "figure.2.and.child.holdinghands",
        "sun.max.fill", "moon.stars.fill", "camera.fill", "music.note", "gamecontroller.fill",
    ]
}
