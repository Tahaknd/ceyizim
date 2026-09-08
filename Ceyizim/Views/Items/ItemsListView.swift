import SwiftUI
import SwiftData

enum ItemSort: String, CaseIterable, Identifiable {
    case category, name, newest, priceDesc, priority
    var id: String { rawValue }
    var title: String {
        switch self {
        case .category: return "Kategoriye göre"
        case .name: return "İsme göre"
        case .newest: return "En yeni"
        case .priceDesc: return "Fiyat (yüksekten)"
        case .priority: return "Önceliğe göre"
        }
    }
}

struct ItemsListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \CeyizItem.createdAt, order: .reverse) private var items: [CeyizItem]
    @Query(sort: \CeyizCategory.sortOrder) private var categories: [CeyizCategory]
    @AppStorage(SettingsKeys.currency) private var currency = "TRY"

    @State private var searchText = ""
    @State private var statusFilter: ItemStatus? = nil
    @State private var categoryFilter: PersistentIdentifier? = nil
    @State private var sort: ItemSort = .category
    @State private var showingAdd = false
    @State private var itemToDelete: CeyizItem? = nil

    private var filtered: [CeyizItem] {
        var result = items
        if let statusFilter { result = result.filter { $0.status == statusFilter } }
        if let categoryFilter { result = result.filter { $0.category?.persistentModelID == categoryFilter } }
        let q = searchText.trimmingCharacters(in: .whitespaces)
        if !q.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(q) ||
                $0.store.localizedCaseInsensitiveContains(q) ||
                $0.notes.localizedCaseInsensitiveContains(q) ||
                ($0.category?.name.localizedCaseInsensitiveContains(q) ?? false)
            }
        }
        switch sort {
        case .category, .newest: break
        case .name: result.sort { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        case .priceDesc: result.sort { ($0.displayPrice ?? 0) > ($1.displayPrice ?? 0) }
        case .priority: result.sort { ($0.priority.rawValue, $0.isMustHave ? 1 : 0) > ($1.priority.rawValue, $1.isMustHave ? 1 : 0) }
        }
        return result
    }

    private struct Group: Identifiable {
        let id: String
        let title: String
        let color: CategoryColor?
        let items: [CeyizItem]
    }

    private var groups: [Group] {
        guard sort == .category else {
            return [Group(id: "all", title: "", color: nil, items: filtered)]
        }
        var buckets: [String: [CeyizItem]] = [:]
        for item in filtered {
            let key = item.category.map { "\($0.sortOrder)|\($0.name)" } ?? "zzz|Diğer"
            buckets[key, default: []].append(item)
        }
        return buckets.keys.sorted().map { key in
            let list = buckets[key]!.sorted {
                if $0.status.isCompleted != $1.status.isCompleted { return !$0.status.isCompleted }
                return $0.name.localizedStandardCompare($1.name) == .orderedAscending
            }
            let cat = list.first?.category
            return Group(id: key, title: cat?.name ?? "Diğer", color: cat?.color, items: list)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                filterChips
                if items.isEmpty {
                    EmptyStateView(icon: "checklist",
                                   title: "Listen henüz boş",
                                   message: "İlk eşyanı ekleyerek çeyiz listeni oluşturmaya başla.",
                                   actionTitle: "Eşya Ekle") { showingAdd = true }
                    Spacer()
                } else if filtered.isEmpty {
                    EmptyStateView(icon: "magnifyingglass",
                                   title: "Sonuç bulunamadı",
                                   message: "Aramanı veya filtreleri değiştirmeyi dene.")
                    Spacer()
                } else {
                    list
                }
            }
            .background(Palette.background)
            .navigationTitle("Listem")
            .searchable(text: $searchText, prompt: "Eşya, mağaza veya kategori ara")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Picker("Sırala", selection: $sort) {
                            ForEach(ItemSort.allCases) { Text($0.title).tag($0) }
                        }
                        Divider()
                        Picker("Kategori", selection: $categoryFilter) {
                            Text("Tüm kategoriler").tag(PersistentIdentifier?.none)
                            ForEach(categories) { cat in
                                Label(cat.name, systemImage: cat.icon).tag(Optional(cat.persistentModelID))
                            }
                        }
                    } label: {
                        Image(systemName: categoryFilter == nil && sort == .category
                              ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingAdd = true } label: { Image(systemName: "plus.circle.fill").font(.title3) }
                }
            }
            .navigationDestination(for: CeyizItem.self) { ItemDetailView(item: $0) }
            .navigationDestination(for: CeyizCategory.self) { CategoryDetailView(category: $0) }
            .sheet(isPresented: $showingAdd) {
                let preset = categories.first { $0.persistentModelID == categoryFilter }
                ItemFormView(mode: .create(category: preset))
            }
            .confirmationDialog("Bu eşyayı silmek istediğine emin misin?",
                                isPresented: Binding(get: { itemToDelete != nil }, set: { if !$0 { itemToDelete = nil } }),
                                titleVisibility: .visible) {
                Button("Sil", role: .destructive) {
                    if let item = itemToDelete { context.delete(item) }
                    itemToDelete = nil
                }
                Button("Vazgeç", role: .cancel) { itemToDelete = nil }
            }
        }
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip(title: "Tümü (\(items.count))", selected: statusFilter == nil) { statusFilter = nil }
                ForEach(ItemStatus.allCases) { status in
                    let count = items.filter { $0.status == status }.count
                    chip(title: "\(status.title) (\(count))", icon: status.icon,
                         selected: statusFilter == status) {
                        statusFilter = statusFilter == status ? nil : status
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(Palette.background)
    }

    private func chip(title: String, icon: String? = nil, selected: Bool, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.light()
            withAnimation(.snappy) { action() }
        } label: {
            HStack(spacing: 5) {
                if let icon { Image(systemName: icon).font(.system(size: 11, weight: .semibold)) }
                Text(title).font(Typo.font(.semibold, 13, relativeTo: .caption))
            }
            .foregroundStyle(selected ? .white : Palette.textPrimary)
            .padding(.horizontal, 13).padding(.vertical, 8)
            .background(selected ? Palette.rose : Palette.card, in: Capsule())
            .shadow(color: Color.black.opacity(selected ? 0 : 0.04), radius: 6, y: 2)
        }
        .buttonStyle(.plain)
    }

    private var list: some View {
        List {
            ForEach(groups) { group in
                Section {
                    ForEach(group.items) { item in
                        NavigationLink(value: item) {
                            ItemRow(item: item, currency: currency, showCategory: sort != .category)
                        }
                        .listRowBackground(Palette.card)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) { itemToDelete = item } label: {
                                Label("Sil", systemImage: "trash")
                            }
                            if item.status != .gifted {
                                Button { withAnimation { item.mark(.gifted) } } label: {
                                    Label("Hediye", systemImage: "gift.fill")
                                }.tint(Palette.gold)
                            }
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            if item.status == .planned {
                                Button { withAnimation { item.mark(.purchased) }; Haptics.success() } label: {
                                    Label("Alındı", systemImage: "checkmark")
                                }.tint(Palette.success)
                            } else {
                                Button { withAnimation { item.mark(.planned) } } label: {
                                    Label("Alınacak", systemImage: "arrow.uturn.backward")
                                }.tint(Palette.textSecondary)
                            }
                        }
                    }
                } header: {
                    if !group.title.isEmpty {
                        HStack(spacing: 6) {
                            if let color = group.color {
                                Circle().fill(color.color).frame(width: 8, height: 8)
                            }
                            Text(group.title)
                                .font(Typo.caption)
                                .foregroundStyle(Palette.textSecondary)
                            Text("\(group.items.filter { $0.status.isCompleted }.count)/\(group.items.count)")
                                .font(Typo.caption2.monospacedDigit())
                                .foregroundStyle(Palette.textSecondary.opacity(0.7))
                        }
                        .textCase(nil)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Palette.background)
    }
}
