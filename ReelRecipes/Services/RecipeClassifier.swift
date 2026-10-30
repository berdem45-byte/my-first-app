import Foundation

/// Decides whether a saved reel is a food recipe, from its caption alone.
///
/// Used for reels bulk-imported from an Instagram export, which mix recipes with everything
/// else people save. Reels shared one by one are always treated as recipes.
enum RecipeClassifier {
    /// Words that strongly suggest the caption is (or points to) a recipe, in several languages.
    static let strongWords = [
        "recipe", "recipes", "ingredients", "tarif", "tarifi", "malzemeler", "receta", "ingredientes", "recette",
        "ricetta", "rezept", "zutaten", "how to make", "homemade", "ev yapimi",
    ]

    /// Weaker food signals: each adds a little.
    static let foodWords = [
        "cook", "cooking", "bake", "baking", "food", "foodie", "dinner", "lunch", "breakfast", "dessert", "yummy",
        "delicious", "tasty", "kitchen", "chef", "meal", "mealprep", "lezzetli", "yemek", "mutfak", "oven", "airfryer",
    ]

    static let threshold = 3

    static func score(_ caption: String) -> Int {
        let parsed = RecipeParser.parse(caption)
        let text = caption.normalizedForMatching
        let words = Set(text.split { !$0.isLetter && !$0.isNumber }.map(String.init))
        let hashtags = parsed.hashtags.map(\.normalizedForMatching)

        func mentions(_ word: String) -> Bool {
            word.contains(" ") ? text.contains(word) : words.contains(word) || hashtags.contains { $0.contains(word) }
        }

        var score = 0
        if parsed.ingredients.count >= 2 { score += 3 }
        if parsed.steps.count >= 2 { score += 2 }

        let quantityLines = caption.components(separatedBy: .newlines)
            .map(RecipeParser.clean)
            .filter(RecipeParser.looksLikeIngredient)
            .count
        if quantityLines >= 3 { score += 2 }

        if strongWords.contains(where: mentions) { score += 2 }
        score += min(2, foodWords.filter(mentions).count)

        let tags = RecipeTagger.tag(caption: caption)
        if tags.cuisine != nil || !tags.tags.isEmpty { score += 1 }

        return score
    }

    static func isLikelyRecipe(_ caption: String) -> Bool {
        score(caption) >= threshold
    }
}
