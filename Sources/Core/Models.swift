import Foundation

struct PullRequest: Codable, Identifiable, Sendable {
    let id: String
    let number: Int
    let title: String
    let repository: String
    let url: URL
    let isDraft: Bool
    let checks: String?
}

struct PullRequestSnapshot: Codable, Sendable {
    var requests: [PullRequest]
    var totalCount: Int
    var updatedAt: Date
}

struct CalendarEvent: Codable, Identifiable, Sendable {
    let id: String
    let title: String
    let start: Date
    let end: Date
    let isAllDay: Bool
    let url: URL?
    let color: String

    func occurs(on date: Date, calendar: Calendar = .current) -> Bool {
        let dayStart = calendar.startOfDay(for: date)
        guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else { return false }
        // Google uses an exclusive end, including for multi-day, all-day events.
        return start < dayEnd && (end > dayStart || (start == end && start >= dayStart))
    }
}

struct CalendarTask: Codable, Identifiable, Sendable {
    let id: String
    let title: String
    let dueDay: String?
}

struct CalendarSnapshot: Codable, Sendable {
    let month: String
    let events: [CalendarEvent]
    let tasks: [CalendarTask]
    let updatedAt: Date

    func events(on date: Date, calendar: Calendar = .current) -> [CalendarEvent] {
        events.filter { $0.occurs(on: date, calendar: calendar) }
            .sorted { left, right in
                if left.isAllDay != right.isAllDay { return left.isAllDay }
                return left.start < right.start
            }
    }

    func tasks(on date: Date, calendar: Calendar = .current) -> [CalendarTask] {
        let day = CalendarDates.dayKey(date, calendar: calendar)
        return tasks.filter { $0.dueDay == day }
    }
}

struct CalendarSelection: Codable, Sendable {
    var date: Date
    var changedAt: Date

    func effectiveDate(now: Date = .now, calendar: Calendar = .current) -> Date {
        // Return to today after midnight, rather than freezing an old selection indefinitely.
        calendar.isDate(changedAt, inSameDayAs: now) ? date : now
    }
}

enum WidgetFailure: LocalizedError {
    case message(String)

    var errorDescription: String? {
        switch self {
        case .message(let message): message
        }
    }
}
