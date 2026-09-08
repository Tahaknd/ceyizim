import Foundation

/// Aggregated numbers derived from the whole item list, computed in a single pass.
struct CeyizStats {
    private(set) var total = 0
    private(set) var purchased = 0
    private(set) var gifted = 0
    private(set) var planned = 0
    private(set) var spent: Double = 0
    private(set) var plannedCost: Double = 0
    private(set) var giftValue: Double = 0

    init(items: [CeyizItem]) {
        total = items.count
        for item in items {
            switch item.status {
            case .purchased:
                purchased += 1
                spent += item.spentAmount
            case .gifted:
                gifted += 1
                giftValue += item.giftValue
            case .planned:
                planned += 1
                plannedCost += item.plannedAmount
            }
        }
    }

    var completed: Int { purchased + gifted }
    var progress: Double { total == 0 ? 0 : Double(completed) / Double(total) }
    var percentText: String { "\(Int((progress * 100).rounded()))%" }

    /// Spent so far plus everything still planned.
    var projectedTotal: Double { spent + plannedCost }

    /// Share of the projected total that is already spent (0...1).
    var spentShare: Double { projectedTotal <= 0 ? 0 : min(1, spent / projectedTotal) }

    var hasAnyMoney: Bool { spent > 0 || plannedCost > 0 || giftValue > 0 }
}
