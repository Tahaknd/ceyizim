import SwiftUI

/// Accent colour picker: a free wheel, a row of starting points, and a live
/// preview of the parts of the app the accent actually touches.
struct ThemePickerView: View {

    private var theme: AccentTheme { ThemeStore.shared.accent }

    /// The wheel is bound to the *resolved* accent, not the raw pick, so the
    /// swatch always shows the colour the app will really use.
    private var picked: Binding<Color> {
        Binding(get: { ThemeStore.shared.accent.accentLight },
                set: { apply(AccentTheme(picked: $0), haptic: false) })
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                preview
                wheel
                presets
                resetButton
                footnote
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 20)
        }
        .background(Palette.background.ignoresSafeArea())
        .navigationTitle("Tema rengi")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Live preview

    private var preview: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 16) {
                ProgressRing(progress: 0.62)
                    .frame(width: 76, height: 76)
                    .overlay {
                        Text("62%").font(Typo.caption).foregroundStyle(Palette.textPrimary)
                    }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Genel İlerleme")
                        .font(Typo.subheadline).foregroundStyle(Palette.textSecondary)
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("69").font(Typo.number).foregroundStyle(Palette.rose)
                        Text("/ 111 eşya").font(Typo.subheadline).foregroundStyle(Palette.textSecondary)
                    }
                }
                Spacer()
            }

            HStack(spacing: 10) {
                Text("Tümü (111)")
                    .font(Typo.subheadlineSemibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16).padding(.vertical, 9)
                    .background(Palette.rose, in: Capsule())
                Text("Alınacak (42)")
                    .font(Typo.subheadlineSemibold)
                    .foregroundStyle(Palette.textSecondary)
                    .padding(.horizontal, 16).padding(.vertical, 9)
                    .background(Palette.roseSoft, in: Capsule())
                Spacer()
            }

            ProgressBar(progress: 0.62)

            Button("Hadi Başlayalım") {}
                .buttonStyle(PrimaryButtonStyle())
                .allowsHitTesting(false)
        }
        .ceyizCard(padding: 18)
    }

    // MARK: - Controls

    private var wheel: some View {
        VStack(alignment: .leading, spacing: 8) {
            ColorPicker(selection: picked, supportsOpacity: false) {
                Label("Kendi rengini seç", systemImage: "eyedropper.halffull")
                    .font(Typo.bodyMedium).foregroundStyle(Palette.textPrimary)
            }
            .padding(.horizontal, 16).padding(.vertical, 12)
            .background(Palette.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }

    private var presets: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Hazır tonlar")
                .font(Typo.caption).foregroundStyle(Palette.textSecondary)
                .textCase(.uppercase)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 5),
                      spacing: 14) {
                ForEach(AccentTheme.presets, id: \.name) { preset in
                    Button { apply(preset.theme) } label: {
                        VStack(spacing: 6) {
                            Circle()
                                .fill(preset.theme.accentLight)
                                .frame(height: 46)
                                .overlay {
                                    if preset.theme == theme {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 17, weight: .bold))
                                            .foregroundStyle(.white)
                                    }
                                }
                                .overlay {
                                    Circle().strokeBorder(Palette.textPrimary.opacity(0.08), lineWidth: 1)
                                }
                            Text(preset.name)
                                .font(Typo.caption2).foregroundStyle(Palette.textSecondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var resetButton: some View {
        Button {
            apply(.brand)
        } label: {
            Label("Varsayılan güle dön", systemImage: "arrow.uturn.backward")
                .font(Typo.subheadlineSemibold)
                .foregroundStyle(Palette.rose)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Palette.roseSoft, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .disabled(theme == .brand)
        .opacity(theme == .brand ? 0.45 : 1)
    }

    private var footnote: some View {
        Text("Rengi sen seçiyorsun; uygulama yalnızca tonunu dengeliyor ki butonlardaki yazı her renkte okunur kalsın. Seçtiğin renk yukarıdaki önizlemede göründüğü gibi uygulanır.")
            .font(Typo.captionRegular)
            .foregroundStyle(Palette.textSecondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 8)
    }

    /// The wheel fires continuously while dragging, so it skips the haptic;
    /// taps on a preset or on reset get one.
    private func apply(_ new: AccentTheme, haptic: Bool = true) {
        guard new != theme else { return }
        withAnimation(.easeInOut(duration: 0.25)) {
            ThemeStore.shared.apply(new)
        }
        if haptic { Haptics.light() }
    }
}
