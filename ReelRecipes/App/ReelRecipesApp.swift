import SwiftData
import SwiftUI

@main
struct ReelRecipesApp: App {
    @Environment(\.scenePhase) private var scenePhase

    private let container: ModelContainer = {
        do {
            return try ModelContainer(for: Recipe.self)
        } catch {
            fatalError("Could not open the recipe store: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RecipeListView()
        }
        .modelContainer(container)
        .onChange(of: scenePhase, initial: true) { _, phase in
            guard phase == .active else { return }
            Task { await RecipeImporter.importSharedReels(into: container.mainContext) }
        }
    }
}
