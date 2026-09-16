import Foundation

enum SharedStore {
    static var groupID: String {
        Bundle.main.object(forInfoDictionaryKey: "SharedAppGroup") as? String ?? ""
    }

    static func directory() throws -> URL {
        guard !groupID.isEmpty, !groupID.contains("$("),
              let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupID) else {
            throw WidgetFailure.message("Le conteneur partagé est indisponible. Vérifiez la signature de l’app.")
        }
        let directory = container.appendingPathComponent("Snapshots", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    static func read<Value: Decodable>(_ name: String, as type: Value.Type) -> Value? {
        guard let directory = try? directory(),
              let data = try? Data(contentsOf: directory.appendingPathComponent(name)) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    static func write<Value: Encodable>(_ value: Value, to name: String) throws {
        let url = try directory().appendingPathComponent(name)
        try JSONEncoder().encode(value).write(to: url, options: .atomic)
        try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: url.path)
    }

    static func remove(prefix: String) throws {
        let directory = try directory()
        for url in try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
        where url.lastPathComponent.hasPrefix(prefix) {
            try FileManager.default.removeItem(at: url)
        }
    }

    static var selectedDate: Date {
        read("selection.json", as: CalendarSelection.self)?.effectiveDate() ?? .now
    }

    static func calendarFile(for date: Date) -> String {
        let zone = TimeZone.current.identifier.replacingOccurrences(of: "/", with: "_")
        return "calendar-\(CalendarDates.monthKey(date))-\(zone).json"
    }
}
