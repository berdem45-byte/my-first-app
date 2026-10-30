import Foundation

struct Cuisine: Identifiable, Hashable {
    let name: String
    let country: String
    let flag: String
    /// Dishes, ingredients and words that point at this cuisine (matched accent-insensitively).
    let keywords: [String]
    var id: String { name }
}

enum CuisineCatalog {
    static let all: [Cuisine] = [
        Cuisine(name: "Turkish", country: "Türkiye", flag: "🇹🇷", keywords: [
            "turkish", "turkey food", "turkiye", "türkiye", "kofte", "köfte", "manti", "mantı", "lahmacun", "borek", "börek",
            "menemen", "baklava", "pide", "dolma", "sarma", "cilbir", "çılbır", "sucuk", "kisir", "kısır", "iskender",
            "kebap", "adana", "ayran", "simit", "gozleme", "gözleme", "mercimek", "imam bayildi", "karniyarik",
            "hunkar begendi", "pilav", "kunefe", "künefe", "sutlac", "sütlaç", "biber salcasi", "pul biber", "tarif", "tarifi",
        ]),
        Cuisine(name: "Italian", country: "Italy", flag: "🇮🇹", keywords: [
            "italian", "italy", "italia", "pasta", "spaghetti", "carbonara", "lasagna", "lasagne", "risotto", "pizza",
            "gnocchi", "pesto", "parmigiano", "parmesan", "mozzarella", "burrata", "tiramisu", "bruschetta", "focaccia",
            "penne", "rigatoni", "tagliatelle", "fettuccine", "linguine", "arrabbiata", "bolognese", "cacio e pepe",
            "ricotta", "prosciutto", "panna cotta", "limoncello", "orzo", "ossobuco", "minestrone",
        ]),
        Cuisine(name: "Mexican", country: "Mexico", flag: "🇲🇽", keywords: [
            "mexican", "mexico", "taco", "tacos", "burrito", "quesadilla", "enchilada", "enchiladas", "guacamole",
            "salsa verde", "tortilla", "tortillas", "chipotle", "jalapeno", "jalapeño", "pozole", "birria", "elote",
            "nachos", "fajitas", "chilaquiles", "tamales", "carnitas", "al pastor", "mole",
        ]),
        Cuisine(name: "Japanese", country: "Japan", flag: "🇯🇵", keywords: [
            "japanese", "japan", "sushi", "ramen", "miso", "teriyaki", "tempura", "udon", "soba", "katsu", "onigiri",
            "matcha", "mirin", "dashi", "yakitori", "gyoza", "okonomiyaki", "donburi", "karaage", "tamagoyaki", "furikake",
        ]),
        Cuisine(name: "Chinese", country: "China", flag: "🇨🇳", keywords: [
            "chinese", "china", "dumpling", "dumplings", "dim sum", "wonton", "chow mein", "lo mein", "kung pao",
            "szechuan", "sichuan", "mapo tofu", "hoisin", "char siu", "bao", "fried rice", "five spice", "bok choy",
            "dan dan", "xiao long bao", "shaoxing", "chili oil",
        ]),
        Cuisine(name: "Korean", country: "South Korea", flag: "🇰🇷", keywords: [
            "korean", "korea", "kimchi", "gochujang", "gochugaru", "bibimbap", "bulgogi", "tteokbokki", "japchae",
            "kimbap", "gimbap", "galbi", "korean fried chicken", "doenjang", "sundubu",
        ]),
        Cuisine(name: "Thai", country: "Thailand", flag: "🇹🇭", keywords: [
            "thai", "thailand", "pad thai", "tom yum", "tom kha", "green curry", "red curry", "massaman", "fish sauce",
            "lemongrass", "galangal", "pad see ew", "larb", "som tam", "khao soi", "thai basil",
        ]),
        Cuisine(name: "Indian", country: "India", flag: "🇮🇳", keywords: [
            "indian", "india", "curry", "masala", "garam masala", "tikka", "biryani", "dal", "daal", "paneer", "naan",
            "chapati", "roti", "samosa", "tandoori", "korma", "vindaloo", "chana", "turmeric", "ghee", "pakora", "dosa",
            "butter chicken", "raita", "chutney",
        ]),
        Cuisine(name: "Greek", country: "Greece", flag: "🇬🇷", keywords: [
            "greek", "greece", "feta", "tzatziki", "souvlaki", "gyro", "gyros", "moussaka", "spanakopita", "halloumi",
            "kalamata", "orzo salad", "horiatiki", "pastitsio",
        ]),
        Cuisine(name: "French", country: "France", flag: "🇫🇷", keywords: [
            "french", "france", "croissant", "crepe", "crêpe", "ratatouille", "quiche", "bechamel", "béchamel",
            "baguette", "creme brulee", "crème brûlée", "souffle", "soufflé", "coq au vin", "bouillabaisse", "gratin",
            "dijon", "beurre", "madeleine", "macaron", "eclair",
        ]),
        Cuisine(name: "Spanish", country: "Spain", flag: "🇪🇸", keywords: [
            "spanish", "spain", "paella", "tapas", "chorizo", "gazpacho", "tortilla espanola", "patatas bravas",
            "churros", "jamon", "manchego", "romesco", "gambas", "basque cheesecake",
        ]),
        Cuisine(name: "Middle Eastern", country: "Lebanon", flag: "🇱🇧", keywords: [
            "lebanese", "middle eastern", "hummus", "falafel", "tahini", "shawarma", "tabbouleh", "fattoush",
            "baba ganoush", "za'atar", "zaatar", "sumac", "labneh", "manakish", "pita", "shakshuka", "kibbeh",
        ]),
        Cuisine(name: "Moroccan", country: "Morocco", flag: "🇲🇦", keywords: [
            "moroccan", "morocco", "tagine", "couscous", "harissa", "ras el hanout", "preserved lemon", "chermoula",
        ]),
        Cuisine(name: "Vietnamese", country: "Vietnam", flag: "🇻🇳", keywords: [
            "vietnamese", "vietnam", "pho", "banh mi", "spring rolls", "rice paper", "bun cha", "nuoc cham", "vermicelli",
        ]),
        Cuisine(name: "American", country: "United States", flag: "🇺🇸", keywords: [
            "american", "burger", "cheeseburger", "bbq", "barbecue", "mac and cheese", "pancakes", "brownies",
            "buffalo", "cornbread", "hot dog", "sloppy joe", "cookies", "pulled pork", "chocolate chip",
        ]),
        Cuisine(name: "British", country: "United Kingdom", flag: "🇬🇧", keywords: [
            "british", "english", "scones", "shepherd's pie", "cottage pie", "fish and chips", "yorkshire pudding",
            "sunday roast", "crumble", "sticky toffee",
        ]),
        Cuisine(name: "Brazilian", country: "Brazil", flag: "🇧🇷", keywords: [
            "brazilian", "brazil", "brigadeiro", "feijoada", "pao de queijo", "coxinha", "acai", "açaí", "farofa",
        ]),
        Cuisine(name: "Peruvian", country: "Peru", flag: "🇵🇪", keywords: [
            "peruvian", "peru", "ceviche", "lomo saltado", "aji amarillo", "causa", "anticuchos",
        ]),
    ]

