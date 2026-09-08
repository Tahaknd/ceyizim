import SwiftUI
import UIKit

// MARK: - Palette

enum Palette {
    static func dynamic(_ light: UInt32, _ dark: UInt32) -> Color {
        Color(uiColor: UIColor { tc in
            tc.userInterfaceStyle == .dark ? UIColor(hex: dark) : UIColor(hex: light)
        })
    }

    static let background     = dynamic(0xFDF7F4, 0x171014)
    static let card           = dynamic(0xFFFFFF, 0x241922)
    static let cardSecondary  = dynamic(0xFBEFF2, 0x30222A)
    static let rose           = dynamic(0xD4667F, 0xE58AA0)
    static let roseDeep       = dynamic(0xB84D67, 0xD1728A)
    static let roseSoft       = dynamic(0xFBE4EA, 0x46293A)
    static let textPrimary    = dynamic(0x33222B, 0xF7EEF1)
    static let textSecondary  = dynamic(0x8C7580, 0xB79FA9)
    static let separator      = dynamic(0xF0E2E6, 0x3A2B32)
    static let success        = dynamic(0x63A97D, 0x8CC9A1)
    static let warning        = dynamic(0xE0A24B, 0xF0B865)
    static let danger         = dynamic(0xD95F5F, 0xE87C7C)
    static let gold           = dynamic(0xD9A960, 0xE8C27E)
}

extension UIColor {
    convenience init(hex: UInt32) {
        let r = CGFloat((hex >> 16) & 0xFF) / 255
        let g = CGFloat((hex >> 8) & 0xFF) / 255
        let b = CGFloat(hex & 0xFF) / 255
        self.init(red: r, green: g, blue: b, alpha: 1)
    }
}

// MARK: - Category colours

enum CategoryColor: String, CaseIterable, Identifiable {
    case rose, gold, sage, lilac, sky, peach, plum, mint, coral, lavender

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .rose:     return Palette.dynamic(0xD4667F, 0xE58AA0)
        case .gold:     return Palette.dynamic(0xD1A054, 0xE6BC79)
        case .sage:     return Palette.dynamic(0x7FAE8F, 0x9BC7AA)
        case .lilac:    return Palette.dynamic(0xA98BCF, 0xC0A7E0)
        case .sky:      return Palette.dynamic(0x7FA9D3, 0x9DBFE2)
        case .peach:    return Palette.dynamic(0xE9946F, 0xF2AD8D)
        case .plum:     return Palette.dynamic(0x9B5B7E, 0xB77A9B)
        case .mint:     return Palette.dynamic(0x66B7A9, 0x86CFC2)
        case .coral:    return Palette.dynamic(0xE27070, 0xEE9090)
        case .lavender: return Palette.dynamic(0x8E8ED1, 0xA9A9E3)
        }
    }

    var title: String {
        switch self {
        case .rose: return "Gül"
        case .gold: return "Altın"
        case .sage: return "Adaçayı"
        case .lilac: return "Leylak"
        case .sky: return "Gök"
        case .peach: return "Şeftali"
        case .plum: return "Erik"
        case .mint: return "Nane"
        case .coral: return "Mercan"
        case .lavender: return "Lavanta"
        }
    }
}

// MARK: - Typography (Nunito, scales with Dynamic Type)

enum Typo {
    enum Weight: String { case regular = "Nunito-Regular", medium = "Nunito-Medium", semibold = "Nunito-SemiBold", bold = "Nunito-Bold", extraBold = "Nunito-ExtraBold" }

    static func font(_ weight: Weight, _ size: CGFloat, relativeTo style: Font.TextStyle = .body) -> Font {
        .custom(weight.rawValue, size: size, relativeTo: style)
    }

    static let display   = font(.extraBold, 30, relativeTo: .largeTitle)
    static let title     = font(.bold, 22, relativeTo: .title2)
    static let heading   = font(.semibold, 17, relativeTo: .headline)
    static let body      = font(.regular, 16, relativeTo: .body)
    static let bodyMedium = font(.medium, 16, relativeTo: .body)
    static let subheadline = font(.regular, 15, relativeTo: .subheadline)
    static let subheadlineMedium = font(.medium, 15, relativeTo: .subheadline)
    static let subheadlineSemibold = font(.semibold, 15, relativeTo: .subheadline)
    static let footnote  = font(.regular, 13, relativeTo: .footnote)
    static let caption   = font(.semibold, 13, relativeTo: .caption)
    static let captionRegular = font(.regular, 12, relativeTo: .caption)
    static let caption2  = font(.medium, 11, relativeTo: .caption2)
    static let number    = font(.extraBold, 28, relativeTo: .largeTitle)
    static let numberSm  = font(.bold, 18, relativeTo: .title3)
    static let button    = font(.bold, 17, relativeTo: .headline)

    /// Applies Nunito to UIKit-backed chrome (navigation bar titles, tab bar labels).
    static func configureAppearance() {
        let nav = UINavigationBar.appearance()
        if let large = UIFont(name: Weight.extraBold.rawValue, size: 34) {
            nav.largeTitleTextAttributes = [.font: UIFontMetrics(forTextStyle: .largeTitle).scaledFont(for: large)]
        }
        if let inline = UIFont(name: Weight.bold.rawValue, size: 17) {
            nav.titleTextAttributes = [.font: UIFontMetrics(forTextStyle: .headline).scaledFont(for: inline)]
        }
        if let tab = UIFont(name: Weight.semibold.rawValue, size: 10) {
            UITabBarItem.appearance().setTitleTextAttributes([.font: tab], for: .normal)
            UITabBarItem.appearance().setTitleTextAttributes([.font: tab], for: .selected)
        }
    }
}

// MARK: - View helpers

struct CardModifier: ViewModifier {
    var padding: CGFloat = 16
    var secondary = false
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(secondary ? Palette.cardSecondary : Palette.card,
                        in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .shadow(color: Color.black.opacity(0.05), radius: 14, x: 0, y: 6)
    }
}

extension View {
    func ceyizCard(padding: CGFloat = 16, secondary: Bool = false) -> some View {
        modifier(CardModifier(padding: padding, secondary: secondary))
    }

    @ViewBuilder
    func `if`<T: View>(_ condition: Bool, transform: (Self) -> T) -> some View {
        if condition { transform(self) } else { self }
    }
}

enum Haptics {
    static func light() { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
    static func success() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
    static func warning() { UINotificationFeedbackGenerator().notificationOccurred(.warning) }
}
