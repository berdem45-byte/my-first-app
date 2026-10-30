import Foundation
import SwiftData

/// Turns a saved reel link into a recipe: fetch caption + thumbnail, extract, tag.
@MainActor
enum RecipeImporter {
    private static var isImportingShares = false

    /// Moves reels shared from Instagram (via the Share Extension) into the store and processes
    /// them, along with anything left unfinished from a previous launch.
    static func importSharedReels(into context: ModelContext) async {
        guard !isImportingShares else { return }
        isImportingShares = true
        defer { isImportingShares = false }

        for share in PendingShareQueue.drain() {
            let recipe = Recipe(sourceURL: share.url, rawCaption: share.caption, createdAt: share.sharedAt)
            context.insert(recipe)
        }
        try? context.save()

        let pending = RecipeStatus.pending.rawValue
        let processing = RecipeStatus.processing.rawValue
        let descriptor = FetchDescriptor<Recipe>(predicate: #Predicate<Recipe> { $0.statusRaw == pending || $0.statusRaw == processing })
        for recipe in (try? context.fetch(descriptor)) ?? [] {
            await process(recipe)
        }
        try? context.save()
    }

    /// Fetches what's missing and (re-)extracts the recipe from its caption.
    static func process(_ recipe: Recipe) async {
        recipe.status = .processing

        let needsCaption = recipe.rawCaption.trimmed.isEmpty
        if (needsCaption || recipe.thumbnailData == nil), let url = recipe.url,
           let metadata = try? await InstagramMetadataFetcher.fetch(url) {
            if needsCaption, let caption = metadata.caption { recipe.rawCaption = caption }
            if recipe.authorHandle == nil { recipe.authorHandle = metadata.authorHandle }
            if recipe.thumbnailData == nil, let imageURL = metadata.imageURL {
                recipe.thumbnailData = await InstagramMetadataFetcher.downloadImage(imageURL)
            }
        }

        guard !recipe.rawCaption.trimmed.isEmpty else {
            recipe.status = .needsCaption
            return
        }

        await extract(into: recipe)
        recipe.status = .ready
    }

    private static func extract(into recipe: Recipe) async {
        let caption = recipe.rawCaption
        let parsed = RecipeParser.parse(caption)
        let ai = await AIRecipeExtractor.extract(from: caption)

        let title = ai?.title.nonEmpty ?? parsed.title
        let ingredients = ai?.ingredients.nonEmpty ?? parsed.ingredients
        let steps = ai?.steps.nonEmpty ?? parsed.steps
        let detected = RecipeTagger.tag(caption: caption, title: title, ingredients: ingredients, totalMinutes: parsed.totalMinutes)

        recipe.title = title
        recipe.ingredients = ingredients
        recipe.steps = steps
        recipe.servings = parsed.servings
        recipe.totalMinutes = parsed.totalMinutes
        recipe.cuisine = detected.cuisine ?? ai?.cuisine.nonEmpty
        recipe.country = detected.country ?? ai?.country.nonEmpty

        var tags = detected.tags
        for tag in ai?.tags ?? [] where !tags.contains(tag) && tag.count <= 20 { tags.append(tag) }
        recipe.tags = tags
    }
}

private extension String {
    var nonEmpty: String? { trimmed.isEmpty ? nil : self }
}

private extension Array {
    var nonEmpty: Self? { isEmpty ? nil : self }
}
