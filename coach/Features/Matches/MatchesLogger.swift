import Foundation

enum MatchesLogger {
    static func log(_ message: String) {
        #if DEBUG
        let timestamp = MatchesDateFormatter.hhmmssForLogs.string(from: Date())
        print("[Matches][\(timestamp)] \(message)")
        #endif
    }
}

private extension MatchesDateFormatter {
    static let hhmmssForLogs: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()
}
