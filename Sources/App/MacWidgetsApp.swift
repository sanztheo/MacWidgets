import SwiftUI

// Select the property-wrapper type explicitly: SDK 27 also exports a State macro
// whose plugin is not shipped with the standalone Command Line Tools.
typealias ViewState<Value> = SwiftUI.State<Value>

@main
struct MacWidgetsApp: App {
    @ViewState private var model = AppModel()

    var body: some Scene {
        WindowGroup("MacWidgets") {
            MainView(model: model)
                .frame(minWidth: 800, minHeight: 650)
                .preferredColorScheme(.dark)
        }
        .defaultSize(width: 1040, height: 760)
    }
}
