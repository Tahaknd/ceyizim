import SwiftUI
import SwiftData

// MARK: - Progress ring

struct ProgressRing: View {
    var progress: Double
    var lineWidth: CGFloat = 12
    var color: Color = Palette.rose
    var track: Color = Palette.roseSoft

    var body: some View {
        ZStack {
            Circle().stroke(track, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: min(1, max(0, progress)))
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.spring(duration: 0.6), value: progress)
        }
    }
}

// MARK: - Thin progress bar

struct ProgressBar: View {
    var progress: Double
    var color: Color = Palette.rose
    var height: CGFloat = 8
    var track: Color = Palette.roseSoft

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(track)
                Capsule().fill(color)
                    .frame(width: progress <= 0 ? 0 : max(height, geo.size.width * CGFloat(min(1, progress))))
                    .animation(.spring(duration: 0.5), value: progress)
            }
        }
        .frame(height: height)
    }
}

// MARK: - Category icon

struct CategoryIconView: View {
    var icon: String
    var color: CategoryColor
    var size: CGFloat = 44

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.32, style: .continuous)
                .fill(color.color.opacity(0.16))
            Image(systemName: icon)
                .font(.system(size: size * 0.42, weight: .semibold))
                .foregroundStyle(color.color)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Stat pill

struct StatPill: View {
    var title: String
    var value: String
    var color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(Typo.numberSm)
                .foregroundStyle(color)
            Text(title)
                .font(Typo.caption2)
                .foregroundStyle(Palette.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(color.opacity(0.10), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

// MARK: - Section header

struct SectionHeader: View {
    var title: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(Typo.title)
                .foregroundStyle(Palette.textPrimary)
            Spacer()
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(Typo.caption)
                    .foregroundStyle(Palette.rose)
            }
        }
    }
}

// MARK: - Empty state

struct EmptyStateView: View {
    var icon: String
    var title: String
    var message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle().fill(Palette.roseSoft).frame(width: 92, height: 92)
                Image(systemName: icon)
                    .font(.system(size: 38, weight: .medium))
                    .foregroundStyle(Palette.rose)
            }
            Text(title)
                .font(Typo.title)
                .foregroundStyle(Palette.textPrimary)
                .multilineTextAlignment(.center)
            Text(message)
                .font(Typo.subheadline)
                .foregroundStyle(Palette.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)
            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(Typo.heading)
                        .padding(.horizontal, 22).padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .padding(.horizontal)
    }
}

// MARK: - Status badge

struct StatusBadge: View {
    var status: ItemStatus
    var body: some View {
        Label(status.title, systemImage: status.icon)
            .font(Typo.font(.semibold, 12, relativeTo: .caption))
            .foregroundStyle(status.color)
            .padding(.horizontal, 10).padding(.vertical, 5)
            .background(status.color.opacity(0.12), in: Capsule())
    }
}

// MARK: - Primary button style

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Typo.heading)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(colors: [Palette.rose, Palette.roseDeep],
                               startPoint: .topLeading, endPoint: .bottomTrailing),
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
            .opacity(configuration.isPressed ? 0.85 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Item row (shared between lists)

struct ItemRow: View {
    @Bindable var item: CeyizItem
    var currency: String
    var showCategory = false
    var onToggle: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 12) {
            Button {
                Haptics.light()
                withAnimation(.snappy) {
                    item.mark(item.status == .planned ? .purchased : .planned)
                }
                onToggle?()
            } label: {
                Image(systemName: item.status.icon)
                    .font(.system(size: 24, weight: .regular))
                    .foregroundStyle(item.status == .planned ? Palette.textSecondary.opacity(0.5) : item.status.color)
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(item.name)
                        .font(Typo.bodyMedium)
                        .foregroundStyle(item.status.isCompleted ? Palette.textSecondary : Palette.textPrimary)
                        .strikethrough(item.status == .purchased, color: Palette.textSecondary.opacity(0.6))
                        .lineLimit(1)
                    if item.quantity > 1 {
                        Text("×\(item.quantity)")
                            .font(Typo.caption)
                            .foregroundStyle(Palette.textSecondary)
                    }
                    if item.isMustHave {
                        Image(systemName: "star.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(Palette.gold)
                    }
                    if item.priority == .high && item.status == .planned {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(Palette.danger)
                    }
                }
                HStack(spacing: 6) {
                    if showCategory, let cat = item.category {
                        Text(cat.name)
                            .font(Typo.captionRegular)
                            .foregroundStyle(cat.color.color)
                    }
                    if !item.store.isEmpty {
                        Text(item.store).font(Typo.captionRegular).foregroundStyle(Palette.textSecondary).lineLimit(1)
                    }
                    if item.status == .gifted, !item.giftedBy.isEmpty {
                        Text("🎁 \(item.giftedBy)").font(Typo.captionRegular).foregroundStyle(Palette.textSecondary).lineLimit(1)
                    }
                }
            }
            Spacer(minLength: 4)
            if let price = item.displayPrice, price > 0 {
                Text(Money.format(price, code: currency))
                    .font(Typo.font(.semibold, 14, relativeTo: .subheadline))
                    .foregroundStyle(item.status == .planned ? Palette.textSecondary : Palette.textPrimary)
            }
            if item.photoData != nil {
                Image(systemName: "photo.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(Palette.textSecondary.opacity(0.6))
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}
