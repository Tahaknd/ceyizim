import SwiftUI
import SwiftData
import StoreKit

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.requestReview) private var requestReview
    @Query private var items: [CeyizItem]
    @Query private var categories: [CeyizCategory]

    @AppStorage(SettingsKeys.userName) private var userName = ""
    @AppStorage(SettingsKeys.weddingDate) private var weddingTimestamp: Double = 0
    @AppStorage(SettingsKeys.currency) private var currency = "TRY"
    @AppStorage(SettingsKeys.seededTemplate) private var seededTemplate = false

    @State private var showingTemplateConfirm = false
    @State private var showingDeleteConfirm = false
    @State private var templateResult: Int? = nil

    private var hasWeddingDate: Binding<Bool> {
        Binding(
            get: { weddingTimestamp > 0 },
            set: { on in
                weddingTimestamp = on
                    ? (Calendar.current.date(byAdding: .month, value: 6, to: Date()) ?? Date()).timeIntervalSince1970
                    : 0
            })
    }

    private var weddingDate: Binding<Date> {
        Binding(
            get: { WeddingCountdown.date(from: weddingTimestamp) ?? Date() },
            set: { weddingTimestamp = $0.timeIntervalSince1970 })
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 16) {
                        Image("SandikHero")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 64, height: 64)
                            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                            .shadow(color: Palette.rose.opacity(0.25), radius: 10, y: 5)
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Çeyizim").font(Typo.title).foregroundStyle(Palette.textPrimary)
                            Text("Mutlu yuvana giden yolda yanındayız.")
                                .font(Typo.captionRegular).foregroundStyle(Palette.textSecondary)
                            Text(AppConfig.versionText).font(Typo.caption2).foregroundStyle(Palette.textSecondary.opacity(0.8))
                        }
                    }
                    .padding(.vertical, 6)
                }
                .listRowBackground(Color.clear)

                Section("Profil") {
                    HStack {
                        Text("Adın")
                        TextField("İsteğe bağlı", text: $userName)
                            .multilineTextAlignment(.trailing)
                            .textInputAutocapitalization(.words)
                            .autocorrectionDisabled()
                    }
                    Toggle("Düğün tarihim belli", isOn: hasWeddingDate.animation())
                    if weddingTimestamp > 0 {
                        DatePicker("Düğün tarihi", selection: weddingDate, displayedComponents: .date)
                            .environment(\.locale, Money.locale)
                    }
                }

                Section {
                    Picker("Para birimi", selection: $currency) {
                        ForEach(CurrencyOption.all) { Text($0.title).tag($0.code) }
                    }
                } header: {
                    Text("Harcamalar")
                } footer: {
                    Text("Harcamalar, Alındı olarak işaretlediğin eşyaların fiyatlarından otomatik hesaplanır.")
                }

                Section {
                    Button { showingTemplateConfirm = true } label: {
                        Label("Hazır çeyiz listesini ekle", systemImage: "wand.and.stars")
                    }
                    ShareLink(item: CSVExport(items: items, currencyCode: currency),
                              preview: SharePreview("Çeyiz Listem", image: Image(systemName: "tablecells"))) {
                        Label("CSV olarak dışa aktar", systemImage: "square.and.arrow.up")
                    }
                    .disabled(items.isEmpty)
                    Button(role: .destructive) { showingDeleteConfirm = true } label: {
                        Label("Tüm verileri sil", systemImage: "trash")
                    }
                    .disabled(items.isEmpty && categories.isEmpty)
                } header: {
                    Text("Veriler")
                } footer: {
                    Text("Verilerin yalnızca bu cihazda saklanır; hiçbir sunucuya gönderilmez. \(items.count) eşya, \(categories.count) kategori.")
                }

                Section("Hakkında") {
                    Button { requestReview() } label: {
                        Label("Uygulamayı değerlendir", systemImage: "star.fill")
                    }
                    Link(destination: AppConfig.privacyPolicyURL) {
                        Label("Gizlilik politikası", systemImage: "hand.raised.fill")
                    }
                    Link(destination: AppConfig.supportURL) {
                        Label("Destek & iletişim", systemImage: "envelope.fill")
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Palette.background)
            .navigationTitle("Ayarlar")
            .confirmationDialog("Hazır liste eklensin mi?", isPresented: $showingTemplateConfirm, titleVisibility: .visible) {
                Button("Ekle") {
                    let added = SeedData.apply(to: context)
                    seededTemplate = true
                    templateResult = added
                    Haptics.success()
                }
                Button("Vazgeç", role: .cancel) {}
            } message: {
                Text("Mevcut kategorilerin ve eşyaların korunur; yalnızca listede olmayanlar eklenir.")
            }
            .confirmationDialog("Tüm veriler silinsin mi?", isPresented: $showingDeleteConfirm, titleVisibility: .visible) {
                Button("Hepsini Sil", role: .destructive) { deleteAll() }
                Button("Vazgeç", role: .cancel) {}
            } message: {
                Text("Tüm kategoriler, eşyalar ve fotoğraflar kalıcı olarak silinir. Bu işlem geri alınamaz.")
            }
            .alert("Liste eklendi", isPresented: Binding(get: { templateResult != nil }, set: { if !$0 { templateResult = nil } })) {
                Button("Tamam") { templateResult = nil }
            } message: {
                if let n = templateResult {
                    Text(n == 0 ? "Listendeki tüm öneriler zaten mevcuttu." : "\(n) yeni eşya eklendi.")
                }
            }
        }
    }

    private func deleteAll() {
        for item in items { context.delete(item) }
        for category in categories { context.delete(category) }
        try? context.save()
        seededTemplate = false
        Haptics.warning()
    }
}
