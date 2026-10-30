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
        // Re-fetch until empty so reels added while this runs (e.g. an export import) get picked up.
        while true {
            let queue = (try? context.fetch(descriptor)) ?? []
            if queue.isEmpty { break }
            for (index, recipe) in queue.enumerated() {
                await process(recipe)
                if index % 10 == 9 { try? context.save() }
                // Be gentle with Instagram when working through a large export.
                if queue.count > 3 { try? await Task.sleep(nanoseconds: 1_000_000_000) }
            }
            try? context.save()
        }
    }

    /// Adds every reel link found in an Instagram export that isn't saved yet.
    /// Returns (links found, links added).
    @discardableResult
    static func addExportedReels(_ urls: [URL], into context: ModelContext) -> (found: Int, added: Int) {
        let existing = Set(((try? context.fetch(FetchDescriptor<Recipe>())) ?? []).map(\.sourceURL))
        let new = urls.filter { !existing.contains($0.absoluteString) }
        // Keep the export's order (newest saves first) when sorting by date.
        let now = Date.now
        for (index, url) in new.enumerated() {
            let recipe = Recipe(sourceURL: url.absoluteString, createdAt: now.addingTimeInterval(-Double(index)))
            recipe.importedFromExport = true
            context.insert(recipe)
        }
        try? context.save()
        return (urls.count, new.count)
    }

    /// Puts reels whose caption couldn't be fetched back in the queue.
    static func retryMissingCaptions(in context: ModelContext) async {
        let needsCaption = RecipeStatus.needsCaption.rawValue
        let descriptor = FetchDescriptor<Recipe>(predicate: #Predicate<Recipe> { $0.statusRaw == needsCaption })
        for recipe in (try? context.fetch(descriptor)) ?? [] {
            recipe.status = .pending
        }
        await importSharedReels(into: context)
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

        let isRecipe = recipe.isRecipeOverride
            ?? (recipe.importedFromExport ? RecipeClassifier.isLikelyRecipe(recipe.rawCaption) : true)
        guard isRecipe else {
            // Not worth running the full extraction; just give it a readable title.
            recipe.title = RecipeParser.parse(recipe.rawCaption).title
            recipe.status = .notRecipe
            return
        }

        await extract(into: recipe)
        recipe.status = .ready
    }

    static func setIsRecipe(_ isRecipe: Bool, for recipe: Recipe) async {
        recipe.isRecipeOverride = isRecipe
        if isRecipe {
            await process(recipe)
        } else {
            recipe.status = .notRecipe
        }
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
