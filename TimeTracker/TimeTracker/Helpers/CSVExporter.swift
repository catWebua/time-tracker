import Foundation

enum CSVExporter {

    // MARK: - Public API

    /// Generates a CSV string from an array of time entries.
    static func generate(entries: [TimeEntry]) -> String {
        let header = "Проект,Клієнт,Опис,Дата,Початок,Кінець,Тривалість (год),Оплачено,Теги\n"
        let rows = entries.map { row(for: $0) }.joined(separator: "\n")
        return header + rows
    }

    /// Writes CSV to a temp file and returns its URL for sharing.
    static func makeShareURL(entries: [TimeEntry], projectName: String? = nil) -> URL {
        let name = projectName.map { "\($0) " } ?? ""
        let dateStr = Date.exportFormatter.string(from: Date())
        let filename = "\(name)TimeTracker \(dateStr).csv"

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
        let billed   = entry.isBilled ? "Так" : "Ні"
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
