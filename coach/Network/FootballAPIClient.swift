import Foundation

protocol FootballAPIClientProtocol {
    func fetchFixtures(endpoint: FootballEndpoint) async throws -> FixtureResponse
    func fetch<T: Decodable>(_ type: T.Type, endpoint: FootballEndpoint) async throws -> T
}

extension FootballAPIClientProtocol {
    func fetchFixtures(endpoint: FootballEndpoint) async throws -> FixtureResponse {
        try await fetch(FixtureResponse.self, endpoint: endpoint)
    }
}

enum FootballAPIClientError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case decodingFailed(Error)
    case missingAPIKey
    case emptyResponse

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL."
        case .invalidResponse:
            return "Invalid server response."
        case .httpError(let code):
            return "Server returned HTTP \(code)."
        case .decodingFailed:
            return "Failed to decode API data."
        case .missingAPIKey:
            return "Missing FOOTBALL_API_KEY in Secrets.plist."
        case .emptyResponse:
            return "The API response body is empty."
        }
    }
}

struct FootballAPIClient: FootballAPIClientProtocol {
    private let session: URLSession
    private let maxAttempts: Int
    private let requestTimeout: TimeInterval

    init(
        session: URLSession = .shared,
        maxAttempts: Int = 3,
        requestTimeout: TimeInterval = 14
    ) {
        self.session = session
        self.maxAttempts = max(1, maxAttempts)
        self.requestTimeout = max(6, requestTimeout)
        APIConfig.configureURLCacheIfNeeded()
    }

    func fetchFixtures(endpoint: FootballEndpoint) async throws -> FixtureResponse {
        try await fetch(FixtureResponse.self, endpoint: endpoint)
    }

