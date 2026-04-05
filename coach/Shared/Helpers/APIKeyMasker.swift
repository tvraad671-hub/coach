import Foundation

enum APIKeyMasker {
    static func mask(_ rawKey: String) -> String {
        let key = rawKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard key.count > 8 else { return "****" }
        return "\(key.prefix(4))********\(key.suffix(4))"
    }
}
