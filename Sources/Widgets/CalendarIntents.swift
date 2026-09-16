import AppIntents
import WidgetKit

struct SelectCalendarDay: AppIntent {
    static var title: LocalizedStringResource { "Afficher ce jour" }
    static var description: IntentDescription { "Affiche les événements du jour choisi dans le widget." }
    @Parameter(title: "Date") var date: Date

    init() {}
    init(date: Date) { self.date = date }

    func perform() async throws -> some IntentResult {
        try SharedStore.write(CalendarSelection(date: date, changedAt: .now), to: "selection.json")
        WidgetCenter.shared.reloadTimelines(ofKind: "CalendarWidget")
        return .result()
    }
}
