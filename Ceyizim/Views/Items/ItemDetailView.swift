import SwiftUI
import SwiftData

struct ItemDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage(SettingsKeys.currency) private var currency = "TRY"

    @Bindable var item: CeyizItem
    @State private var showingEdit = false
    @State private var showingDelete = false
    @State private var isDeleted = false

    var body: some View {
        Group {
            if isDeleted {
                Color.clear
            } else {
                content
            }
        }
        .background(Palette.background)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { showingEdit = true } label: { Label("Düzenle", systemImage: "pencil") }
                    Divider()
                    Button(role: .destructive) { showingDelete = true } label: { Label("Sil", systemImage: "trash") }
                } label: { Image(systemName: "ellipsis.circle") }
            }
        }
        .sheet(isPresented: $showingEdit) { ItemFormView(mode: .edit(item)) }
        .confirmationDialog("“\(item.name)” silinsin mi?", isPresented: $showingDelete, titleVisibility: .visible) {
            Button("Sil", role: .destructive) { deleteItem() }
            Button("Vazgeç", role: .cancel) {}
        }
    }

    private var content: some View {
        ScrollView {
            VStack(spacing: 18) {
                hero
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top) {
                        Text(item.name)
                            .font(Typo.display)
                            .foregroundStyle(Palette.textPrimary)
                        Spacer()
                        StatusBadge(status: item.status)
                    }
                    HStack(spacing: 8) {
                        if let cat = item.category {
                            Label(cat.name, systemImage: cat.icon)
                                .font(Typo.caption)
                                .foregroundStyle(cat.color.color)
                        }
                        if item.isMustHave {
                            Label("Olmazsa olmaz", systemImage: "star.fill")
                                .font(Typo.caption)
                                .foregroundStyle(Palette.gold)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                actions

                infoGrid

                if !item.notes.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notlar").font(Typo.heading).foregroundStyle(Palette.textPrimary)
                        Text(item.notes).font(Typo.body).foregroundStyle(Palette.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .ceyizCard()
                }
            }
            .padding(20)
        }
    }

    @ViewBuilder
    private var hero: some View {
        if let data = item.photoData, let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: 260)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .shadow(color: Color.black.opacity(0.08), radius: 16, y: 8)
        } else {
            let color = item.category?.color.color ?? Palette.rose
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(LinearGradient(colors: [color.opacity(0.35), color.opacity(0.12)],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                Image(systemName: item.category?.icon ?? "shippingbox.fill")
                    .font(.system(size: 64, weight: .medium))
                    .foregroundStyle(color)
            }
            .frame(height: 170)
        }
    }

    private var actions: some View {
        HStack(spacing: 10) {
            if item.status != .purchased {
                actionButton(title: "Alındı", icon: "checkmark.circle.fill", color: Palette.success) {
                    item.mark(.purchased); Haptics.success()
                }
            }
            if item.status != .gifted {
                actionButton(title: "Hediye geldi", icon: "gift.fill", color: Palette.gold) {
                    item.mark(.gifted); Haptics.success()
                }
            }
            if item.status != .planned {
                actionButton(title: "Alınacak'a al", icon: "arrow.uturn.backward.circle.fill", color: Palette.textSecondary) {
                    item.mark(.planned); Haptics.light()
                }
            }
        }
    }

    private func actionButton(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button { withAnimation(.snappy) { action() } } label: {
            VStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 22))
                Text(title).font(Typo.font(.semibold, 12, relativeTo: .caption))
            }
            .foregroundStyle(color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var infoGrid: some View {
        VStack(spacing: 0) {
            infoRow("Adet", "\(item.quantity)")
            infoRow("Öncelik", item.priority.title, icon: item.priority.icon)
            if let est = item.estimatedPrice { infoRow("Tahmini fiyat", Money.format(est, code: currency)) }
            if item.status == .purchased {
                infoRow("Ödenen", item.actualPrice.map { Money.format($0, code: currency) } ?? "Girilmedi")
            }
            if !item.store.isEmpty { infoRow("Mağaza", item.store) }
            if item.status == .gifted { infoRow("Hediye eden", item.giftedBy.isEmpty ? "Belirtilmedi" : item.giftedBy) }
            if let date = item.purchaseDate, item.status != .planned {
                infoRow(item.status == .gifted ? "Geliş tarihi" : "Alım tarihi",
                        date.formatted(.dateTime.day().month(.wide).year().locale(Money.locale)))
            }
            infoRow("Eklenme", item.createdAt.formatted(.dateTime.day().month(.wide).year().locale(Money.locale)), last: true)
        }
        .ceyizCard(padding: 4)
    }

    private func infoRow(_ title: String, _ value: String, icon: String? = nil, last: Bool = false) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(title).font(Typo.subheadline).foregroundStyle(Palette.textSecondary)
                Spacer()
                HStack(spacing: 5) {
                    if let icon { Image(systemName: icon).font(Typo.captionRegular) }
                    Text(value).font(Typo.subheadlineSemibold)
                }
                .foregroundStyle(Palette.textPrimary)
            }
            .padding(.horizontal, 14).padding(.vertical, 12)
            if !last { Divider().padding(.leading, 14) }
        }
    }

    private func deleteItem() {
        isDeleted = true
        dismiss()
        let target = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            context.delete(target)
        }
    }
}
