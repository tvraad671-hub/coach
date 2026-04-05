import Foundation
import Supabase

struct SupabaseEnvironment: Sendable {
    let urlString: String
    let anonKey: String

    static func resolved(bundle: Bundle = .main, processInfo: ProcessInfo = .processInfo) -> SupabaseEnvironment {
        let secrets = secretsDictionary(bundle: bundle)

        let url = firstNonEmpty(
            processInfo.environment["SUPABASE_URL"],
            bundle.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
            secrets["SUPABASE_URL"] as? String
        )

        let anonKey = firstNonEmpty(
            processInfo.environment["SUPABASE_ANON_KEY"],
            bundle.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String,
            secrets["SUPABASE_ANON_KEY"] as? String
        )

        return SupabaseEnvironment(
            urlString: url ?? "",
            anonKey: anonKey ?? ""
        )
    }

    static func custom(
        urlString: String,
        anonKey: String
    ) -> SupabaseEnvironment {
        SupabaseEnvironment(
            urlString: urlString,
            anonKey: anonKey
        )
    }

    private static func firstNonEmpty(_ values: String?...) -> String? {
        values
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first(where: { !$0.isEmpty })
    }

    private static func secretsDictionary(bundle: Bundle) -> [String: Any] {
        guard
            let url = bundle.url(forResource: "Secrets", withExtension: "plist"),
            let data = try? Data(contentsOf: url),
            let object = try? PropertyListSerialization.propertyList(from: data, format: nil),
            let dictionary = object as? [String: Any]
        else {
            return [:]
        }

        return dictionary
    }
}

enum SupabaseConfigurationError: LocalizedError {
    case missingURL
    case invalidURL(String)
    case missingAnonKey
    case secretKeyNotAllowed

    var errorDescription: String? {
        switch self {
        case .missingURL:
            return "قيمة SUPABASE_URL غير موجودة. أضفها في Config.xcconfig أو Info.plist أو Secrets.plist."
        case .invalidURL(let value):
            return "قيمة SUPABASE_URL غير صالحة: \(value)"
        case .missingAnonKey:
            return "قيمة SUPABASE_ANON_KEY غير موجودة. أضفها في Config.xcconfig أو Info.plist أو Secrets.plist."
        case .secretKeyNotAllowed:
            return "تم اكتشاف مفتاح سري داخل التطبيق. استخدم Publishable/Anon Key فقط."
        }
    }
}

final class SupabaseManager {
    static let shared = SupabaseManager()

    let environment: SupabaseEnvironment

    private struct Configuration: Sendable {
        let url: URL
        let anonKey: String
    }

    private lazy var cachedConfigurationResult: Result<Configuration, SupabaseConfigurationError> = {
        do {
            let config = try configuration(from: environment)
            log(
                "Supabase configuration validated. host=\(config.url.host ?? "unknown"), keyLength=\(config.anonKey.count)"
            )
            return .success(config)
        } catch let error as SupabaseConfigurationError {
            log("Supabase configuration error: \(error.errorDescription ?? "unknown")")
            return .failure(error)
        } catch {
            log("Supabase configuration failed with unexpected error: \(String(describing: error))")
            return .failure(.missingURL)
        }
    }()

    private lazy var cachedClientResult: Result<SupabaseClient, SupabaseConfigurationError> = {
        switch cachedConfigurationResult {
        case .success(let config):
            let options = SupabaseClientOptions(auth: .init(autoRefreshToken: true))

            let client = SupabaseClient(
                supabaseURL: config.url,
                supabaseKey: config.anonKey,
                options: options
            )
            print("Supabase initialized")
            log("Supabase client initialized successfully using publishable key.")
            return .success(client)
        case .failure(let error):
            log("Supabase client init skipped due to configuration error: \(error.errorDescription ?? "unknown")")
            return .failure(error)
        }
    }()

    init(environment: SupabaseEnvironment = .resolved()) {
        self.environment = environment
        log(
            "Initializing SupabaseManager. hasURL=\(!environment.urlString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty), hasPublishableKey=\(!environment.anonKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)"
        )
    }

    func client() throws -> SupabaseClient {
        switch cachedClientResult {
        case .success(let client):
            return client
        case .failure(let error):
            throw error
        }
    }

    private func configuration(from environment: SupabaseEnvironment) throws -> Configuration {
        let trimmedURL = environment.urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedURL.isEmpty else {
            throw SupabaseConfigurationError.missingURL
        }

        guard let url = URL(string: trimmedURL) else {
            throw SupabaseConfigurationError.invalidURL(trimmedURL)
        }

        let trimmedAnonKey = environment.anonKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedAnonKey.isEmpty else {
            throw SupabaseConfigurationError.missingAnonKey
        }
        guard !trimmedAnonKey.localizedCaseInsensitiveContains("service_role") else {
            throw SupabaseConfigurationError.secretKeyNotAllowed
        }

        return Configuration(url: url, anonKey: trimmedAnonKey)
    }

    private func log(_ message: String) {
        print("[SupabaseManager] \(message)")
    }
}
