import Foundation
import SwiftData

@Model
final class CeyizCategory {
    var name: String = ""
    var icon: String = "shippingbox.fill"
    var colorKey: String = CategoryColor.rose.rawValue
    var sortOrder: Int = 0
    var createdAt: Date = Date()

    @Relationship(deleteRule: .cascade, inverse: \CeyizItem.category)
    var items: [CeyizItem] = []

    init(name: String, icon: String, color: CategoryColor, sortOrder: Int) {
        self.name = name
        self.icon = icon
        self.colorKey = color.rawValue
        self.sortOrder = sortOrder
        self.createdAt = Date()
    }

    var color: CategoryColor {
        get { CategoryColor(rawValue: colorKey) ?? .rose }
        set { colorKey = newValue.rawValue }
    }

    struct Summary {
        var total = 0, completed = 0
        var spent: Double = 0, planned: Double = 0
        var progress: Double { total == 0 ? 0 : Double(completed) / Double(total) }
    }

    /// One pass over the relationship instead of four separate filters.
    var summary: Summary {
        var s = Summary()
        for item in items {
            s.total += 1
            if item.status.isCompleted { s.completed += 1 }
            s.spent += item.spentAmount
            s.planned += item.plannedAmount
        }
        return s
    }

    var totalCount: Int { items.count }
    var completedCount: Int { summary.completed }
    var progress: Double { summary.progress }
    var spent: Double { summary.spent }
    var planned: Double { summary.planned }
}
