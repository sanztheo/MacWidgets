import Foundation

@main
struct CoreChecks {
    static func main() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Toronto")!
        calendar.firstWeekday = 2
        let september = CalendarDates.date(fromDay: "2026-09-16", calendar: calendar)!
        let cells = CalendarDates.cells(for: september, calendar: calendar)
        assert(cells.count == 35 && cells[0] == nil)
        assert(CalendarDates.dayKey(cells[1]!, calendar: calendar) == "2026-09-01")
        assert(CalendarDates.dayKey(cells[16]!, calendar: calendar) == "2026-09-16")
        assert(CalendarDates.date(fromDay: "2026-02-30", calendar: calendar) == nil)
        let leapDay = CalendarDates.date(fromDay: "2028-02-29", calendar: calendar)!
        assert(CalendarDates.cells(for: leapDay, calendar: calendar).compactMap { $0 }.count == 29)
        let sixWeeks = CalendarDates.date(fromDay: "2026-03-01", calendar: calendar)!
        assert(CalendarDates.cells(for: sixWeeks, calendar: calendar).count == 42)

        let march8 = CalendarDates.date(fromDay: "2026-03-08", calendar: calendar)!
        let march9 = CalendarDates.date(fromDay: "2026-03-09", calendar: calendar)!
        assert(march9.timeIntervalSince(march8) == 23 * 3600)
        let allDay = CalendarEvent(id: "day", title: "DST", start: march8, end: march9,
                                   isAllDay: true, url: nil, color: "9")
        assert(allDay.occurs(on: march8, calendar: calendar))
        assert(!allDay.occurs(on: march9, calendar: calendar))
        let overnight = CalendarEvent(id: "night", title: "Overnight",
            start: march9.addingTimeInterval(-1800), end: march9.addingTimeInterval(1800),
            isAllDay: false, url: nil, color: "9")
        assert(overnight.occurs(on: march8, calendar: calendar) && overnight.occurs(on: march9, calendar: calendar))
        let selection = CalendarSelection(date: september, changedAt: march8)
        assert(selection.effectiveDate(now: march9, calendar: calendar) == march9)
        assert(CalendarDates.parseTimestamp("2026-09-16T09:30:00.123-04:00") != nil)

        let graphql = Data(#"{"data":{"viewer":{"pullRequests":{"totalCount":1,"nodes":[{"id":"pr1","number":1,"title":"Example","url":"https://github.com/example/project/pull/1","isDraft":false,"repository":{"nameWithOwner":"example/project"},"commits":{"nodes":[{"commit":{"statusCheckRollup":{"state":"SUCCESS"}}}]}}]}}}}"#.utf8)
        let snapshot = try GitHubClient.decode(graphql)
        assert(snapshot.totalCount == 1 && snapshot.requests.first?.checks == "SUCCESS")
        do {
            _ = try GitHubClient.decode(Data(#"{"data":null,"errors":[{"message":"denied"}]}"#.utf8))
            assertionFailure("A GraphQL error must not look like an empty list")
        } catch { }
        let unsafe = String(decoding: graphql, as: UTF8.self)
            .replacingOccurrences(of: "https://github.com/example/project/pull/1", with: "https://example.invalid/phishing")
        do {
            _ = try GitHubClient.decode(Data(unsafe.utf8))
            assertionFailure("Reject untrusted PR destinations")
        } catch { }
        let form = String(data: HTTP.form(["code": "a+b&c=d e"]), encoding: .utf8)!
        assert(form == "code=a%2Bb%26c%3Dd%20e")

        let eventJSON = Data(#"{"id":"all-day","start":{"date":"2026-09-16"},"end":{"date":"2026-09-17"}}"#.utf8)
        let event = try JSONDecoder().decode(GoogleCalendarClient.EventRecord.self, from: eventJSON).event()
        assert(event.isAllDay && event.title == "Sans titre")
        let localDate = CalendarDates.date(fromDay: "2026-09-16")!
        assert(event.occurs(on: localDate))
        let tasks = [CalendarTask(id: "task", title: "Date only", dueDay: "2026-09-16")]
        let agenda = CalendarSnapshot(month: "2026-09", events: [event], tasks: tasks, updatedAt: .now)
        assert(agenda.tasks(on: localDate).count == 1)
        print("Core checks passed: calendar, DST, midnight, GraphQL errors, URLs, OAuth form and Google dates.")
    }
}
