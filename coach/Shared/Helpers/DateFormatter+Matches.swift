import Foundation

enum MatchesDateFormatter {
    static func formatKickoff(isoDateString: String) -> String {
        let trimmed = isoDateString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "--:--" }

        if let date = isoWithFractional.date(from: trimmed) ?? isoStandard.date(from: trimmed) {
            return hhmmFormatter.string(from: date)
        }

        return "--:--"
    }

    static func todayDateString(in timeZone: TimeZone = .current) -> String {
        dateString(for: Date(), in: timeZone)
    }

    static func dateString(for date: Date, in timeZone: TimeZone) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone

        let components = calendar.dateComponents([.year, .month, .day], from: date)
        guard let year = components.year,
              let month = components.month,
              let day = components.day else {
            return fallbackTodayFormatter.string(from: date)
        }

        return String(format: "%04d-%02d-%02d", year, month, day)
    }

    static func seasonStartYear(for date: Date = Date(), in timeZone: TimeZone = .current) -> Int {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone

        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)

        return month >= 7 ? year : (year - 1)
    }

    static func localTimezoneIdentifier() -> String {
        let identifier = TimeZone.current.identifier.trimmingCharacters(in: .whitespacesAndNewlines)
        return identifier.isEmpty ? "UTC" : identifier
    }

    private static let hhmmFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale.autoupdatingCurrent
        formatter.timeZone = .current
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    private static let fallbackTodayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private static let isoWithFractional: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let isoStandard: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
}
