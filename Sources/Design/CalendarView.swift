import SwiftUI

struct CalendarView: View {
    let snapshot: CalendarSnapshot?
    let selectedDate: Date
    let size: WidgetSize
    var error: String?
    var selectDate: ((Date) -> Void)?

    private var events: [CalendarEvent] {
        snapshot?.events(on: selectedDate, calendar: CalendarDates.calendar) ?? []
    }
    private var tasks: [CalendarTask] {
        snapshot?.tasks(on: selectedDate, calendar: CalendarDates.calendar) ?? []
    }

    var body: some View {
        GeometryReader { geometry in
            Group {
                switch size {
                case .small:
                    monthGrid
                case .medium, .wide:
                    HStack(alignment: .top, spacing: size.compact ? 12 : 24) {
                        monthGrid.frame(width: (geometry.size.width - (size.compact ? 25 : 49)) * 0.53)
                        Rectangle().fill(.white.opacity(0.12)).frame(width: 1)
                        agenda.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    }
                case .large:
                    VStack(alignment: .leading, spacing: 12) {
                        monthGrid.frame(height: geometry.size.height * 0.53)
                        Rectangle().fill(.white.opacity(0.12)).frame(height: 1)
                        agenda
                    }
                }
            }
            .foregroundStyle(.white)
        }
        .padding(size.compact ? 14 : 20)
    }

    private var monthGrid: some View {
        let cells = CalendarDates.cells(for: selectedDate)
        let columns = Array(repeating: GridItem(.flexible(), spacing: 1), count: 7)
        return VStack(spacing: size.compact ? 5 : 10) {
            HStack(spacing: size.compact ? 5 : 10) {
                CalendarMark(size: size.compact ? 16 : 24)
                Text(selectedDate.formatted(.dateTime.month(.wide).year().locale(Locale(identifier: "fr_FR"))).capitalized)
                    .font(.system(size: size.compact ? 11 : 19, weight: .semibold))
                    .lineLimit(1).minimumScaleFactor(0.8)
                Spacer(minLength: 0)
                if !size.compact {
                    monthButton(offset: -1, symbol: "chevron.left")
                    monthButton(offset: 1, symbol: "chevron.right")
                }
            }
            LazyVGrid(columns: columns, spacing: 0) {
                ForEach(Array(["L", "M", "M", "J", "V", "S", "D"].enumerated()), id: \.offset) { _, day in
                    Text(day).font(.system(size: size.compact ? 10 : 12, weight: .medium))
                        .foregroundStyle(WidgetStyle.secondary).frame(maxWidth: .infinity)
                }
            }
            GeometryReader { geometry in
                let rowHeight = geometry.size.height / CGFloat(cells.count / 7)
                LazyVGrid(columns: columns, spacing: 0) {
                    ForEach(cells.indices, id: \.self) { index in
                        if let date = cells[index] {
                            dayButton(date: date, height: rowHeight)
                        } else {
                            Color.clear.frame(height: rowHeight).accessibilityHidden(true)
                        }
                    }
                }
            }
            if size == .small, error != nil {
                Image(systemName: "exclamationmark.circle").font(.system(size: 10))
                    .foregroundStyle(.orange).accessibilityLabel(error ?? "")
            }
        }
    }

    @ViewBuilder
    private func dayButton(date: Date, height: CGFloat) -> some View {
        if let selectDate {
            Button { selectDate(date) } label: { dayLabel(date: date, height: height) }
                .buttonStyle(.plain)
        } else {
            Button(intent: SelectCalendarDay(date: date)) { dayLabel(date: date, height: height) }
                .buttonStyle(.plain)
        }
    }

