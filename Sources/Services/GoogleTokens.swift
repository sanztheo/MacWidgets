import Foundation

struct GoogleClientConfiguration: Codable, Sendable {
    let clientID: String
    let clientSecret: String?

    static func imported(from data: Data) throws -> Self {
        struct Document: Decodable {
            let installed: Installed
            struct Installed: Decodable {
                let client_id: String
                let client_secret: String?
            }
        }
        let document = try JSONDecoder().decode(Document.self, from: data)
        guard document.installed.client_id.hasSuffix(".apps.googleusercontent.com") else {
            throw WidgetFailure.message("Importez un client OAuth Google de type Application de bureau.")
        }
        return Self(clientID: document.installed.client_id, clientSecret: document.installed.client_secret)
    }
}

struct GoogleCredentials: Codable, Sendable {
    let configuration: GoogleClientConfiguration
    let accessToken: String
    let refreshToken: String
    let expiresAt: Date
}

actor GoogleTokens {
    static let shared = GoogleTokens()

    static let scopes = [
        "https://www.googleapis.com/auth/calendar.events.readonly",
        "https://www.googleapis.com/auth/tasks.readonly"
    ]

    func accessToken() async throws -> String {
        guard let original = try Credentials.read("google"),
              let credentials = try? JSONDecoder().decode(GoogleCredentials.self, from: original) else {
            throw WidgetFailure.message("Connectez Google dans MacWidgets.")
        }
        if credentials.expiresAt.timeIntervalSinceNow > 90 { return credentials.accessToken }
        let token = try await requestToken(configuration: credentials.configuration, fields: [
            "refresh_token": credentials.refreshToken,
            "grant_type": "refresh_token"
        ])
        // A disconnect or account change must win over an in-flight token refresh.
        guard try Credentials.read("google") == original else {
            throw WidgetFailure.message("Le compte Google a changé. Réessayez.")
        }
        let updated = GoogleCredentials(
            configuration: credentials.configuration, accessToken: token.access_token,
            refreshToken: token.refresh_token ?? credentials.refreshToken,
            expiresAt: .now.addingTimeInterval(token.expires_in)
        )
        try Credentials.save(JSONEncoder().encode(updated), account: "google")
        return updated.accessToken
    }

    func exchange(code: String, verifier: String, redirectURI: String,
                  configuration: GoogleClientConfiguration) async throws -> GoogleCredentials {
        let token = try await requestToken(configuration: configuration, fields: [
            "code": code, "code_verifier": verifier,
            "redirect_uri": redirectURI, "grant_type": "authorization_code"
        ])
        guard let refreshToken = token.refresh_token else {
            throw WidgetFailure.message("Google n’a pas fourni d’accès hors ligne. Reconnectez le compte.")
        }
        let granted = Set((token.scope ?? "").split(separator: " ").map(String.init))
        guard Set(Self.scopes).isSubset(of: granted) else {
            throw WidgetFailure.message("Autorisez la lecture du calendrier et des tâches pour utiliser ce widget.")
        }
        return GoogleCredentials(
            configuration: configuration, accessToken: token.access_token,
            refreshToken: refreshToken, expiresAt: .now.addingTimeInterval(token.expires_in)
        )
    }

    private func requestToken(configuration: GoogleClientConfiguration,
                              fields: [String: String]) async throws -> TokenResponse {
        var fields = fields
        fields["client_id"] = configuration.clientID
        fields["client_secret"] = configuration.clientSecret
        var request = URLRequest(url: URL(string: "https://oauth2.googleapis.com/token")!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = HTTP.form(fields)
        return try await HTTP.json(TokenResponse.self, request: request)
    }

    private struct TokenResponse: Decodable {
        let access_token: String
        let refresh_token: String?
        let expires_in: Double
        let scope: String?
    }
}
