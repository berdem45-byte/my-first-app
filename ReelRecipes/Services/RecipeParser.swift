import Foundation

struct ParsedRecipe: Equatable {
    var title: String
    var ingredients: [String]
    var steps: [String]
    var hashtags: [String]
    var servings: Int?
    var totalMinutes: Int?
}

/// Rule-based extraction of a recipe from a free-form Instagram caption.
///
/// Captions usually look like:
///
///     Creamy Tuscan pasta 🍝
///     Ingredients:
///     - 200g pasta
///     - 2 cloves garlic
///     Method:
///     1. Boil the pasta...
///     #pasta #italianfood
///
/// When there are no section headers, lines are classified by shape (quantities → ingredients,
/// numbered lines / cooking verbs → steps).
enum RecipeParser {
    private enum Section { case intro, ingredients, steps }

    static let ingredientHeaders = [
        "ingredients", "ingredient", "ingredient list", "you will need", "you'll need", "youll need", "what you need",
        "shopping list", "malzemeler", "malzeme listesi", "ingredientes", "ingrédients", "ingredients list",
        "zutaten", "ingredienti",
    ]

    static let stepHeaders = [
        "instructions", "instruction", "method", "directions", "steps", "preparation", "how to make it",
        "recipe steps", "yapilisi", "hazirlanisi", "tarifi", "preparacion",
        "elaboracion", "zubereitung", "procedimento", "procedure",
    ]

    private static let noisePhrases = [
        "follow ", "follow@", "follow for", "save this", "save for later", "save it", "link in bio",
        "tag a friend", "tag someone", "share with", "turn on notifications", "like and", "comment below",
        "comment \"", "dm me", "full recipe", "recipe below", "recipe 👇", "send this to",
    ]

    private static let cookingVerbs: Set<String> = [
        "add", "bake", "beat", "blend", "boil", "bring", "chop", "combine", "cook", "cover", "cut", "dice",
        "drain", "drizzle", "mash", "fold", "fry", "garnish", "grate", "grill", "heat", "knead", "let", "marinate",
        "melt", "mix", "place", "pour", "preheat", "put", "reduce", "remove", "rest", "roast", "roll",
        "saute", "sauté", "season", "serve", "simmer", "slice", "spread", "sprinkle", "stir", "strain",
        "top", "toss", "transfer", "whisk", "wrap", "air", "refrigerate", "chill", "finish", "start", "then",
    ]

    private static let quantityPattern =
        #"^[\d½¼¾⅓⅔⅛]|(\d|½|¼|¾)\s*(g|gr|kg|ml|l|oz|lb|lbs|cups?|tbsp|tbs|tsp|tablespoons?|teaspoons?|grams?|pinch|cloves?|slices?|cans?|handful|su bardagi|yemek kasigi|tatli kasigi)\b|\b(a pinch|to taste|as needed)\b"#

    static func parse(_ caption: String) -> ParsedRecipe {
        let hashtags = extractHashtags(from: caption)
        let lines = caption
            .replacingOccurrences(of: "\r\n", with: "\n")
            .components(separatedBy: .newlines)
            .map(\.trimmed)

        var section = Section.intro
        var intro: [String] = []
        var ingredients: [String] = []
        var steps: [String] = []

        for line in lines where !line.isEmpty {
            if let (header, remainder) = detectHeader(line) {
                section = header
                if let remainder {
                    if header == .ingredients {
                        ingredients += remainder.split(separator: ",").map { clean(String($0)) }.filter { !$0.isEmpty }
                    } else {
                        let cleaned = clean(remainder)
                        if !cleaned.isEmpty { steps.append(cleaned) }
                    }
                }
                continue
            }

            let cleaned = clean(line)
            guard !cleaned.isEmpty, !isNoise(cleaned) else { continue }

            switch section {
            case .intro: intro.append(line)
            case .ingredients: ingredients.append(cleaned)
            case .steps: steps.append(cleaned)
            }
        }

        // Title: first meaningful intro line.
        var title = ""
        var bodyLines = intro
        if let index = intro.firstIndex(where: { !clean($0).isEmpty && !isNoise(clean($0)) }) {
            title = makeTitle(from: intro[index])
            bodyLines.remove(at: index)
        }

        // No headers found: classify the remaining lines by their shape.
        if ingredients.isEmpty && steps.isEmpty {
            for line in bodyLines {
                let cleaned = clean(line)
                guard !cleaned.isEmpty, !isNoise(cleaned) else { continue }
                if looksNumbered(line) || looksLikeInstruction(cleaned) && !looksLikeIngredient(cleaned) {
                    steps.append(cleaned)
                } else if looksLikeIngredient(cleaned) || startsWithBullet(line) {
                    ingredients.append(cleaned)
                }
            }
        }

        return ParsedRecipe(
            title: title,
            ingredients: ingredients,
            steps: steps,
            hashtags: hashtags,
            servings: extractServings(from: caption),
            totalMinutes: extractMinutes(from: caption)
        )
    }

