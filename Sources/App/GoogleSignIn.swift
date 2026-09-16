import AppKit
import CryptoKit
import Foundation
import Network
import Security

@MainActor
final class GoogleSignIn {
    private var listener: NWListener?
    private var completion: CheckedContinuation<String, Error>?
    private var timeout: Task<Void, Never>?
    private var expectedState = ""
    private var redirectURI = ""

    func connect(configuration: GoogleClientConfiguration) async throws -> GoogleCredentials {
        let verifier = try randomValue()
        expectedState = try randomValue()
        let challenge = Data(SHA256.hash(data: Data(verifier.utf8))).base64URL
        let code = try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                completion = continuation
                do { try start(configuration: configuration, challenge: challenge) }
                catch { finish(.failure(error)) }
            }
        } onCancel: {
            Task { @MainActor in self.finish(.failure(CancellationError())) }
        }
        try Task.checkCancellation()
        return try await GoogleTokens.shared.exchange(
            code: code, verifier: verifier, redirectURI: redirectURI, configuration: configuration
        )
    }

    private func start(configuration: GoogleClientConfiguration, challenge: String) throws {
        let parameters = NWParameters.tcp
        parameters.requiredLocalEndpoint = .hostPort(host: "127.0.0.1", port: .any)
        let listener = try NWListener(using: parameters)
        self.listener = listener
        listener.stateUpdateHandler = { [weak self] state in
            Task { @MainActor in
                guard let self else { return }
                switch state {
                case .ready:
                    guard let port = self.listener?.port else { return }
                    self.redirectURI = "http://127.0.0.1:\(port.rawValue)"
                    self.openBrowser(configuration: configuration, challenge: challenge)
                case .failed:
                    self.finish(.failure(WidgetFailure.message("Impossible de démarrer la connexion locale Google.")))
                default: break
                }
            }
        }
        listener.newConnectionHandler = { [weak self] connection in
            Task { @MainActor in
                guard let self else { connection.cancel(); return }
                connection.start(queue: .main)
                self.receive(connection, buffer: Data())
            }
        }
        listener.start(queue: .main)
        timeout = Task { [weak self] in
            try? await Task.sleep(for: .seconds(180))
            guard !Task.isCancelled else { return }
            self?.finish(.failure(WidgetFailure.message("Connexion Google expirée. Réessayez.")))
        }
    }

    private func openBrowser(configuration: GoogleClientConfiguration, challenge: String) {
        var url = URLComponents(string: "https://accounts.google.com/o/oauth2/v2/auth")!
        url.queryItems = [
            "client_id": configuration.clientID,
            "redirect_uri": redirectURI,
            "response_type": "code",
            "scope": GoogleTokens.scopes.joined(separator: " "),
            "code_challenge": challenge,
            "code_challenge_method": "S256",
            "state": expectedState,
            "access_type": "offline",
            "prompt": "consent"
        ].map(URLQueryItem.init)
        guard let url = url.url, NSWorkspace.shared.open(url) else {
            finish(.failure(WidgetFailure.message("Impossible d’ouvrir le navigateur.")))
            return
        }
    }

    private func receive(_ connection: NWConnection, buffer: Data) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 8192) { [weak self] data, _, complete, error in
            Task { @MainActor in
                guard let self else { connection.cancel(); return }
                var received = buffer
                received.append(data ?? Data())
                guard received.count <= 8192, error == nil else { connection.cancel(); return }
                if let request = String(data: received, encoding: .utf8), request.contains("\r\n\r\n") {
                    self.respond(to: connection, request: request)
                } else if !complete {
                    self.receive(connection, buffer: received)
                } else { connection.cancel() }
            }
        }
    }

    private func respond(to connection: NWConnection, request: String) {
        let words = request.components(separatedBy: "\r\n")[0].split(separator: " ")
        guard words.count == 3, words[0] == "GET",
              let url = URLComponents(string: redirectURI + String(words[1])), url.path == "/",
              url.queryItems?.filter({ $0.name == "state" }).count == 1,
              url.queryItems?.first(where: { $0.name == "state" })?.value == expectedState else {
            connection.cancel()
            return
        }
        let code = url.queryItems?.first(where: { $0.name == "code" })?.value
        let denied = url.queryItems?.contains(where: { $0.name == "error" }) == true
        let html = "<meta charset='utf-8'><title>MacWidgets</title><p>Vous pouvez revenir à MacWidgets.</p>"
        let response = "HTTP/1.1 200 OK\r\nContent-Type: text/html; charset=utf-8\r\nCache-Control: no-store\r\nConnection: close\r\nContent-Length: \(html.utf8.count)\r\n\r\n\(html)"
        connection.send(content: Data(response.utf8), completion: .contentProcessed { _ in connection.cancel() })
        if let code, !code.isEmpty, !denied {
            finish(.success(code))
        } else {
            finish(.failure(WidgetFailure.message("L’accès Google n’a pas été autorisé.")))
        }
    }

    private func finish(_ result: Result<String, Error>) {
        let continuation = completion
        completion = nil
        listener?.cancel()
        listener = nil
        timeout?.cancel()
        timeout = nil
        continuation?.resume(with: result)
    }

    private func randomValue() throws -> String {
        var bytes = [UInt8](repeating: 0, count: 32)
        guard SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes) == errSecSuccess else {
            throw WidgetFailure.message("La génération du code de connexion a échoué.")
        }
        return Data(bytes).base64URL
    }
}

private extension Data {
    var base64URL: String {
        base64EncodedString().replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_").replacingOccurrences(of: "=", with: "")
    }
}
