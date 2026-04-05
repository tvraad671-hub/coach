import Foundation

enum APIConfig {
    static let footballBaseURL = URL(string: "https://v3.football.api-sports.io")!

    private static let secretsFileName = "Secrets"
    private static let apiKeyName = "FOOTBALL_API_KEY"

    // Keep API credentials in Secrets.plist only, never hardcode keys in source files.
    static var footballAPIKey: String {
        guard let raw = secretsDictionary?[apiKeyName] as? String else {
            #if DEBUG
            assertionFailure("Missing \(apiKeyName) in Secrets.plist")
            #endif
            return ""
        }

        let key = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty, !isPlaceholderKey(key) else {
            #if DEBUG
            assertionFailure("Empty or placeholder \(apiKeyName) in Secrets.plist")
            #endif
            return ""
        }

        return key
    }

    static var timezoneIdentifier: String {
        MatchesDateFormatter.localTimezoneIdentifier()
    }

    static func configureURLCacheIfNeeded() {
        _ = cacheConfiguration
    }

    private static let cacheConfiguration: Void = {
        let current = URLCache.shared
        let minimumMemory = 40 * 1024 * 1024
        let minimumDisk = 150 * 1024 * 1024

        if current.memoryCapacity >= minimumMemory, current.diskCapacity >= minimumDisk {
            return
        }

        URLCache.shared = URLCache(
            memoryCapacity: minimumMemory,
            diskCapacity: minimumDisk,
            diskPath: "football-api-cache"
        )
    }()

    private static var secretsDictionary: [String: Any]? {
        guard let url = Bundle.main.url(forResource: secretsFileName, withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let object = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil),
              let dict = object as? [String: Any] else {
            return nil
        }
        return dict
    }

    private static func isPlaceholderKey(_ key: String) -> Bool {
        let upper = key.uppercased()
        return upper == "YOUR_API_KEY"
            || upper == "<YOUR_API_KEY>"
            || upper == "REPLACE_ME"
            || upper == "FOOTBALL_API_KEY"
    }
}