    // MARK: - Pieces

    static func extractHashtags(from text: String) -> [String] {
        var seen = Set<String>()
        return text.allMatches(#"#([\p{L}\p{N}_]+)"#)
            .map { $0.lowercased() }
            .filter { seen.insert($0).inserted }
    }

    /// Returns the section a header line starts, plus any inline content after a colon
    /// (e.g. "Ingredients: pasta, garlic, oil").
    private static func detectHeader(_ line: String) -> (Section, String?)? {
        let stripped = line.strippingLeadingSymbols
        let parts = stripped.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: false)
        let head = String(parts[0])
            .normalizedForMatching
            .filter { $0.isLetter || $0 == " " || $0 == "'" }
            .trimmed
        guard !head.isEmpty, head.count <= 32 else { return nil }

        let remainder = parts.count > 1 ? String(parts[1]).trimmed : nil
        let inline = remainder?.isEmpty == false ? remainder : nil

        func matches(_ keywords: [String]) -> Bool {
            keywords.contains { keyword in
                let k = keyword.normalizedForMatching
                return head == k || head.hasPrefix(k + " ") && (parts.count > 1 || head.count <= k.count + 16)
            }
        }
        if matches(ingredientHeaders) { return (.ingredients, inline) }
        if matches(stepHeaders) { return (.steps, inline) }
        return nil
    }

    /// Removes hashtags, bullets, emoji and list numbering.
    static func clean(_ line: String) -> String {
        line
            .replacingMatches(#"^\d\uFE0F?\u20E3\s*"#, with: "") // 1️⃣ keycap numbering
            .replacingMatches(#"#[\p{L}\p{N}_]+"#, with: "")
            .strippingLeadingSymbols
            .replacingMatches(#"^(step\s*)?\d{1,2}\s*[\.\):-]\s+"#, with: "")
            .replacingMatches(#"^step\s*\d{1,2}\s*"#, with: "")
            .strippingLeadingSymbols
            .replacingMatches(#"\s{2,}"#, with: " ")
            .trimmed
    }

    private static func makeTitle(from line: String) -> String {
        var title = clean(line)
        while let last = title.last, ":.!-–|".contains(last) || (!last.isLetter && !last.isNumber && !last.isWhitespace && last != ")") {
            title.removeLast()
        }
        title = title.trimmed
        if title.count > 80 {
            title = String(title.prefix(80)).trimmed + "…"
        }
        return title
    }

    private static func isNoise(_ line: String) -> Bool {
        let lower = line.lowercased()
        if lower.hasPrefix("@") { return true }
        return noisePhrases.contains { lower.contains($0) }
    }

    private static func looksNumbered(_ line: String) -> Bool {
        line.strippingLeadingSymbols.matches(#"^(step\s*)?\d{1,2}\s*[\.\):]\s+\D"#) || line.lowercased().hasPrefix("step ")
            || line.unicodeScalars.first.map { (0x2460...0x2473).contains($0.value) || (0x1F51F == $0.value) } == true // ①…⑳
            || line.matches(#"^\d️?⃣"#) // 1️⃣
    }

    static func looksLikeIngredient(_ line: String) -> Bool {
        line.normalizedForMatching.matches(quantityPattern)
    }

    private static func looksLikeInstruction(_ line: String) -> Bool {
        guard let first = line.split(separator: " ").first else { return false }
        return cookingVerbs.contains(first.lowercased().trimmingCharacters(in: .punctuationCharacters))
    }

    private static func startsWithBullet(_ line: String) -> Bool {
        guard let first = line.first else { return false }
        return !first.isLetter && !first.isNumber
    }

    static func extractServings(from text: String) -> Int? {
        let patterns = [
            #"(?:serves|servings|portions?|porsiyon|makes)\s*:?\s*(\d{1,2})"#,
            #"(\d{1,2})\s*(?:servings|portions|people|kisilik|kişilik)"#,
        ]
        for pattern in patterns {
            if let value = text.firstMatch(pattern).flatMap(Int.init) { return value }
        }
        return nil
    }

    static func extractMinutes(from text: String) -> Int? {
        let lower = text.lowercased()
        if let total = lower.firstMatch(#"(?:total time|ready in|takes|in just|in only|only)\D{0,12}(\d{1,3})\s*(?:min|mins|minutes|dk|dakika)\b"#) {
            return Int(total)
        }
        if let hours = lower.firstMatch(#"(?:total time|ready in)\D{0,12}(\d{1,2})\s*(?:h|hr|hrs|hours?)\b"#).flatMap(Int.init) {
            return hours * 60
        }
        if let quick = lower.firstMatch(#"\b(\d{1,3})[\s-]*(?:min|minute)s?\s+(?:recipe|meal|dinner|lunch|breakfast|dessert)"#) {
            return Int(quick)
        }
        return nil
    }
}