    private func dayLabel(date: Date, height: CGFloat) -> some View {
        let selected = CalendarDates.calendar.isDate(date, inSameDayAs: selectedDate)
        let dayEvents = snapshot?.events(on: date, calendar: CalendarDates.calendar) ?? []
        return VStack(spacing: 1) {
            Text("\(CalendarDates.calendar.component(.day, from: date))")
                .font(.system(size: size.compact ? 11 : 14, weight: selected ? .semibold : .regular))
                .fixedSize()
                .frame(width: min(height - 5, size.compact ? 21 : 29), height: min(height - 5, size.compact ? 21 : 29))
                .background { if selected { Circle().fill(WidgetStyle.blue) } }
            HStack(spacing: 2) {
                ForEach(Array(dayEvents.prefix(3).enumerated()), id: \.offset) { _, event in
                    Circle().fill(WidgetStyle.eventColor(event.color)).frame(width: 3, height: 3)
                }
            }.frame(height: 3)
        }
        .frame(maxWidth: .infinity).frame(height: height)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(date.formatted(date: .complete, time: .omitted))
        .accessibilityValue("\(dayEvents.count) événements")
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    @ViewBuilder
    private func monthButton(offset: Int, symbol: String) -> some View {
        if let date = CalendarDates.calendar.date(byAdding: .month, value: offset, to: selectedDate) {
            if let selectDate {
                Button { selectDate(date) } label: { Image(systemName: symbol).frame(width: 20, height: 24) }
                    .buttonStyle(.plain).accessibilityLabel(offset < 0 ? "Mois précédent" : "Mois suivant")
            } else {
                Button(intent: SelectCalendarDay(date: date)) {
                    Image(systemName: symbol).frame(width: 20, height: 24)
                }
                .buttonStyle(.plain).accessibilityLabel(offset < 0 ? "Mois précédent" : "Mois suivant")
            }
        }
    }

    private var agenda: some View {
        VStack(alignment: .leading, spacing: size == .large ? 8 : size.compact ? 9 : 12) {
            Text(selectedDate.formatted(.dateTime.weekday(.wide).day().locale(Locale(identifier: "fr_FR"))).capitalized)
                .font(.system(size: size.compact ? 13 : 20, weight: .semibold)).lineLimit(1)
            if snapshot == nil {
                Text(error ?? "Connectez Google dans MacWidgets.")
                    .font(.system(size: size.compact ? 11 : 13)).foregroundStyle(WidgetStyle.secondary)
            } else {
                if events.isEmpty {
                    Text("Aucun événement").font(.system(size: 12)).foregroundStyle(WidgetStyle.secondary)
                }
                ForEach(events.prefix(size == .wide ? 3 : 2)) { event in
                    Link(destination: event.url ?? URL(string: "https://calendar.google.com")!) {
                        eventRow(event)
                    }.buttonStyle(.plain)
                }
                if !tasks.isEmpty {
                    if size == .medium {
                        Text("\(tasks.count) tâche\(tasks.count > 1 ? "s" : "") à venir")
                            .font(.system(size: 10)).foregroundStyle(WidgetStyle.secondary)
                    } else {
                        Rectangle().fill(.white.opacity(0.12)).frame(height: 1)
                        if size == .wide {
                            Text("Tâches").font(.system(size: 13, weight: .medium)).foregroundStyle(WidgetStyle.secondary)
                        }
                        Link(destination: URL(string: "https://tasks.google.com")!) {
                            HStack(spacing: 10) {
                                Image(systemName: "circle").font(.system(size: size == .large ? 19 : 22)).foregroundStyle(.white.opacity(0.75))
                                Text(tasks[0].title).font(.system(size: size == .large ? 12 : 14)).lineLimit(1)
                                Spacer(minLength: 0)
                                if Calendar.current.isDateInToday(selectedDate) {
                                    Text("Aujourd’hui").font(.system(size: 11)).foregroundStyle(WidgetStyle.secondary)
                                }
                            }
                        }.buttonStyle(.plain)
                    }
                }
                if error != nil {
                    WidgetNotice(message: error, updatedAt: snapshot?.updatedAt)
                } else {
                    WidgetNotice(updatedAt: snapshot?.updatedAt)
                }
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func eventRow(_ event: CalendarEvent) -> some View {
        if size == .large {
            HStack(spacing: 10) {
                Circle().fill(WidgetStyle.eventColor(event.color)).frame(width: 8, height: 8)
                Text(event.isAllDay ? "Journée" :
                        "\(event.start.formatted(date: .omitted, time: .shortened)) – \(event.end.formatted(date: .omitted, time: .shortened))")
                    .foregroundStyle(WidgetStyle.secondary).frame(width: 94, alignment: .leading)
                Rectangle().fill(.white.opacity(0.12)).frame(width: 1, height: 16)
                Text(event.title).lineLimit(1)
                Spacer(minLength: 0)
            }
            .font(.system(size: 12)).frame(height: 20).contentShape(Rectangle())
        } else {
            verticalEventRow(event)
        }
    }

    private func verticalEventRow(_ event: CalendarEvent) -> some View {
        HStack(spacing: size.compact ? 8 : 12) {
            RoundedRectangle(cornerRadius: 2).fill(WidgetStyle.eventColor(event.color)).frame(width: 3)
            VStack(alignment: .leading, spacing: 2) {
                if event.isAllDay {
                    Text("Toute la journée").foregroundStyle(WidgetStyle.secondary)
                } else {
                    Text(size.compact ? event.start.formatted(date: .omitted, time: .shortened) :
                            "\(event.start.formatted(date: .omitted, time: .shortened)) – \(event.end.formatted(date: .omitted, time: .shortened))")
                        .foregroundStyle(WidgetStyle.secondary)
                }
                Text(event.title).fontWeight(.semibold).lineLimit(1)
            }
            .font(.system(size: size.compact ? 11 : 14))
            Spacer(minLength: 0)
        }
        .frame(height: size.compact ? 33 : 38)
        .contentShape(Rectangle())
    }
}
