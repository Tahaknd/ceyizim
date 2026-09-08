import SwiftUI
import SwiftData

struct CategoryFormView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var allCategories: [CeyizCategory]

    let category: CeyizCategory?
    var onCreate: ((CeyizCategory) -> Void)? = nil

    @State private var name = ""
    @State private var icon = "shippingbox.fill"
    @State private var color: CategoryColor = .rose
    @State private var loaded = false
    @FocusState private var nameFocused: Bool

    private var canSave: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 12) {
                            CategoryIconView(icon: icon, color: color, size: 84)
                            Text(name.isEmpty ? "Kategori adı" : name)
                                .font(Typo.title)
                                .foregroundStyle(name.isEmpty ? Palette.textSecondary : Palette.textPrimary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
                .listRowBackground(Color.clear)

                Section("Ad") {
                    TextField("Örn. Mutfak", text: $name)
                        .focused($nameFocused)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                }

                Section("Renk") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(CategoryColor.allCases) { c in
                                Button {
                                    Haptics.light(); color = c
                                } label: {
                                    ZStack {
                                        Circle().fill(c.color).frame(width: 36, height: 36)
                                        if c == color {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundStyle(.white)
                                        }
                                    }
                                    .overlay(Circle().stroke(c == color ? c.color.opacity(0.4) : .clear, lineWidth: 4).padding(-4))
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(c.title)
                            }
                        }
                        .padding(.vertical, 6)
                    }
                }

                Section("Simge") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                        ForEach(SeedData.iconChoices, id: \.self) { symbol in
                            Button {
                                Haptics.light(); icon = symbol
                            } label: {
                                Image(systemName: symbol)
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(symbol == icon ? .white : color.color)
                                    .frame(width: 44, height: 44)
                                    .background(symbol == icon ? color.color : color.color.opacity(0.12),
                                                in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 6)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Palette.background)
            .navigationTitle(category == nil ? "Yeni Kategori" : "Kategoriyi Düzenle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Vazgeç") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") { save() }.disabled(!canSave).fontWeight(.semibold)
                }
            }
            .onAppear {
                guard !loaded else { return }
                loaded = true
                if let category {
                    name = category.name; icon = category.icon; color = category.color
                } else {
                    let used = Set(allCategories.map(\.color))
                    color = CategoryColor.allCases.first { !used.contains($0) } ?? .rose
                    nameFocused = true
                }
            }
        }
        .presentationDragIndicator(.visible)
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if let category {
            category.name = trimmed
            category.icon = icon
            category.color = color
        } else {
            let order = (allCategories.map(\.sortOrder).max() ?? -1) + 1
            let new = CeyizCategory(name: trimmed, icon: icon, color: color, sortOrder: order)
            context.insert(new)
            try? context.save()
            onCreate?(new)
        }
        Haptics.success()
        dismiss()
    }
}
