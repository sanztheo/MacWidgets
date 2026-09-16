import Foundation

enum HTTP {
    static func data(for request: URLRequest) async throws -> Data {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 25
        let session = URLSession(configuration: configuration)
        defer { session.invalidateAndCancel() }
        let (data, response) = try await session.data(for: request)
        guard let response = response as? HTTPURLResponse else {
            throw WidgetFailure.message("Réponse du serveur invalide.")
        }
        switch response.statusCode {
        case 200..<300: return data
        case 401: throw WidgetFailure.message("Connexion expirée. Reconnectez le compte dans MacWidgets.")
        case 403: throw WidgetFailure.message("Accès refusé : vérifiez les autorisations du compte et les quotas.")
        case 429: throw WidgetFailure.message("Limite de requêtes atteinte. Réessayez plus tard.")
        default: throw WidgetFailure.message("Le service est indisponible (HTTP \(response.statusCode)).")
        }
    }

    static func json<Value: Decodable>(_ type: Value.Type, request: URLRequest) async throws -> Value {
        try JSONDecoder().decode(type, from: await data(for: request))
    }

    static func form(_ values: [String: String]) -> Data {
        let allowed = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~")
        return values.sorted { $0.key < $1.key }.map { key, value in
            "\(key.addingPercentEncoding(withAllowedCharacters: allowed)!)=\(value.addingPercentEncoding(withAllowedCharacters: allowed)!)"
        }.joined(separator: "&").data(using: .utf8)!
    }
}