    static func cuisine(named name: String) -> Cuisine? {
        let n = name.normalizedForMatching
        return all.first { $0.name.normalizedForMatching == n }
    }

    static func flag(forCountry country: String) -> String? {
        let n = country.normalizedForMatching
        if let match = all.first(where: { $0.country.normalizedForMatching == n }) { return match.flag }
        return extraFlags[n]
    }

    private static let extraFlags: [String: String] = [
        "turkey": "🇹🇷", "usa": "🇺🇸", "us": "🇺🇸", "uk": "🇬🇧", "england": "🇬🇧", "korea": "🇰🇷", "germany": "🇩🇪",
        "portugal": "🇵🇹", "syria": "🇸🇾", "iran": "🇮🇷", "egypt": "🇪🇬", "israel": "🇮🇱", "indonesia": "🇮🇩",
        "philippines": "🇵🇭", "malaysia": "🇲🇾", "ethiopia": "🇪🇹", "argentina": "🇦🇷", "colombia": "🇨🇴",
        "jamaica": "🇯🇲", "poland": "🇵🇱", "russia": "🇷🇺", "ukraine": "🇺🇦", "georgia": "🇬🇪", "azerbaijan": "🇦🇿",
    ]
}

struct RecipeTags: Equatable {
    var cuisine: String?
    var country: String?
    var tags: [String]
}

