import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var context
    @AppStorage(SettingsKeys.hasOnboarded) private var hasOnboarded = false
    @AppStorage(SettingsKeys.userName) private var userName = ""
    @AppStorage(SettingsKeys.weddingDate) private var weddingTimestamp: Double = 0
    @AppStorage(SettingsKeys.seededTemplate) private var seededTemplate = false

    @State private var page = 0
    @State private var name = ""
    @State private var hasWeddingDate = false
    @State private var weddingDate = Calendar.current.date(byAdding: .month, value: 6, to: Date()) ?? Date()
    @State private var useTemplate = true
    @FocusState private var focused: Bool

    private let pageCount = 3

    var body: some View {
        ZStack {
            LinearGradient(colors: [Palette.roseSoft, Palette.background],
                           startPoint: .top, endPoint: .center)
                .ignoresSafeArea()
            Palette.background.opacity(0.001) // keep gradient under scroll

            VStack(spacing: 0) {
                TabView(selection: $page) {
                    welcomePage.tag(0)
                    profilePage.tag(1)
                    templatePage.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: page)

                VStack(spacing: 16) {
                    HStack(spacing: 8) {
                        ForEach(0..<pageCount, id: \.self) { i in
                            Capsule()
                                .fill(i == page ? Palette.rose : Palette.rose.opacity(0.25))
                                .frame(width: i == page ? 24 : 8, height: 8)
                                .animation(.spring(duration: 0.3), value: page)
                        }
                    }
                    Button {
                        focused = false
                        if page < pageCount - 1 {
                            withAnimation { page += 1 }
                        } else {
                            finish()
                        }
                    } label: {
                        Text(page == pageCount - 1 ? "Hadi Başlayalım" : "Devam")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }
        }
        .scrollDismissesKeyboard(.interactively)
    }

    // MARK: Pages

    private var welcomePage: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer(minLength: 40)
                Image("SandikHero")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 180, height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 40, style: .continuous))
                    .shadow(color: Palette.rose.opacity(0.35), radius: 28, y: 14)
                VStack(spacing: 12) {
                    Text("Çeyizim'e hoş geldin")
                        .font(Typo.display)
                        .foregroundStyle(Palette.textPrimary)
                        .multilineTextAlignment(.center)
                    Text("Çeyizini kategori kategori planla, aldıklarını işaretle, hediyeleri not et ve harcamalarını takip et. Her şey telefonunda, sadece sana ait.")
                        .font(Typo.body)
                        .foregroundStyle(Palette.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)
                }
                VStack(alignment: .leading, spacing: 14) {
                    featureRow(icon: "checklist", title: "Hazır çeyiz listesi", text: "10 kategori, 100'den fazla öneri ile hemen başla.")
                    featureRow(icon: "turkishlirasign.circle.fill", title: "Harcama takibi", text: "Ne kadar harcadığını ve ne kadar kaldığını otomatik gör.")
                    featureRow(icon: "gift.fill", title: "Hediyeler", text: "Kimden ne geldi, hiçbirini unutma.")
                }
                .padding(20)
                .ceyizCard()
                .padding(.horizontal, 24)
                Spacer(minLength: 20)
            }
        }
    }

    private func featureRow(icon: String, title: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Palette.rose)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(Typo.heading).foregroundStyle(Palette.textPrimary)
                Text(text).font(Typo.subheadline).foregroundStyle(Palette.textSecondary)
            }
        }
    }

    private var profilePage: some View {
        ScrollView {
            VStack(spacing: 22) {
                Spacer(minLength: 30)
                VStack(spacing: 10) {
                    Text("Seni tanıyalım")
                        .font(Typo.display)
                        .foregroundStyle(Palette.textPrimary)
                    Text("Bu bilgiler yalnızca sana özel bir deneyim için. İstediğin zaman Ayarlar'dan değiştirebilirsin.")
                        .font(Typo.subheadline)
                        .foregroundStyle(Palette.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)
                }

                VStack(spacing: 18) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Adın").font(Typo.caption).foregroundStyle(Palette.textSecondary)
                        TextField("Örn. Elif", text: $name)
                            .textInputAutocapitalization(.words)
                            .autocorrectionDisabled()
                            .focused($focused)
                            .padding(14)
                            .background(Palette.cardSecondary, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    Divider()
                    Toggle(isOn: $hasWeddingDate.animation()) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Düğün tarihim belli").font(Typo.bodyMedium).foregroundStyle(Palette.textPrimary)
                            Text("Özet ekranında geri sayım gösterilir").font(Typo.captionRegular).foregroundStyle(Palette.textSecondary)
                        }
                    }
                    if hasWeddingDate {
                        DatePicker("Düğün tarihi", selection: $weddingDate, in: Date()..., displayedComponents: .date)
                            .datePickerStyle(.compact)
                            .environment(\.locale, Money.locale)
                    }
                }
                .padding(20)
                .ceyizCard()
                .padding(.horizontal, 24)
                Spacer(minLength: 20)
            }
        }
    }

    private var templatePage: some View {
        ScrollView {
            VStack(spacing: 22) {
                Spacer(minLength: 30)
                VStack(spacing: 10) {
                    Text("Nasıl başlamak istersin?")
                        .font(Typo.display)
                        .foregroundStyle(Palette.textPrimary)
                        .multilineTextAlignment(.center)
                    Text("Hazır listeyi dilediğin gibi düzenleyebilir, silebilir veya kendi eşyalarını ekleyebilirsin.")
                        .font(Typo.subheadline)
                        .foregroundStyle(Palette.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)
                }

                VStack(spacing: 12) {
                    templateOption(selected: useTemplate, icon: "wand.and.stars",
                                   title: "Hazır çeyiz listesiyle başla",
                                   subtitle: "Mutfak, yatak odası, banyo, beyaz eşya ve daha fazlası. Önerilen.") {
                        useTemplate = true
                    }
                    templateOption(selected: !useTemplate, icon: "square.and.pencil",
                                   title: "Boş başla",
                                   subtitle: "Kategorilerini ve eşyalarını sıfırdan kendin oluştur.") {
                        useTemplate = false
                    }
                }
                .padding(.horizontal, 24)

                if useTemplate {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Listede neler var?").font(Typo.heading).foregroundStyle(Palette.textPrimary)
                        FlowLayout(spacing: 8) {
                            ForEach(SeedData.categories, id: \.name) { cat in
                                HStack(spacing: 6) {
                                    Image(systemName: cat.icon).font(.system(size: 11, weight: .semibold))
                                    Text(cat.name).font(Typo.font(.medium, 12, relativeTo: .caption))
                                }
                                .foregroundStyle(cat.color.color)
                                .padding(.horizontal, 10).padding(.vertical, 6)
                                .background(cat.color.color.opacity(0.12), in: Capsule())
                            }
                        }
                    }
                    .padding(18)
                    .ceyizCard()
                    .padding(.horizontal, 24)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
                Spacer(minLength: 20)
            }
            .animation(.easeInOut, value: useTemplate)
        }
    }

    private func templateOption(selected: Bool, icon: String, title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button(action: { Haptics.light(); action() }) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(selected ? Palette.rose : Palette.roseSoft)
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(selected ? .white : Palette.rose)
                }
                .frame(width: 48, height: 48)
                VStack(alignment: .leading, spacing: 3) {
                    Text(title).font(Typo.heading).foregroundStyle(Palette.textPrimary)
                    Text(subtitle).font(Typo.captionRegular).foregroundStyle(Palette.textSecondary)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(selected ? Palette.rose : Palette.textSecondary.opacity(0.4))
            }
            .padding(16)
            .background(Palette.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(selected ? Palette.rose : Color.clear, lineWidth: 2)
            )
            .shadow(color: Color.black.opacity(0.04), radius: 10, y: 4)
        }
        .buttonStyle(.plain)
    }

    // MARK: Finish

    private func finish() {
        userName = name.trimmingCharacters(in: .whitespaces)
        weddingTimestamp = hasWeddingDate ? weddingDate.timeIntervalSince1970 : 0
        if useTemplate {
            SeedData.apply(to: context)
            seededTemplate = true
        }
        Haptics.success()
        hasOnboarded = true
    }
}

/// Minimal wrapping layout for chips.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > width, x > 0 {
                x = 0; y += rowHeight + spacing; rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: width, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowHeight: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX; y += rowHeight + spacing; rowHeight = 0
            }
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
