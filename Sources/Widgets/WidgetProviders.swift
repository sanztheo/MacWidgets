import WidgetKit

struct GitHubEntry: TimelineEntry {
    let date: Date
    let snapshot: PullRequestSnapshot?
    let error: String?
}

struct GitHubProvider: TimelineProvider {
    func placeholder(in context: Context) -> GitHubEntry {
        GitHubEntry(date: .now, snapshot: PreviewData.github, error: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping @Sendable (GitHubEntry) -> Void) {
        completion(context.isPreview ? placeholder(in: context) :
            GitHubEntry(date: .now, snapshot: SharedStore.read("github.json", as: PullRequestSnapshot.self), error: nil))
    }

    func getTimeline(in context: Context, completion: @escaping @Sendable (Timeline<GitHubEntry>) -> Void) {
        Task {
            let error = await WidgetSync.shared.github()
            let snapshot = SharedStore.read("github.json", as: PullRequestSnapshot.self)
            completion(Timeline(entries: [GitHubEntry(date: .now, snapshot: snapshot, error: error)],
                                policy: .after(.now.addingTimeInterval(900))))
        }
    }
}

struct CalendarEntry: TimelineEntry {
    let date: Date
    let selectedDate: Date
    let snapshot: CalendarSnapshot?
    let error: String?
}

struct CalendarProvider: TimelineProvider {
    func placeholder(in context: Context) -> CalendarEntry {
        CalendarEntry(date: .now, selectedDate: PreviewData.date, snapshot: PreviewData.calendar, error: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping @Sendable (CalendarEntry) -> Void) {
        let selected = SharedStore.selectedDate
        completion(context.isPreview ? placeholder(in: context) : CalendarEntry(
            date: .now, selectedDate: selected,
            snapshot: SharedStore.read(SharedStore.calendarFile(for: selected), as: CalendarSnapshot.self), error: nil
        ))
    }

    func getTimeline(in context: Context, completion: @escaping @Sendable (Timeline<CalendarEntry>) -> Void) {
        Task {
            let selected = SharedStore.selectedDate
            let error = await WidgetSync.shared.calendar(date: selected)
            let entry = CalendarEntry(
                date: .now, selectedDate: selected,
                snapshot: SharedStore.read(SharedStore.calendarFile(for: selected), as: CalendarSnapshot.self), error: error
            )
            let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: .now))!
            completion(Timeline(entries: [entry], policy: .after(min(.now.addingTimeInterval(900), nextDay))))
        }
    }
}
