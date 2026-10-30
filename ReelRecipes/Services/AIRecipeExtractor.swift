import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

struct ExtractedRecipe: Equatable {
    var title: String
    var ingredients: [String]
    var steps: [String]
    var cuisine: String
    var country: String
    var tags: [String]
}

/// Uses Apple's on-device language model (Apple Intelligence, iOS 26+) to read messy captions
/// that the rule-based parser struggles with. Returns nil when the model isn't available, so the
/// app falls back to `RecipeParser` on older devices.
enum AIRecipeExtractor {
    static var isAvailable: Bool {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            if case .available = SystemLanguageModel.default.availability { return true }
        }
        #endif
        return false
    }

    static func extract(from caption: String) async -> ExtractedRecipe? {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *), isAvailable {
            return await extractWithFoundationModels(caption)
        }
        #endif
        return nil
    }

    #if canImport(FoundationModels)
    @available(iOS 26.0, *)
    private static func extractWithFoundationModels(_ caption: String) async -> ExtractedRecipe? {
        let session = LanguageModelSession(instructions: """
            You extract cooking recipes from Instagram captions. Only use information present in the caption. \
            Keep ingredient quantities exactly as written. Translate nothing; keep the caption's language. \
            Ignore calls to follow, like, save or comment, and ignore hashtags except as hints for cuisine and tags.
            """)
        do {
            let response = try await session.respond(
                to: "Extract the recipe from this caption:\n\n\(caption)",
                generating: GeneratedRecipe.self
            )
            let r = response.content
            return ExtractedRecipe(
                title: r.title.trimmed,
                ingredients: r.ingredients.map(\.trimmed).filter { !$0.isEmpty },
                steps: r.steps.map(\.trimmed).filter { !$0.isEmpty },
                cuisine: r.cuisine.trimmed,
                country: r.country.trimmed,
                tags: r.tags.map { $0.trimmed.lowercased() }.filter { !$0.isEmpty }
            )
        } catch {
            return nil
        }
    }
    #endif
}

#if canImport(FoundationModels)
@available(iOS 26.0, *)
@Generable
struct GeneratedRecipe {
    @Guide(description: "Short dish name, for example 'Creamy Garlic Tuscan Chicken'")
    var title: String

    @Guide(description: "Each ingredient with its quantity, one ingredient per item")
    var ingredients: [String]

    @Guide(description: "Cooking steps in order, one step per item")
    var steps: [String]

    @Guide(description: "Cuisine type such as Italian, Turkish, Japanese or Mexican. Empty string if unclear")
    var cuisine: String

    @Guide(description: "Country the dish comes from, such as Italy or Türkiye. Empty string if unclear")
    var country: String

    @Guide(description: "Up to 5 short lowercase tags like dessert, vegan, breakfast, quick, chicken")
    var tags: [String]
}
#endif
