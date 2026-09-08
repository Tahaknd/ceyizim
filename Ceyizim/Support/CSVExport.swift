import Foundation
import SwiftUI
import CoreTransferable
import UniformTypeIdentifiers

/// Lazily rendered CSV file for ShareLink. Uses ";" as separator so it opens
/// correctly in Turkish Excel/Numbers, and a UTF‑8 BOM so accents survive.
struct CSVExport: Transferable {
    let rows: [[String]]

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .commaSeparatedText) { export in
            export.data
        }
        .suggestedFileName("ceyizim-listem.csv")
    }

    init(items: [CeyizItem], currencyCode: String) {
        let header = ["Kategori", "Eşya", "Adet", "Durum", "Öncelik", "Olmazsa Olmaz",
                      "Tahmini Fiyat (\(currencyCode))", "Ödenen (\(currencyCode))",
                      "Mağaza", "Hediye Eden", "Alım Tarihi", "Notlar"]
        let df = DateFormatter()
        df.locale = Money.locale
        df.dateStyle = .short
        var out = [header]
        let sorted = items.sorted {
            let c0 = $0.category?.sortOrder ?? Int.max
            let c1 = $1.category?.sortOrder ?? Int.max
            if c0 != c1 { return c0 < c1 }
            return $0.name.localizedStandardCompare($1.name) == .orderedAscending
        }
        for item in sorted {
            out.append([
                item.category?.name ?? "Diğer",
                item.name,
                String(item.quantity),
                item.status.title,
                item.priority.title,
                item.isMustHave ? "Evet" : "Hayır",
                item.estimatedPrice.map { Self.number($0) } ?? "",
                item.actualPrice.map { Self.number($0) } ?? "",
                item.store,
                item.giftedBy,
                item.purchaseDate.map { df.string(from: $0) } ?? "",
                item.notes.replacingOccurrences(of: "\n", with: " "),
            ])
        }
        rows = out
    }

    private static func number(_ value: Double) -> String {
        value.formatted(.number.locale(Money.locale).precision(.fractionLength(0...2)).grouping(.never))
    }

    var data: Data {
        var text = "\u{FEFF}"
        for row in rows {
            text += row.map(Self.escape).joined(separator: ";") + "\r\n"
        }
        return Data(text.utf8)
    }

    private static func escape(_ field: String) -> String {
        if field.contains(";") || field.contains("\"") || field.contains("\n") {
            return "\"" + field.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return field
    }
}
