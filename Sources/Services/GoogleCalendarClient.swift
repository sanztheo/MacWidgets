import Foundation

enum GoogleCalendarClient {
    static func fetch(month: Date, token: String) async throws -> CalendarSnapshot {
        let interval = CalendarDates.monthInterval(month)
        let formatter = ISO8601DateFormatter()
        async let events = eventPages(token: token, parameters: [
            "timeMin": formatter.string(from: interval.start),
            "timeMax": formatter.string(from: interval.end),
            "timeZone": TimeZone.current.identifier,
            "singleEvents": "true", "orderBy": "startTime", "maxResults": "2500"
        ])
        async let tasks = allTasks(token: token)
        return try await CalendarSnapshot(
            month: CalendarDates.monthKey(month), events: events, tasks: tasks, updatedAt: .now
        )
    }

    private static func eventPages(token: String, parameters: [String: String]) async throws -> [CalendarEvent] {
        let records: [EventRecord] = try await pages(
            url: "https://www.googleapis.com/calendar/v3/calendars/primary/events",
            token: token, parameters: parameters
        )
        return try records.filter { $0.status != "cancelled" }.map { try $0.event() }
    }

    private static func allTasks(token: String) async throws -> [CalendarTask] {
        let lists: [TaskListRecord] = try await pages(
            url: "https://tasks.googleapis.com/tasks/v1/users/@me/lists", token: token,
            parameters: ["maxResults": "1000"]
        )
        var tasks: [CalendarTask] = []
        for list in lists {
            let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-._~"))
            let identifier = list.id.addingPercentEncoding(withAllowedCharacters: allowed)!
            let records: [TaskRecord] = try await pages(
                url: "https://tasks.googleapis.com/tasks/v1/lists/\(identifier)/tasks",
                token: token, parameters: ["maxResults": "100", "showCompleted": "false", "showDeleted": "false"]
            )
            tasks += records.filter { $0.status != "completed" && $0.deleted != true }.map {
                // Tasks due values contain a calendar date, not an instant to convert to local time.
                CalendarTask(id: "\(list.id):\($0.id)", title: $0.title ?? "Sans titre",
                             dueDay: $0.due.map { String($0.prefix(10)) })
            }
        }
        return tasks
    }

    private static func pages<Item: Decodable>(url: String, token: String,
                                               parameters: [String: String]) async throws -> [Item] {
        var items: [Item] = []
        var pageToken: String?
        var seenTokens = Set<String>()
        repeat {
            var query = parameters
            query["pageToken"] = pageToken
            var components = URLComponents(string: url)!
            components.queryItems = query.sorted { $0.key < $1.key }.map(URLQueryItem.init)
            var request = URLRequest(url: components.url!)
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            let page = try await HTTP.json(Page<Item>.self, request: request)
            items += page.items ?? []
            pageToken = page.nextPageToken
            if let pageToken, !seenTokens.insert(pageToken).inserted {
                throw WidgetFailure.message("Pagination Google interrompue. Réessayez.")
            }
        } while pageToken != nil
        return items
    }

    private struct Page<Item: Decodable>: Decodable {
        let items: [Item]?
        let nextPageToken: String?
    }

    private struct TaskListRecord: Decodable { let id: String }
    private struct TaskRecord: Decodable {
        let id: String
        let title: String?
        let due: String?
        let status: String?
        let deleted: Bool?
    }

    struct EventRecord: Decodable {
        let id: String
        let summary: String?
        let status: String?
        let start: EventDate?
        let end: EventDate?
        let htmlLink: String?
        let colorId: String?

        func event() throws -> CalendarEvent {
            guard let start, let end,
                  let startDate = start.parsed, let endDate = end.parsed, endDate >= startDate else {
                throw WidgetFailure.message("Un événement Google contient une date invalide.")
            }
            let url = htmlLink.flatMap(URL.init(string:))
            return CalendarEvent(
                id: id, title: summary ?? "Sans titre", start: startDate, end: endDate,
                isAllDay: start.date != nil,
                url: url?.scheme == "https" ? url : nil, color: colorId ?? "9"
            )
        }
    }

    struct EventDate: Decodable {
        let date: String?
        let dateTime: String?

        var parsed: Date? {
            if let date { return CalendarDates.date(fromDay: date) }
            return dateTime.flatMap(CalendarDates.parseTimestamp)
        }
    }
}
