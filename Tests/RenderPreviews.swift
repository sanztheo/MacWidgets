import AppKit
import SwiftUI

@main
struct RenderPreviews {
    @MainActor static func main() throws {
        _ = NSApplication.shared
        let output = URL(fileURLWithPath: ".build/previews", isDirectory: true)
        try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
        for size in WidgetSize.allCases {
            let view = CalendarView(snapshot: PreviewData.calendar, selectedDate: PreviewData.date,
                                    size: size, selectDate: { _ in })
                .frame(width: size.dimensions.width, height: size.dimensions.height)
                .background(WidgetStyle.background, in: RoundedRectangle(cornerRadius: 24))
                .overlay(RoundedRectangle(cornerRadius: 24).stroke(.white.opacity(0.14), lineWidth: 0.5))
                .padding(24)
                .background(Color(red: 0.05, green: 0.13, blue: 0.25))
                .environment(\.locale, Locale(identifier: "fr_FR"))
                .environment(\.colorScheme, .dark)
            let renderer = ImageRenderer(content: view)
            renderer.scale = 3
            guard let cgImage = renderer.cgImage else { throw WidgetFailure.message("Rendu impossible") }
            let bitmap = NSBitmapImageRep(cgImage: cgImage)
            guard let data = bitmap.representation(using: .png, properties: [:]) else {
                throw WidgetFailure.message("PNG impossible")
            }
            try data.write(to: output.appendingPathComponent("calendar-\(size).png"))
        }
        print("Native SwiftUI previews rendered to .build/previews")
    }
}
