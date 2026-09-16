import Foundation

actor WidgetSync {
    static let shared = WidgetSync()

    func github(force: Bool = false) async -> String? {
        do {
            guard let original = try Credentials.read("github"), let token = String(data: original, encoding: .utf8) else {
                return "Connectez GitHub dans MacWidgets."
            }
            if !force, let snapshot = SharedStore.read("github.json", as: PullRequestSnapshot.self),
               snapshot.updatedAt.timeIntervalSinceNow > -900 { return nil }
            let snapshot = try await GitHubClient.fetch(token: token)
            guard try Credentials.read("github") == original else { return "Le compte GitHub a changé." }
            try SharedStore.write(snapshot, to: "github.json")
            return nil
        } catch { return error.localizedDescription }
    }

    func calendar(date: Date, force: Bool = false) async -> String? {
        do {
            guard let original = try Credentials.read("google"),
                  let account = try? JSONDecoder().decode(GoogleCredentials.self, from: original) else {
                return "Connectez Google dans MacWidgets."
            }
            let filename = SharedStore.calendarFile(for: date)
            if !force, let snapshot = SharedStore.read(filename, as: CalendarSnapshot.self),
               snapshot.updatedAt.timeIntervalSinceNow > -900 { return nil }
            let token = try await GoogleTokens.shared.accessToken()
            let snapshot = try await GoogleCalendarClient.fetch(month: date, token: token)
            guard let current = try Credentials.read("google"),
                  let credentials = try? JSONDecoder().decode(GoogleCredentials.self, from: current),
                  credentials.refreshToken == account.refreshToken else { return "Le compte Google a changé." }
            try SharedStore.write(snapshot, to: filename)
            return nil
        } catch { return error.localizedDescription }
    }
}
