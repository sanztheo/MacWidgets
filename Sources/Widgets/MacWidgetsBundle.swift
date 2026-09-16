import SwiftUI
import WidgetKit

@main
struct MacWidgetsBundle: WidgetBundle {
    var body: some Widget {
        PullRequestsWidget()
        GoogleCalendarWidget()
    }
}

struct PullRequestsWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "PullRequestsWidget", provider: GitHubProvider()) { entry in
            PullRequestWidgetContent(entry: entry)
                .containerBackground(for: .widget) { WidgetStyle.background }
        }
        .configurationDisplayName("GitHub · Pull requests")
        .description("Vos pull requests ouvertes, avec leurs vérifications et un accès direct à GitHub.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .contentMarginsDisabled()
    }
}

private struct PullRequestWidgetContent: View {
    @Environment(\.widgetFamily) private var family
    let entry: GitHubEntry

    var body: some View {
        PullRequestView(snapshot: entry.snapshot, size: family == .systemSmall ? .small :
                            family == .systemMedium ? .medium : .large, error: entry.error)
    }
}

struct GoogleCalendarWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "CalendarWidget", provider: CalendarProvider()) { entry in
            CalendarWidgetContent(entry: entry)
                .containerBackground(for: .widget) { WidgetStyle.background }
        }
        .configurationDisplayName("Google Calendar")
        .description("Le mois, l’agenda du jour sélectionné et vos tâches Google.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .systemExtraLarge])
        .contentMarginsDisabled()
    }
}

private struct CalendarWidgetContent: View {
    @Environment(\.widgetFamily) private var family
    let entry: CalendarEntry

    private var size: WidgetSize {
        switch family {
        case .systemSmall: .small
        case .systemMedium: .medium
        case .systemExtraLarge: .wide
        default: .large
        }
    }

    var body: some View {
        CalendarView(snapshot: entry.snapshot, selectedDate: entry.selectedDate, size: size, error: entry.error)
            .invalidatableContent()
    }
}
