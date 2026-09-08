import SwiftUI
import SwiftData

struct CategoryDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage(SettingsKeys.currency) private var currency = "TRY"

    @Bindable var category: CeyizCategory
    @State private var showingAdd = false
    @State private var showingEdit = false
    @State private var showingDelete = false
    @State private var itemToDelete: CeyizItem? = nil
    @State private var isDeleted = false
    @State private var hideCompleted = false

    private var sortedItems: [CeyizItem] {
        category.items
            .filter { !hideCompleted || !$0.status.isCompleted }
            .sorted {
                if $0.status.isCompleted != $1.status.isCompleted { return !$0.status.isCompleted }
                if $0.isMustHave != $1.isMustHave { return $0.isMustHave }
                if $0.priority != $1.priority { return $0.priority.rawValue > $1.priority.rawValue }
                return $0.name.localizedStandardCompare($1.name) == .orderedAscending
            }
    }

    var body: some View {
        Group {
            if isDeleted {
                Color.clear
            } else {
                List {
                    Section { header.listRowInsets(EdgeInsets()).listRowBackground(Color.clear) }
                    if category.items.isEmpty {
                        Section {
                            EmptyStateView(icon: category.icon,
                                           title: "Bu kategori boş",
                                           message: "\(category.name) için ilk eşyanı ekle.",
                                           actionTitle: "Eşya Ekle") { showingAdd = true }
                        }
                        .listRowBackground(Color.clear)
                    } else {
                        Section {
                            ForEach(sortedItems) { item in
                                NavigationLink(value: item) {
                                    ItemRow(item: item, currency: currency)
                                }
                                .listRowBackground(Palette.card)
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) { itemToDelete = item } label: { Label("Sil", systemImage: "trash") }
                                    if item.status != .gifted {
                                        Button { withAnimation { item.mark(.gifted) } } label: { Label("Hediye", systemImage: "gift.fill") }
                                            .tint(Palette.gold)
                                    }
                                }
                                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                    if item.status == .planned {
                                        Button { withAnimation { item.mark(.purchased) }; Haptics.success() } label: { Label("Alındı", systemImage: "checkmark") }
                                            .tint(Palette.success)
                                    } else {
                                        Button { withAnimation { item.mark(.planned) } } label: { Label("Alınacak", systemImage: "arrow.uturn.backward") }
                                            .tint(Palette.textSecondary)
                                    }
                                }
                            }
                        } header: {
                            HStack {
                                Text("Eşyalar").font(Typo.caption).foregroundStyle(Palette.textSecondary)
                                Spacer()
                                Toggle("Tamamlananları gizle", isOn: $hideCompleted.animation())
                                    .font(Typo.captionRegular)
                                    .toggleStyle(.button)
                                    .buttonStyle(.bordered)
                                    .controlSize(.mini)
                            }
                            .textCase(nil)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
        }
        .background(Palette.background)
        .navigationTitle(category.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack {
                    Button { showingAdd = true } label: { Image(systemName: "plus.circle.fill").font(.title3) }
                    Menu {
                        Button { showingEdit = true } label: { Label("Kategoriyi düzenle", systemImage: "pencil") }
                        Divider()
                        Button(role: .destructive) { showingDelete = true } label: { Label("Kategoriyi sil", systemImage: "trash") }
                    } label: { Image(systemName: "ellipsis.circle") }
                }
            }
        }
        .sheet(isPresented: $showingAdd) { ItemFormView(mode: .create(category: category)) }
        .sheet(isPresented: $showingEdit) { CategoryFormView(category: category) }
        .confirmationDialog(
            category.items.isEmpty
                ? "“\(category.name)” silinsin mi?"
                : "“\(category.name)” ve içindeki \(category.items.count) eşya silinsin mi?",
            isPresented: $showingDelete, titleVisibility: .visible) {
            Button("Sil", role: .destructive) { deleteCategory() }
            Button("Vazgeç", role: .cancel) {}
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

    private var header: some View {
        HStack(spacing: 18) {
            ZStack {
                ProgressRing(progress: category.progress, lineWidth: 9,
                             color: category.color.color, track: category.color.color.opacity(0.15))
                Image(systemName: category.icon)
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(category.color.color)
            }
            .frame(width: 84, height: 84)
            VStack(alignment: .leading, spacing: 6) {
                Text("\(category.completedCount) / \(category.totalCount) tamamlandı")
                    .font(Typo.heading).foregroundStyle(Palette.textPrimary)
                if category.spent > 0 {
                    Text("Harcanan: \(Money.format(category.spent, code: currency))")
                        .font(Typo.subheadline).foregroundStyle(Palette.textSecondary)
                }
                if category.planned > 0 {
                    Text("Planlanan: \(Money.format(category.planned, code: currency))")
                        .font(Typo.subheadline).foregroundStyle(Palette.textSecondary)
                }
                if category.spent == 0 && category.planned == 0 {
                    Text("Fiyat girildiğinde harcama özeti burada görünür.")
                        .font(Typo.captionRegular).foregroundStyle(Palette.textSecondary)
                }
            }
            Spacer()
        }
        .ceyizCard()
        .padding(.horizontal, 4)
        .padding(.vertical, 6)
    }

    private func deleteCategory() {
        isDeleted = true
        dismiss()
        let target = category
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            context.delete(target)
        }
    }
}
