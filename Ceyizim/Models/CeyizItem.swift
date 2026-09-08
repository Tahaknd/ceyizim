import Foundation
import SwiftData
import SwiftUI

enum ItemStatus: String, Codable, CaseIterable, Identifiable {
    case planned, purchased, gifted

    var id: String { rawValue }

    var title: String {
        switch self {
        case .planned: return "Alınacak"
        case .purchased: return "Alındı"
        case .gifted: return "Hediye"
        }
    }

    var icon: String {
        switch self {
        case .planned: return "circle"
        case .purchased: return "checkmark.circle.fill"
        case .gifted: return "gift.fill"
        }
    }

    var color: Color {
        switch self {
        case .planned: return Palette.textSecondary
        case .purchased: return Palette.success
        case .gifted: return Palette.gold
        }
    }

    var isCompleted: Bool { self != .planned }
}

enum ItemPriority: Int, Codable, CaseIterable, Identifiable {
    case low = 0, normal = 1, high = 2

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .low: return "Düşük"
        case .normal: return "Normal"
        case .high: return "Yüksek"
        }
    }

    var icon: String {
        switch self {
        case .low: return "arrow.down"
        case .normal: return "minus"
        case .high: return "flame.fill"
        }
    }
}

@Model
final class CeyizItem {
    var name: String = ""
    var quantity: Int = 1
    var statusRaw: String = ItemStatus.planned.rawValue
    var priorityRaw: Int = ItemPriority.normal.rawValue
    var isMustHave: Bool = false
    var estimatedPrice: Double?
    var actualPrice: Double?
    var store: String = ""
    var notes: String = ""
    var giftedBy: String = ""
    var purchaseDate: Date?
    var createdAt: Date = Date()

    @Attribute(.externalStorage)
    var photoData: Data?

    var category: CeyizCategory?

    init(name: String,
         quantity: Int = 1,
         status: ItemStatus = .planned,
         priority: ItemPriority = .normal,
         isMustHave: Bool = false,
         estimatedPrice: Double? = nil,
         category: CeyizCategory? = nil) {
        self.name = name
        self.quantity = max(1, quantity)
        self.statusRaw = status.rawValue
        self.priorityRaw = priority.rawValue
        self.isMustHave = isMustHave
        self.estimatedPrice = estimatedPrice
        self.category = category
        self.createdAt = Date()
    }

    var status: ItemStatus {
        get { ItemStatus(rawValue: statusRaw) ?? .planned }
        set { statusRaw = newValue.rawValue }
    }

    var priority: ItemPriority {
        get { ItemPriority(rawValue: priorityRaw) ?? .normal }
        set { priorityRaw = newValue.rawValue }
    }

    /// Money actually spent: only purchased items count. Falls back to the estimate
    /// when no actual price was entered.
    var spentAmount: Double {
        guard status == .purchased else { return 0 }
        return actualPrice ?? estimatedPrice ?? 0
    }

    /// Money still expected to be spent: only planned items count.
    var plannedAmount: Double {
        guard status == .planned else { return 0 }
        return estimatedPrice ?? 0
    }

    /// Value of gifts received, used for the "savings" statistic.
    var giftValue: Double {
        guard status == .gifted else { return 0 }
        return actualPrice ?? estimatedPrice ?? 0
    }

    /// The most relevant price to show in lists.
    var displayPrice: Double? {
        switch status {
        case .purchased: return actualPrice ?? estimatedPrice
        case .planned, .gifted: return estimatedPrice ?? actualPrice
        }
    }

    func mark(_ newStatus: ItemStatus) {
        status = newStatus
        switch newStatus {
        case .purchased:
            if purchaseDate == nil { purchaseDate = Date() }
        case .gifted:
            if purchaseDate == nil { purchaseDate = Date() }
        case .planned:
            purchaseDate = nil
            actualPrice = nil
            giftedBy = ""
        }
    }
}
