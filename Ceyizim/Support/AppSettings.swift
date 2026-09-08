import Foundation
import SwiftUI

enum SettingsKeys {
    static let hasOnboarded = "hasOnboarded"
    static let userName = "userName"
    static let weddingDate = "weddingDateTimestamp"   // 0 = not set
    static let currency = "currencyCode"
    static let seededTemplate = "seededTemplate"
}

enum AppConfig {
    static let appName = "Çeyizim"
    static let privacyPolicyURL = URL(string: "https://tahaknd.github.io/ceyizim/gizlilik")!
    static let supportURL = URL(string: "https://tahaknd.github.io/ceyizim/destek")!
    static let supportEmail = "ceyizim.app@gmail.com"

    static var versionText: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "Sürüm \(v) (\(b))"
    }
}

struct CurrencyOption: Identifiable, Hashable {
    let code: String
    let title: String
    var id: String { code }

    static let all: [CurrencyOption] = [
        .init(code: "TRY", title: "Türk Lirası (₺)"),
        .init(code: "USD", title: "Amerikan Doları ($)"),
        .init(code: "EUR", title: "Euro (€)"),
        .init(code: "GBP", title: "İngiliz Sterlini (£)"),
    ]
}

enum Money {
    static let locale = Locale(identifier: "tr_TR")

    static func format(_ value: Double, code: String) -> String {
        value.formatted(
            .currency(code: code)
                .locale(locale)
                .precision(.fractionLength(value.rounded() == value ? 0 : 2))
        )
    }

    static func compact(_ value: Double, code: String) -> String {
        if abs(value) >= 1_000_000 {
            return (value / 1_000_000).formatted(.number.locale(locale).precision(.fractionLength(0...1))) + " M " + symbol(code)
        }
        return format(value, code: code)
    }

    static func symbol(_ code: String) -> String {
        switch code {
        case "TRY": return "₺"
        case "USD": return "$"
        case "EUR": return "€"
        case "GBP": return "£"
        default: return code
        }
    }
}

enum WeddingCountdown {
    static func date(from timestamp: Double) -> Date? {
        timestamp > 0 ? Date(timeIntervalSince1970: timestamp) : nil
    }

    /// Days from today until the wedding. Negative when the wedding has passed.
    static func daysUntil(_ date: Date, now: Date = Date()) -> Int {
        let cal = Calendar.current
        let start = cal.startOfDay(for: now)
        let end = cal.startOfDay(for: date)
        return cal.dateComponents([.day], from: start, to: end).day ?? 0
    }

    static func headline(for date: Date) -> String {
        let days = daysUntil(date)
        if days > 1 { return "Düğüne \(days) gün" }
        if days == 1 { return "Düğün yarın! 💐" }
        if days == 0 { return "Düğün bugün! 💐" }
        return "Mutluluklar! 🎉"
    }

    static func subline(for date: Date) -> String {
        let days = daysUntil(date)
        let formatted = date.formatted(.dateTime.day().month(.wide).year().locale(Money.locale))
        if days >= 0 { return formatted }
        return "Düğün \(formatted) tarihindeydi"
    }
}
