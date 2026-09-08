import SwiftUI
import SwiftData
import PhotosUI

struct ItemFormView: View {
    enum Mode {
        case create(category: CeyizCategory?)
        case edit(CeyizItem)
    }

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \CeyizCategory.sortOrder) private var categories: [CeyizCategory]
    @AppStorage(SettingsKeys.currency) private var currency = "TRY"

    let mode: Mode

    @State private var name = ""
    @State private var categoryID: PersistentIdentifier? = nil
    @State private var quantity = 1
    @State private var status: ItemStatus = .planned
    @State private var priority: ItemPriority = .normal
    @State private var isMustHave = false
    @State private var estimatedPrice: Double? = nil
    @State private var actualPrice: Double? = nil
    @State private var store = ""
    @State private var giftedBy = ""
    @State private var purchaseDate = Date()
    @State private var notes = ""
    @State private var photoData: Data? = nil
    @State private var photoSelection: PhotosPickerItem? = nil
    @State private var loaded = false
    @State private var showingNewCategory = false
    @FocusState private var nameFocused: Bool

    private var isEditing: Bool { if case .edit = mode { return true } else { return false } }
    private var canSave: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                photoSection
                Section("Eşya") {
                    TextField("Eşya adı", text: $name)
                        .focused($nameFocused)
                        .textInputAutocapitalization(.sentences)
                    Picker("Kategori", selection: $categoryID) {
                        Text("Seçilmedi").tag(PersistentIdentifier?.none)
                        ForEach(categories) { cat in
                            Label(cat.name, systemImage: cat.icon).tag(Optional(cat.persistentModelID))
                        }
                    }
                    Button { showingNewCategory = true } label: {
                        Label("Yeni kategori oluştur", systemImage: "plus")
                    }
                    Stepper("Adet: \(quantity)", value: $quantity, in: 1...999)
                }

                Section("Durum") {
                    Picker("Durum", selection: $status.animation()) {
                        ForEach(ItemStatus.allCases) { s in
                            Label(s.title, systemImage: s.icon).tag(s)
                        }
                    }
                    .pickerStyle(.segmented)
                    if status != .planned {
                        DatePicker(status == .gifted ? "Geliş tarihi" : "Alım tarihi",
                                   selection: $purchaseDate, displayedComponents: .date)
                            .environment(\.locale, Money.locale)
                    }
                    if status == .gifted {
                        TextField("Hediye eden (örn. Teyzem)", text: $giftedBy)
                            .textInputAutocapitalization(.words)
                            .autocorrectionDisabled()
                    }
                }

                Section {
                    HStack {
                        Text("Tahmini fiyat")
                        Spacer()
                        TextField("0", value: $estimatedPrice, format: .number.locale(Money.locale))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text(Money.symbol(currency)).foregroundStyle(.secondary)
                    }
                    if status == .purchased {
                        HStack {
                            Text("Ödenen")
                            Spacer()
                            TextField("0", value: $actualPrice, format: .number.locale(Money.locale))
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                            Text(Money.symbol(currency)).foregroundStyle(.secondary)
                        }
                    }
                    TextField("Mağaza / marka", text: $store)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                } header: {
                    Text("Fiyat & Alışveriş")
                } footer: {
                    if status == .purchased {
                        Text("Ödenen boş bırakılırsa harcama hesabında tahmini fiyat kullanılır.")
                    } else if status == .gifted {
                        Text("Hediyeler harcamaya dahil edilmez; tahmini fiyat “hediyelerle tasarruf” olarak gösterilir.")
                    }
                }

                Section("Öncelik") {
                    Picker("Öncelik", selection: $priority) {
                        ForEach(ItemPriority.allCases) { Text($0.title).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    Toggle(isOn: $isMustHave) {
                        Label("Olmazsa olmaz", systemImage: "star.fill")
                    }
                    .tint(Palette.gold)
                }

                Section("Notlar") {
                    TextField("Renk, ölçü, beğendiğin model…", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }

            }
            .scrollContentBackground(.hidden)
            .background(Palette.background)
            .navigationTitle(isEditing ? "Eşyayı Düzenle" : "Yeni Eşya")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Vazgeç") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") { save() }.disabled(!canSave).fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showingNewCategory) {
                CategoryFormView(category: nil) { newCategory in
                    categoryID = newCategory.persistentModelID
                }
            }
            .onAppear(perform: load)
            .onChange(of: photoSelection) { _, newValue in
                guard let newValue else { return }
                Task {
                    if let data = try? await newValue.loadTransferable(type: Data.self),
                       let processed = ImageProcessing.downscaledJPEG(from: data) {
                        photoData = processed
                    }
                    photoSelection = nil
                }
            }
        }
        .presentationDragIndicator(.visible)
    }

    private var photoSection: some View {
        Section {
            HStack(spacing: 14) {
                Group {
                    if let photoData, let image = UIImage(data: photoData) {
                        Image(uiImage: image).resizable().scaledToFill()
                    } else {
                        ZStack {
                            Palette.roseSoft
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 26))
                                .foregroundStyle(Palette.rose)
                        }
                    }
                }
                .frame(width: 84, height: 84)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                VStack(alignment: .leading, spacing: 8) {
                    PhotosPicker(selection: $photoSelection, matching: .images) {
                        Label(photoData == nil ? "Fotoğraf ekle" : "Fotoğrafı değiştir", systemImage: "photo")
                            .font(Typo.subheadlineSemibold)
                    }
                    if photoData != nil {
                        Button(role: .destructive) { photoData = nil } label: {
                            Label("Fotoğrafı kaldır", systemImage: "trash").font(Typo.subheadline)
                        }
                    }
                }
                Spacer()
            }
            .padding(.vertical, 4)
        }
    }

    private func load() {
        guard !loaded else { return }
        loaded = true
        switch mode {
        case .create(let category):
            categoryID = category?.persistentModelID
            nameFocused = true
        case .edit(let item):
            name = item.name
            categoryID = item.category?.persistentModelID
            quantity = item.quantity
            status = item.status
            priority = item.priority
            isMustHave = item.isMustHave
            estimatedPrice = item.estimatedPrice
            actualPrice = item.actualPrice
            store = item.store
            giftedBy = item.giftedBy
            purchaseDate = item.purchaseDate ?? Date()
            notes = item.notes
            photoData = item.photoData
        }
    }

    private func save() {
        let category = categories.first { $0.persistentModelID == categoryID }
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let item: CeyizItem
        switch mode {
        case .create:
            item = CeyizItem(name: trimmedName)
            context.insert(item)
        case .edit(let existing):
            item = existing
            item.name = trimmedName
        }
        item.category = category
        item.quantity = quantity
        item.status = status
        item.priority = priority
        item.isMustHave = isMustHave
        item.estimatedPrice = estimatedPrice.flatMap { $0 > 0 ? $0 : nil }
        item.actualPrice = status == .purchased ? actualPrice.flatMap { $0 > 0 ? $0 : nil } : nil
        item.store = store.trimmingCharacters(in: .whitespaces)
        item.giftedBy = status == .gifted ? giftedBy.trimmingCharacters(in: .whitespaces) : ""
        item.purchaseDate = status == .planned ? nil : purchaseDate
        item.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        item.photoData = photoData
        Haptics.success()
        dismiss()
    }
}

enum ImageProcessing {
    static func downscaledJPEG(from data: Data, maxDimension: CGFloat = 1400, quality: CGFloat = 0.8) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        let size = image.size
        let scale = min(1, maxDimension / max(size.width, size.height))
        let target = CGSize(width: size.width * scale, height: size.height * scale)
        guard let thumb = image.preparingThumbnail(of: target) else {
            return image.jpegData(compressionQuality: quality)
        }
        return thumb.jpegData(compressionQuality: quality)
    }
}