/// Infers cuisine, country and descriptive tags (meal type, diet, protein, …) from a recipe's text.
enum RecipeTagger {
    static let categoryKeywords: [(tag: String, keywords: [String])] = [
        ("breakfast", ["breakfast", "brunch", "pancake", "pancakes", "omelette", "omelet", "granola", "oatmeal",
                       "overnight oats", "french toast", "menemen", "kahvalti", "waffles", "eggs benedict"]),
        ("dessert", ["dessert", "cake", "cookie", "cookies", "brownie", "brownies", "cheesecake", "tiramisu", "baklava",
                     "ice cream", "pudding", "mousse", "tart", "sutlac", "tatli", "cupcake", "donut", "doughnut",
                     "brigadeiro", "churros", "panna cotta", "kunefe"]),
        ("soup", ["soup", "stew", "broth", "ramen", "pho", "corba", "chowder", "bisque", "minestrone"]),
        ("salad", ["salad", "salata", "slaw", "tabbouleh", "fattoush", "kisir"]),
        ("pasta", ["pasta", "spaghetti", "penne", "rigatoni", "linguine", "fettuccine", "tagliatelle", "lasagna",
                   "lasagne", "macaroni", "orzo", "gnocchi", "manti", "makarna"]),
        ("baking", ["bread", "focaccia", "sourdough", "dough", "pastry", "croissant", "borek", "pide", "buns", "muffin",
                    "muffins", "scones", "loaf"]),
        ("snack", ["snack", "appetizer", "dip", "finger food", "bites", "starter", "meze", "mezze", "tapas"]),
        ("drink", ["drink", "cocktail", "mocktail", "smoothie", "latte", "lemonade", "juice", "milkshake", "ayran"]),
        ("chicken", ["chicken", "tavuk"]),
        ("beef", ["beef", "steak", "ground beef", "minced beef", "kiyma", "dana"]),
        ("lamb", ["lamb", "kuzu"]),
        ("pork", ["pork", "bacon", "ham", "pancetta", "chorizo"]),
        ("seafood", ["fish", "salmon", "tuna", "shrimp", "prawn", "prawns", "seafood", "cod", "mussels", "squid",
                     "calamari", "crab", "lobster", "balik", "karides"]),
        ("vegan", ["vegan", "plant based", "plantbased", "dairy free"]),
        ("vegetarian", ["vegetarian", "veggie", "meatless"]),
        ("gluten-free", ["gluten free", "glutenfree", "gf"]),
        ("high-protein", ["high protein", "highprotein", "protein"]),
        ("healthy", ["healthy", "low calorie", "low cal", "lowcarb", "low carb", "keto", "clean eating", "mealprep",
                     "meal prep"]),
        ("air fryer", ["air fryer", "airfryer", "air fried", "air fry"]),
        ("one-pot", ["one pot", "onepot", "one pan", "one-pan", "sheet pan", "traybake"]),
        ("quick", ["quick", "15 minute", "15 min", "10 minute", "10 min", "20 minute", "20 min", "5 minute",
                   "5 min", "easy dinner", "weeknight"]),
        ("spicy", ["spicy", "chili", "chilli", "hot sauce", "jalapeno", "gochujang", "harissa", "sriracha"]),
    ]

    static func tag(caption: String, title: String = "", ingredients: [String] = [], totalMinutes: Int? = nil) -> RecipeTags {
        let hashtags = RecipeParser.extractHashtags(from: caption).map(\.normalizedForMatching)
        let text = ([title, caption] + ingredients).joined(separator: "\n").normalizedForMatching
        let words = Set(text.split { !$0.isLetter && !$0.isNumber && $0 != "'" }.map(String.init))

        func hits(_ keyword: String) -> Bool {
            let k = keyword.normalizedForMatching
            if k.contains(" ") || k.contains("'") || k.contains("-") {
                return text.contains(k) || hashtags.contains(k.replacingOccurrences(of: " ", with: ""))
            }
            if words.contains(k) { return true }
            // Hashtags glue words together (#italianfood, #pastarecipe), so look inside them.
            return k.count >= 4 && hashtags.contains { $0.contains(k) }
        }

        // Cuisine: highest keyword score wins; naming the cuisine itself counts triple.
        var best: (cuisine: Cuisine, score: Int)?
        for cuisine in CuisineCatalog.all {
            var score = 0
            for (index, keyword) in cuisine.keywords.enumerated() where hits(keyword) {
                score += index < 2 ? 3 : 1
            }
            if score > (best?.score ?? 0) { best = (cuisine, score) }
        }

        var tags = categoryKeywords.filter { entry in entry.keywords.contains(where: hits) }.map(\.tag)
        if let minutes = totalMinutes, minutes <= 20, !tags.contains("quick") {
            tags.append("quick")
        }
        if tags.contains("vegan") { tags.removeAll { $0 == "vegetarian" } }

        return RecipeTags(cuisine: best?.cuisine.name, country: best?.cuisine.country, tags: tags)
    }
}
