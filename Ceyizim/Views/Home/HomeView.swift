import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \CeyizCategory.sortOrder) private var categories: [CeyizCategory]
    @Query private var items: [CeyizItem]

    @Binding var selectedTab: AppTab

    @AppStorage(SettingsKeys.userName) private var userName = ""
    @AppStorage(SettingsKeys.weddingDate) private var weddingTimestamp: Double = 0
    @AppStorage(SettingsKeys.currency) private var currency = "TRY"
    @AppStorage(SettingsKeys.seededTemplate) private var seededTemplate = false

    @State private var showingAddItem = false
    @State private var showingAddCategory = false

    private var stats: CeyizStats { CeyizStats(items: items) }

    private var mustHaves: [CeyizItem] {
        items.filter { $0.status == .planned && ($0.isMustHave || $0.priority == .high) }
            .sorted { ($0.priority.rawValue, $0.isMustHave ? 1 : 0) > ($1.priority.rawValue, $1.isMustHave ? 1 : 0) }
            .prefix(5).map { $0 }
    }

    private var recentlyCompleted: [CeyizItem] {
        items.filter { $0.status.isCompleted && $0.purchaseDate != nil }
            .sorted { ($0.purchaseDate ?? .distantPast) > ($1.purchaseDate ?? .distantPast) }
            .prefix(3).map { $0 }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    greeting
                    if categories.isEmpty {
                        emptyState
                    } else {
                        if stats.total > 0 && stats.progress >= 1 { celebration }
                        progressCard
                        spendingCard
                        categoriesSection
                        if !mustHaves.isEmpty { mustHaveSection }
                        if !recentlyCompleted.isEmpty { recentSection }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .background(Palette.background)
            .navigationTitle("Çeyizim")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingAddItem = true } label: {
                        Image(systemName: "plus.circle.fill").font(.title3)
                    }
                    .disabled(categories.isEmpty)
                }
            }
            .navigationDestination(for: CeyizCategory.self) { CategoryDetailView(category: $0) }
            .navigationDestination(for: CeyizItem.self) { ItemDetailView(item: $0) }
            .sheet(isPresented: $showingAddItem) { ItemFormView(mode: .create(category: nil)) }
            .sheet(isPresented: $showingAddCategory) { CategoryFormView(category: nil) }
        }
    }

    // MARK: Greeting + countdown

    private var timeGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Günaydın"
        case 12..<18: return "İyi günler"
        case 18..<23: return "İyi akşamlar"
        default: return "İyi geceler"
        }
    }

    private var greeting: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(userName.isEmpty ? "\(timeGreeting) 🌸" : "\(timeGreeting), \(userName) 🌸")
                .font(Typo.display)
                .foregroundStyle(Palette.textPrimary)
            if let date = WeddingCountdown.date(from: weddingTimestamp) {
                HStack(spacing: 8) {
                    Image(systemName: "calendar.badge.clock")
                        .foregroundStyle(Palette.rose)
                    Text(WeddingCountdown.headline(for: date))
                        .font(Typo.heading)
                        .foregroundStyle(Palette.rose)
                    Text("·").foregroundStyle(Palette.textSecondary)
                    Text(WeddingCountdown.subline(for: date))
                        .font(Typo.subheadline)
                        .foregroundStyle(Palette.textSecondary)
                }
            } else {
                Text(stats.total == 0 ? "Çeyiz yolculuğun burada başlıyor." : "Çeyiz yolculuğun güzel gidiyor.")
                    .font(Typo.subheadline)
                    .foregroundStyle(Palette.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Celebration

    private var celebration: some View {
        HStack(spacing: 14) {
            Text("🎉").font(.system(size: 34))
            VStack(alignment: .leading, spacing: 3) {
                Text("Çeyizin tamamlandı!").font(Typo.title).foregroundStyle(.white)
                Text("Tüm eşyalar alındı veya hediye geldi. Mutluluklar dileriz.")
                    .font(Typo.footnote).foregroundStyle(.white.opacity(0.9))
            }
            Spacer()
        }
        .padding(18)
        .background(
            LinearGradient(colors: [Palette.rose, Palette.roseDeep], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: Palette.rose.opacity(0.3), radius: 14, y: 6)
    }

    // MARK: Progress

    private var progressCard: some View {
        VStack(spacing: 16) {
            HStack(spacing: 20) {
                ZStack {
                    ProgressRing(progress: stats.progress, lineWidth: 11)
                    VStack(spacing: 0) {
                        Text(stats.percentText)
                            .font(Typo.font(.extraBold, 24, relativeTo: .title))
                            .foregroundStyle(Palette.textPrimary)
                        Text("tamam")
                            .font(Typo.font(.medium, 10, relativeTo: .caption2))
                            .foregroundStyle(Palette.textSecondary)
                    }
                }
                .frame(width: 104, height: 104)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Genel İlerleme")
                        .font(Typo.caption)
                        .foregroundStyle(Palette.textSecondary)
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(stats.completed)")
                            .font(Typo.number)
                            .foregroundStyle(Palette.rose)
                        Text("/ \(stats.total) eşya")
                            .font(Typo.subheadlineMedium)
                            .foregroundStyle(Palette.textSecondary)
                    }
                    Text(motivation)
                        .font(Typo.footnote)
                        .foregroundStyle(Palette.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            HStack(spacing: 10) {
                StatPill(title: "Alındı", value: "\(stats.purchased)", color: Palette.success)
                StatPill(title: "Hediye", value: "\(stats.gifted)", color: Palette.gold)
                StatPill(title: "Alınacak", value: "\(stats.planned)", color: Palette.rose)
            }
        }
        .ceyizCard(padding: 18)
    }

    private var motivation: String {
        switch stats.progress {
        case 0: return "İlk eşyayı işaretlemek için dokun."
        case ..<0.25: return "Güzel bir başlangıç yaptın!"
        case ..<0.5: return "Çeyrek yolu geçtin, devam!"
        case ..<0.75: return "Yarısından fazlası tamam 💪"
        case ..<1: return "Son düzlüktesin!"
        default: return "Çeyizin tamamlandı! 🎉"
        }
    }

    // MARK: Spending

    private var spendingCard: some View {
        Button { selectedTab = .budget } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "turkishlirasign.circle.fill").foregroundStyle(Palette.rose)
                        Text("Harcamalar").foregroundStyle(Palette.textPrimary)
                    }
                    .font(Typo.heading)
                    Spacer()
                    Image(systemName: "chevron.right").font(Typo.captionRegular).foregroundStyle(Palette.textSecondary)
                }
                if stats.hasAnyMoney {
                    HStack(alignment: .firstTextBaseline) {
                        Text(Money.format(stats.spent, code: currency))
                            .font(Typo.numberSm)
                            .foregroundStyle(Palette.textPrimary)
                        Text("harcandı")
                            .font(Typo.subheadline)
                            .foregroundStyle(Palette.textSecondary)
                        Spacer()
                        if stats.plannedCost > 0 {
                            Text("+ \(Money.format(stats.plannedCost, code: currency)) planlı")
                                .font(Typo.caption)
                                .foregroundStyle(Palette.textSecondary)
                        }
                    }
                    if stats.plannedCost > 0 {
                        ProgressBar(progress: stats.spentShare)
                        Text("Tahmini toplam \(Money.format(stats.projectedTotal, code: currency)) · %\(Int((stats.spentShare * 100).rounded())) tamam")
                            .font(Typo.captionRegular)
                            .foregroundStyle(Palette.textSecondary)
                    }
                    if stats.giftValue > 0 {
                        Label("Hediyelerle \(Money.format(stats.giftValue, code: currency)) tasarruf", systemImage: "gift.fill")
                            .font(Typo.captionRegular)
                            .foregroundStyle(Palette.gold)
                    }
                } else {
                    Text("Eşyalara fiyat girdiğinde harcamaların burada toplanır.")
                        .font(Typo.subheadline)
                        .foregroundStyle(Palette.textSecondary)
                }
            }
            .ceyizCard()
        }
        .buttonStyle(.plain)
    }

    // MARK: Categories

    private var categoriesSection: some View {
        VStack(spacing: 12) {
            SectionHeader(title: "Kategoriler", actionTitle: "Yeni") { showingAddCategory = true }
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                ForEach(categories) { category in
                    NavigationLink(value: category) {
                        CategoryCard(category: category, currency: currency)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: Must-haves

    private var mustHaveSection: some View {
        VStack(spacing: 12) {
            SectionHeader(title: "Öncelikli Alınacaklar")
            itemList(mustHaves)
        }
    }

    private var recentSection: some View {
        VStack(spacing: 12) {
            SectionHeader(title: "Son Tamamlananlar", actionTitle: "Tümü") { selectedTab = .list }
            itemList(recentlyCompleted)
        }
    }

    private func itemList(_ list: [CeyizItem]) -> some View {
        VStack(spacing: 0) {
            ForEach(list) { item in
                NavigationLink(value: item) {
                    ItemRow(item: item, currency: currency, showCategory: true)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
                if item.id != list.last?.id {
                    Divider().padding(.leading, 52)
                }
            }
        }
        .ceyizCard(padding: 4)
    }

    // MARK: Empty

    private var emptyState: some View {
        VStack(spacing: 16) {
            EmptyStateView(icon: "shippingbox.fill",
                           title: "Çeyiz sandığın henüz boş",
                           message: "Hazır listeyle saniyeler içinde başlayabilir veya kendi kategorilerini oluşturabilirsin.")
            VStack(spacing: 10) {
                Button {
                    SeedData.apply(to: context)
                    seededTemplate = true
                    Haptics.success()
                } label: { Label("Hazır listeyle başla", systemImage: "wand.and.stars") }
                    .buttonStyle(PrimaryButtonStyle())
                Button { showingAddCategory = true } label: {
                    Text("Kendi kategorimi oluştur")
                        .font(Typo.heading)
                        .foregroundStyle(Palette.rose)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
            }
        }
        .ceyizCard()
    }
}

struct CategoryCard: View {
    let category: CeyizCategory
    var currency: String

    var body: some View {
        let s = category.summary
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                CategoryIconView(icon: category.icon, color: category.color, size: 42)
                Spacer()
                if s.total > 0 && s.progress >= 1 {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(Palette.success)
                }
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(category.name)
                    .font(Typo.heading)
                    .foregroundStyle(Palette.textPrimary)
                    .lineLimit(1)
                Text(s.total == 0 ? "Henüz eşya yok" : "\(s.completed) / \(s.total) tamam")
                    .font(Typo.captionRegular)
                    .foregroundStyle(Palette.textSecondary)
                if s.spent > 0 {
                    Text(Money.format(s.spent, code: currency))
                        .font(Typo.caption)
                        .foregroundStyle(category.color.color)
                }
            }
            ProgressBar(progress: s.progress, color: category.color.color, height: 6,
                        track: category.color.color.opacity(0.15))
        }
        .ceyizCard(padding: 14)
    }
}
