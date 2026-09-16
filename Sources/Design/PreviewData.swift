import Foundation

enum PreviewData {
    static let date = CalendarDates.date(fromDay: "2026-09-16")!

    static var calendar: CalendarSnapshot {
        func time(_ hour: Int, _ minute: Int = 0) -> Date {
            CalendarDates.calendar.date(bySettingHour: hour, minute: minute, second: 0, of: date)!
        }
        return CalendarSnapshot(month: "2026-09", events: [
            CalendarEvent(id: "sample-1", title: "Point équipe", start: time(9, 30), end: time(10),
                          isAllDay: false, url: nil, color: "9"),
            CalendarEvent(id: "sample-2", title: "Revue produit", start: time(14), end: time(15),
                          isAllDay: false, url: nil, color: "6"),
            CalendarEvent(id: "sample-3", title: "Appel client", start: time(16, 30), end: time(17),
                          isAllDay: false, url: nil, color: "10")
        ], tasks: [CalendarTask(id: "sample-task", title: "Envoyer le devis", dueDay: "2026-09-16")], updatedAt: .now)
    }

    static let github = PullRequestSnapshot(requests: [
        PullRequest(id: "sample-1", number: 24, title: "Améliorer la recherche du calendrier",
                    repository: "octocat / calendar", url: URL(string: "https://github.com/pulls")!,
                    isDraft: false, checks: "SUCCESS"),
        PullRequest(id: "sample-2", number: 18, title: "Ajouter les nouveaux widgets natifs",
                    repository: "octocat / widgets", url: URL(string: "https://github.com/pulls")!,
                    isDraft: false, checks: nil)
    ], totalCount: 2, updatedAt: .now)
}
