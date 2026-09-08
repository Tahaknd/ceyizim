import SwiftUI
import SwiftData
import Charts

struct BudgetView: View {
    @Query(sort: \CeyizCategory.sortOrder) private var categories: [CeyizCategory]
    @Query private var items: [CeyizItem]
    @AppStorage(SettingsKeys.currency) private var currency = "TRY"

    private var stats: CeyizStats { CeyizStats(items: items) }

    private struct CategoryAmount: Identifiable {
        let id: PersistentIdentifier
        let name: String
        let color: Color
        let spent: Double
        let planned: Double
        var total: Double { spent + planned }
    }

    private var categoryAmounts: [CategoryAmount] {
        categories.map {
            let s = $0.summary
            return CategoryAmount(id: $0.persistentModelID, name: $0.name, color: $0.color.color,
                                  spent: s.spent, planned: s.planned)
        }
        .filter { $0.total > 0 }
        .sorted { $0.total > $1.total }
    }

    private var topPurchases: [CeyizItem] {
        items.filter { $0.status == .purchased && $0.spentAmount > 0 }
            .sorted { $0.spentAmount > $1.spentAmount }
            .prefix(5).map { $0 }
    }

    private var gifts: [CeyizItem] {
        items.filter { $0.status == .gifted }
            .sorted { ($0.purchaseDate ?? .distantPast) > ($1.purchaseDate ?? .distantPast) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    summaryCard
                    if stats.hasAnyMoney {
                        if !categoryAmounts.isEmpty { chartCard }
                        if !topPurchases.isEmpty { topPurchasesCard }
                        if stats.gifted > 0 { giftCard }
                    } else {
                        EmptyStateView(icon: "chart.bar.xaxis",
                                       title: "Henüz fiyat girilmedi",
                                       message: "Eşyalara tahmini veya ödenen fiyat eklediğinde harcama dağılımın burada görünür.")
                            .ceyizCard()
                    }
                }
                .padding(20)
            }
            .background(Palette.background)
            .navigationTitle("Harcamalar")
            .navigationDestination(for: CeyizItem.self) { ItemDetailView(item: $0) }
        }
    }

    // MARK: Summary

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Toplam Harcanan").font(Typo.caption).foregroundStyle(Palette.textSecondary)
                Text(Money.format(stats.spent, code: currency))
                    .font(Typo.number).foregroundStyle(Palette.textPrimary)
                Text("\(stats.purchased) alınan eşya")
                    .font(Typo.footnote).foregroundStyle(Palette.textSecondary)
            }
            if stats.plannedCost > 0 {
                VStack(alignment: .leading, spacing: 8) {
                    ProgressBar(progress: stats.spentShare, height: 12)
                    HStack {
                        Text("Tahmini toplamın %\(Int((stats.spentShare * 100).rounded()))'i harcandı")
                        Spacer()
                        Text(Money.format(stats.projectedTotal, code: currency))
                    }
                    .font(Typo.captionRegular)
                    .foregroundStyle(Palette.textSecondary)
                }
            }
            HStack(spacing: 10) {
                moneyStat("Planlanan", stats.plannedCost, Palette.textSecondary,
                          subtitle: "\(stats.planned) eşya")
                moneyStat("Tahmini toplam", stats.projectedTotal, Palette.rose,
                          subtitle: "harcanan + planlı")
                moneyStat("Hediye değeri", stats.giftValue, Palette.gold,
                          subtitle: "\(stats.gifted) hediye")
            }
        }
        .ceyizCard(padding: 18)
    }

    private func moneyStat(_ title: String, _ value: Double, _ color: Color, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title).font(Typo.caption2).foregroundStyle(Palette.textSecondary)
            Text(Money.compact(value, code: currency))
                .font(Typo.font(.bold, 15, relativeTo: .subheadline))
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(subtitle).font(Typo.font(.regular, 10, relativeTo: .caption2)).foregroundStyle(Palette.textSecondary).lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(color.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: Chart

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Kategorilere Göre").font(Typo.title).foregroundStyle(Palette.textPrimary)
            Chart {
                ForEach(categoryAmounts) { row in
                    BarMark(x: .value("Tutar", row.spent), y: .value("Kategori", row.name))
                        .foregroundStyle(by: .value("Tür", "Harcanan"))
                        .cornerRadius(4)
                    BarMark(x: .value("Tutar", row.planned), y: .value("Kategori", row.name))
                        .foregroundStyle(by: .value("Tür", "Planlanan"))
                        .cornerRadius(4)
                }
            }
            .chartForegroundStyleScale(["Harcanan": Palette.rose, "Planlanan": Palette.rose.opacity(0.3)])
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 4)) { value in
                    AxisGridLine().foregroundStyle(Palette.separator)
                    AxisValueLabel {
                        if let v = value.as(Double.self) {
                            Text(Money.compact(v, code: currency)).font(Typo.caption2).foregroundStyle(Palette.textSecondary)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks { _ in
                    AxisValueLabel().font(Typo.captionRegular).foregroundStyle(Palette.textPrimary)
                }
            }
            .chartLegend(position: .top, alignment: .leading)
            .frame(height: CGFloat(max(120, categoryAmounts.count * 44)))

            VStack(spacing: 0) {
                ForEach(categoryAmounts) { row in
                    HStack {
                        Circle().fill(row.color).frame(width: 10, height: 10)
                        Text(row.name).font(Typo.subheadline).foregroundStyle(Palette.textPrimary)
                        Spacer()
                        VStack(alignment: .trailing, spacing: 1) {
                            Text(Money.format(row.spent, code: currency))
                                .font(Typo.subheadlineSemibold.monospacedDigit()).foregroundStyle(Palette.textPrimary)
                            if row.planned > 0 {
                                Text("+ \(Money.format(row.planned, code: currency)) planlı")
                                    .font(Typo.caption2).foregroundStyle(Palette.textSecondary)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                    if row.id != categoryAmounts.last?.id { Divider() }
                }
            }
        }
        .ceyizCard()
    }

    private var giftCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(Palette.gold.opacity(0.15)).frame(width: 44, height: 44)
                    Image(systemName: "gift.fill").font(.system(size: 18)).foregroundStyle(Palette.gold)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Hediyeler").font(Typo.title).foregroundStyle(Palette.textPrimary)
                    Text(stats.giftValue > 0
                         ? "\(stats.gifted) hediye, yaklaşık \(Money.format(stats.giftValue, code: currency)) değerinde."
                         : "\(stats.gifted) hediye geldi.")
                        .font(Typo.captionRegular).foregroundStyle(Palette.textSecondary)
                }
            }
            VStack(spacing: 0) {
                ForEach(gifts.prefix(5)) { item in
                    NavigationLink(value: item) {
                        HStack {
                            Text(item.name).font(Typo.subheadlineMedium).foregroundStyle(Palette.textPrimary).lineLimit(1)
                            Spacer()
                            if !item.giftedBy.isEmpty {
                                Text(item.giftedBy).font(Typo.captionRegular).foregroundStyle(Palette.textSecondary).lineLimit(1)
                            }
                            Image(systemName: "chevron.right").font(Typo.caption2).foregroundStyle(Palette.textSecondary.opacity(0.6))
                        }
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                    if item.id != gifts.prefix(5).last?.id { Divider() }
                }
            }
        }
        .ceyizCard()
    }

    private var topPurchasesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("En Büyük Harcamalar").font(Typo.title).foregroundStyle(Palette.textPrimary)
            VStack(spacing: 0) {
                ForEach(topPurchases) { item in
                    NavigationLink(value: item) {
                        HStack(spacing: 12) {
                            if let cat = item.category {
                                CategoryIconView(icon: cat.icon, color: cat.color, size: 36)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.name).font(Typo.subheadlineMedium).foregroundStyle(Palette.textPrimary).lineLimit(1)
                                if let date = item.purchaseDate {
                                    Text(date.formatted(.dateTime.day().month(.abbreviated).locale(Money.locale)))
                                        .font(Typo.caption2).foregroundStyle(Palette.textSecondary)
                                }
                            }
                            Spacer()
                            Text(Money.format(item.spentAmount, code: currency))
                                .font(Typo.subheadlineSemibold.monospacedDigit())
                                .foregroundStyle(Palette.textPrimary)
                            Image(systemName: "chevron.right").font(Typo.captionRegular).foregroundStyle(Palette.textSecondary.opacity(0.6))
                        }
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                    if item.id != topPurchases.last?.id { Divider().padding(.leading, 48) }
                }
            }
        }
        .ceyizCard()
    }
}