    func fetch<T: Decodable>(_ type: T.Type, endpoint: FootballEndpoint) async throws -> T {
        let apiKey = APIConfig.footballAPIKey
        guard !apiKey.isEmpty else {
            throw FootballAPIClientError.missingAPIKey
        }

        let url: URL
        do {
            url = try endpoint.makeURL(baseURL: APIConfig.footballBaseURL)
        } catch {
            debugError("invalid URL for endpoint: \(endpoint)")
            throw FootballAPIClientError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = requestTimeout
        request.setValue(apiKey, forHTTPHeaderField: "x-apisports-key")
        request.setValue(url.host, forHTTPHeaderField: "Host")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var lastNetworkError: Error?

        for attempt in 1...maxAttempts {
            debugRequest(request, apiKey: apiKey, attempt: attempt)

            let data: Data
            let response: URLResponse
            do {
                (data, response) = try await session.data(for: request)
            } catch {
                lastNetworkError = error
                debugError("network error (attempt \(attempt)): \(error.localizedDescription)")
                if attempt < maxAttempts, shouldRetry(for: error) {
                    await retryDelay(attempt: attempt)
                    continue
                }
                throw error
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                debugError("invalid URLResponse type")
                throw FootballAPIClientError.invalidResponse
            }

            debugStatus(code: httpResponse.statusCode, byteCount: data.count, attempt: attempt)
            debugPayloadErrorsIfAny(data)

            if !(200...299).contains(httpResponse.statusCode) {
                let snippet = responseSnippet(from: data)
                if !snippet.isEmpty {
                    debugError("server body: \(snippet)")
                }

                if attempt < maxAttempts, shouldRetry(statusCode: httpResponse.statusCode) {
                    await retryDelay(attempt: attempt)
                    continue
                }

                throw FootballAPIClientError.httpError(httpResponse.statusCode)
            }

            guard !data.isEmpty else {
                debugError("empty response body")
                throw FootballAPIClientError.emptyResponse
            }

            do {
                let decoded = try JSONDecoder().decode(T.self, from: data)
                if let fixturePayload = decoded as? FixtureResponse {
                    debugDecoded(fixturesCount: fixturePayload.response.count)
                    if let errors = fixturePayload.errors, !errors.values.isEmpty {
                        debugError("fixture payload errors: \(errors.values)")
                    }
                } else {
                    debugDecodedPayload(type: String(describing: T.self))
                }
                return decoded
            } catch {
                debugError("decoding failed for type \(String(describing: T.self)): \(decodingDebugDescription(error))")
                let snippet = responseSnippet(from: data)
                if !snippet.isEmpty {
                    debugError("decoding body snippet: \(snippet)")
                }
                throw FootballAPIClientError.decodingFailed(error)
            }
        }

        throw lastNetworkError ?? FootballAPIClientError.invalidResponse
    }

    private func debugRequest(_ request: URLRequest, apiKey: String, attempt: Int) {
        #if DEBUG
        let method = request.httpMethod ?? "GET"
        let absoluteURL = request.url?.absoluteString ?? "--"
        print("[API] request attempt=\(attempt) \(method) \(absoluteURL)")
        print("[API] key: \(APIKeyMasker.mask(apiKey))")
        print("[API] headers host=\(request.value(forHTTPHeaderField: "Host") ?? "--") accept=\(request.value(forHTTPHeaderField: "Accept") ?? "--") content-type=\(request.value(forHTTPHeaderField: "Content-Type") ?? "--")")
        #endif
    }

    private func debugStatus(code: Int, byteCount: Int, attempt: Int) {
        #if DEBUG
        print("[API] status (attempt \(attempt)): \(code)")
        print("[API] response size: \(byteCount) bytes")
        #endif
    }

    private func debugDecoded(fixturesCount: Int) {
        #if DEBUG
        print("[API] decoded fixtures count: \(fixturesCount)")
        #endif
    }

    private func debugDecodedPayload(type: String) {
        #if DEBUG
        print("[API] decoded payload type: \(type)")
        #endif
    }

    private func debugError(_ message: String) {
        #if DEBUG
        print("[API][Error] \(message)")
        #endif
    }

    private func shouldRetry(statusCode: Int) -> Bool {
        switch statusCode {
        case 408, 425, 429, 500, 502, 503, 504:
            return true
        default:
            return false
        }
    }

    private func shouldRetry(for error: Error) -> Bool {
        if error is CancellationError {
            return false
        }
        guard let urlError = error as? URLError else {
            return false
        }

        switch urlError.code {
        case .timedOut, .networkConnectionLost, .notConnectedToInternet, .cannotFindHost, .cannotConnectToHost, .dnsLookupFailed:
            return true
        default:
            return false
        }
    }

    private func retryDelay(attempt: Int) async {
        let nanos = UInt64(250_000_000 * max(1, attempt))
        try? await Task.sleep(nanoseconds: nanos)
    }

    private func responseSnippet(from data: Data) -> String {
        let text = String(data: data.prefix(1000), encoding: .utf8) ?? ""
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func debugPayloadErrorsIfAny(_ data: Data) {
        #if DEBUG
        guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let errors = object["errors"] as? [String: Any],
              !errors.isEmpty else {
            return
        }
        print("[API][PayloadErrors] \(errors)")
        let snippet = responseSnippet(from: data)
        if !snippet.isEmpty {
            print("[API][PayloadBody] \(snippet)")
        }
        #endif
    }

    private func decodingDebugDescription(_ error: Error) -> String {
        guard let decodingError = error as? DecodingError else {
            return error.localizedDescription
        }

        switch decodingError {
        case .typeMismatch(let type, let context):
            return "typeMismatch(\(type)) path=\(codingPathString(context.codingPath)) reason=\(context.debugDescription)"
        case .valueNotFound(let type, let context):
            return "valueNotFound(\(type)) path=\(codingPathString(context.codingPath)) reason=\(context.debugDescription)"
        case .keyNotFound(let key, let context):
            return "keyNotFound(\(key.stringValue)) path=\(codingPathString(context.codingPath)) reason=\(context.debugDescription)"
        case .dataCorrupted(let context):
            return "dataCorrupted path=\(codingPathString(context.codingPath)) reason=\(context.debugDescription)"
        @unknown default:
            return error.localizedDescription
        }
    }

    private func codingPathString(_ path: [CodingKey]) -> String {
        guard !path.isEmpty else { return "$" }
        return "$." + path.map(\.stringValue).joined(separator: ".")
    }
}
