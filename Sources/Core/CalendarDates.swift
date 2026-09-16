import Foundation

enum CalendarDates {
    static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        calendar.firstWeekday = 2
        return calendar
    }

    static func dayKey(_ date: Date, calendar: Calendar = calendar) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year!, parts.month!, parts.day!)
    }

    static func monthKey(_ date: Date, calendar: Calendar = calendar) -> String {
        String(dayKey(date, calendar: calendar).prefix(7))
    }

    static func monthInterval(_ date: Date, calendar: Calendar = calendar) -> DateInterval {
        calendar.dateInterval(of: .month, for: date)!
    }

    static func cells(for date: Date, calendar: Calendar = calendar) -> [Date?] {
        let interval = monthInterval(date, calendar: calendar)
        let leadingDays = (calendar.component(.weekday, from: interval.start) - calendar.firstWeekday + 7) % 7
        let dayCount = calendar.range(of: .day, in: .month, for: date)!.count
        let cellCount = ((leadingDays + dayCount + 6) / 7) * 7
        return (0..<cellCount).map { index in
            let dayOffset = index - leadingDays
            guard (0..<dayCount).contains(dayOffset) else { return nil }
            return calendar.date(byAdding: .day, value: dayOffset, to: interval.start)
        }
    }

    static func date(fromDay key: String, calendar: Calendar = calendar) -> Date? {
        let pieces = key.split(separator: "-").compactMap { Int($0) }
        guard pieces.count == 3 else { return nil }
        let parts = DateComponents(year: pieces[0], month: pieces[1], day: pieces[2])
        guard let date = calendar.date(from: parts), dayKey(date, calendar: calendar) == key else { return nil }
        return date
    }

    static func parseTimestamp(_ value: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: value) { return date }
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: value)
    }
}
