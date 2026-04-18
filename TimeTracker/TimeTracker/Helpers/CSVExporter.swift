import Foundation
import SwiftUI
import UniformTypeIdentifiers

struct TimeReport: Transferable {
    let csvData: Data
    let filename: String
    
    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .commaSeparatedText) { report in
            report.csvData
        }
        .suggestedFileName { report in
            report.filename
        }
    }
}

@MainActor
enum CSVExporter {

    // MARK: - Public API

    /// Creates a TimeReport object safely from models
    static func createReport(entries: [TimeEntry], periodName: String) -> TimeReport {
        let csv = generate(entries: entries)
        let data = csv.data(using: .utf8) ?? Data()
        
        let dateStr = Date.exportFormatter.string(from: Date())
        let filename = "FreelanceKit (\(periodName)) \(dateStr).csv"
        
        return TimeReport(csvData: data, filename: filename)
    }

    /// Generates a CSV string from an array of time entries.
    static func generate(entries: [TimeEntry]) -> String {
        let header = AppLocalization.string("Проект,Клієнт,Опис,Дата,Початок,Кінець,Тривалість (год),Оплачено,Теги") + "\n"
        let rows = entries.map { row(for: $0) }.joined(separator: "\n")
        return header + rows
    }

    /// Writes CSV to a temp file and returns its URL for sharing.
    static func makeShareURL(entries: [TimeEntry], projectName: String? = nil, periodName: String? = nil) -> URL {
        let project = projectName.map { "\($0) " } ?? ""
        let period = periodName.map { "(\($0)) " } ?? ""
        let dateStr = Date.exportFormatter.string(from: Date())
        
        // Premium filename: FreelanceKit [Project] (Period) Date.csv
        let filename = "FreelanceKit \(project)\(period)\(dateStr).csv"

        let csv = generate(entries: entries)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try? csv.data(using: .utf8)?.write(to: url)
        return url
    }

    // MARK: - Private

    private static func row(for entry: TimeEntry) -> String {
        let project  = escaped(entry.project?.name ?? "")
        let client   = escaped(entry.project?.client ?? "")
        let desc     = escaped(entry.taskDescription)
        let date     = Date.exportFormatter.string(from: entry.startedAt)
        let start    = Date.timeFormatter.string(from: entry.startedAt)
        let end      = entry.endedAt.map { Date.timeFormatter.string(from: $0) } ?? ""
        let hours    = String(format: "%.2f", entry.duration / 3600.0)
        let billed   = entry.isBilled ? AppLocalization.string("Так") : AppLocalization.string("Ні")
        let tags     = escaped(entry.tags.joined(separator: ", "))

        return "\(project),\(client),\(desc),\(date),\(start),\(end),\(hours),\(billed),\(tags)"
    }

    /// Wraps a field in quotes and escapes internal quotes.
    private static func escaped(_ s: String) -> String {
        let clean = s.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(clean)\""
    }
}

private extension Date {
    static let exportFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.timeStyle = .short
        return f
    }()
}
