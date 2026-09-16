import AppKit
import Observation
import UniformTypeIdentifiers
import WidgetKit

@MainActor @Observable
final class AppModel {
    var githubConnected = false
    var googleConnected = false
    var busy = false
    var message: String?
    var googleConfiguration: GoogleClientConfiguration?
    var signInTask: Task<Void, Never>?
    private let googleSignIn = GoogleSignIn()

    init() { updateConnections() }

    func updateConnections() {
        do {
            githubConnected = try Credentials.read("github") != nil
            googleConnected = try Credentials.read("google") != nil
            if let data = try Credentials.read("google-client") {
                googleConfiguration = try JSONDecoder().decode(GoogleClientConfiguration.self, from: data)
            }
        } catch { message = error.localizedDescription }
    }

    func connectGitHub(token: String) async {
        let token = token.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !token.isEmpty else { return }
        busy = true
        defer { busy = false }
        do {
            let snapshot = try await GitHubClient.fetch(token: token)
            try Credentials.save(Data(token.utf8), account: "github")
            try SharedStore.write(snapshot, to: "github.json")
            message = "GitHub connecté. \(snapshot.totalCount) pull requests ouvertes."
            updateConnections()
            WidgetCenter.shared.reloadTimelines(ofKind: "PullRequestsWidget")
        } catch { message = error.localizedDescription }
    }

    func importGoogleConfiguration() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.message = "Sélectionnez le fichier JSON du client OAuth Google (Application de bureau)."
        guard panel.runModal() == .OK, let url = panel.url else { return }
        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }
        do {
            let configuration = try GoogleClientConfiguration.imported(from: Data(contentsOf: url))
            try Credentials.save(JSONEncoder().encode(configuration), account: "google-client")
            googleConfiguration = configuration
            message = "Configuration Google importée. Vous pouvez vous connecter."
        } catch { message = error.localizedDescription }
    }

    func connectGoogle() {
        guard let configuration = googleConfiguration, !busy else { return }
        busy = true
        message = "Autorisez la connexion dans votre navigateur."
        signInTask = Task {
            defer { busy = false; signInTask = nil }
            do {
                let credentials = try await googleSignIn.connect(configuration: configuration)
                try Task.checkCancellation()
                try SharedStore.remove(prefix: "calendar-")
                try Credentials.save(JSONEncoder().encode(credentials), account: "google")
                updateConnections()
                message = await WidgetSync.shared.calendar(date: .now, force: true) ?? "Google connecté."
                WidgetCenter.shared.reloadTimelines(ofKind: "CalendarWidget")
            } catch is CancellationError {
                message = "Connexion annulée."
            } catch { message = error.localizedDescription }
        }
    }

    func disconnect(_ account: String) {
        do {
            try Credentials.delete(account)
            try SharedStore.remove(prefix: account == "github" ? "github" : "calendar-")
            updateConnections()
            message = "Compte déconnecté de MacWidgets."
            WidgetCenter.shared.reloadAllTimelines()
        } catch { message = error.localizedDescription }
    }

    func refresh() async {
        guard !busy else { return }
        busy = true
        defer { busy = false }
        var errors: [String] = []
        if githubConnected, let error = await WidgetSync.shared.github(force: true) { errors.append(error) }
        if googleConnected, let error = await WidgetSync.shared.calendar(date: SharedStore.selectedDate, force: true) {
            errors.append(error)
        }
        message = errors.isEmpty ? "Les widgets sont à jour." : errors.joined(separator: "\n")
        WidgetCenter.shared.reloadAllTimelines()
    }
}
