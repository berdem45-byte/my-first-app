import XCTest
@testable import ReelRecipes

final class RecipeParserTests: XCTestCase {
    func testParsesHeadedCaption() {
        let caption = """
        Creamy Tuscan Garlic Pasta 🍝✨
        Ready in 20 minutes and so good!

        Ingredients:
        - 200g penne
        - 2 cloves garlic, minced
        • 1 cup heavy cream
        🧀 50g parmesan
        Handful of spinach

        Method:
        1. Boil the pasta in salted water.
        2. Sauté garlic in olive oil, then add the cream.
        3) Stir in parmesan and spinach, toss with the pasta.

        Follow @chef for more recipes!
        #pasta #italianfood #easyrecipes
        """
        let parsed = RecipeParser.parse(caption)

        XCTAssertEqual(parsed.title, "Creamy Tuscan Garlic Pasta")
        XCTAssertEqual(parsed.ingredients, [
            "200g penne", "2 cloves garlic, minced", "1 cup heavy cream", "50g parmesan", "Handful of spinach",
        ])
        XCTAssertEqual(parsed.steps, [
            "Boil the pasta in salted water.",
            "Sauté garlic in olive oil, then add the cream.",
            "Stir in parmesan and spinach, toss with the pasta.",
        ])
        XCTAssertEqual(parsed.hashtags, ["pasta", "italianfood", "easyrecipes"])
        XCTAssertEqual(parsed.totalMinutes, 20)
    }

    func testInlineIngredientsAfterHeader() {
        let parsed = RecipeParser.parse("Quick salad\nIngredients: cucumber, tomato, feta, olive oil\nInstructions: Chop and mix everything.")
        XCTAssertEqual(parsed.ingredients, ["cucumber", "tomato", "feta", "olive oil"])
        XCTAssertEqual(parsed.steps, ["Chop and mix everything."])
    }

    func testTurkishHeaders() {
        let caption = """
        Fırında Köfte
        Malzemeler:
        500 gr kıyma
        1 adet soğan
        Yapılışı:
        Tüm malzemeleri yoğurun.
        Fırında 200 derecede pişirin.
        """
        let parsed = RecipeParser.parse(caption)
        XCTAssertEqual(parsed.title, "Fırında Köfte")
        XCTAssertEqual(parsed.ingredients, ["500 gr kıyma", "1 adet soğan"])
        XCTAssertEqual(parsed.steps.count, 2)
    }

    func testFallsBackToLineShapesWithoutHeaders() {
        let caption = """
        Best banana bread ever
        3 ripe bananas
        2 cups flour
        1 tsp baking soda
        Mash the bananas and mix with the rest.
        Bake at 180C for 50 minutes.
        """
        let parsed = RecipeParser.parse(caption)
        XCTAssertEqual(parsed.title, "Best banana bread ever")
        XCTAssertEqual(parsed.ingredients, ["3 ripe bananas", "2 cups flour", "1 tsp baking soda"])
        XCTAssertEqual(parsed.steps, ["Mash the bananas and mix with the rest.", "Bake at 180C for 50 minutes."])
    }

    func testTitleThatStartsWithHowToIsNotAHeader() {
        let parsed = RecipeParser.parse("How to make pasta\nIngredients:\n100g spaghetti")
        XCTAssertEqual(parsed.title, "How to make pasta")
        XCTAssertEqual(parsed.ingredients, ["100g spaghetti"])
    }

    func testServings() {
        XCTAssertEqual(RecipeParser.extractServings(from: "Serves 4 people"), 4)
        XCTAssertEqual(RecipeParser.extractServings(from: "Makes 6 servings"), 6)
        XCTAssertNil(RecipeParser.extractServings(from: "So tasty"))
    }
}

final class RecipeTaggerTests: XCTestCase {
    func testDetectsItalianFromHashtagsAndDishes() {
        let tags = RecipeTagger.tag(caption: "Creamy carbonara with parmesan #pastarecipe #italianfood")
        XCTAssertEqual(tags.cuisine, "Italian")
        XCTAssertEqual(tags.country, "Italy")
        XCTAssertTrue(tags.tags.contains("pasta"))
    }

    func testDetectsTurkishWithAccents() {
        let tags = RecipeTagger.tag(caption: "Annemin mantı tarifi 🥟 yoğurt ve pul biber ile")
        XCTAssertEqual(tags.cuisine, "Turkish")
        XCTAssertEqual(tags.country, "Türkiye")
    }

    func testDetectsKoreanAndSpicy() {
        let tags = RecipeTagger.tag(caption: "Tteokbokki with gochujang sauce, so spicy! #koreanfood")
        XCTAssertEqual(tags.cuisine, "Korean")
        XCTAssertTrue(tags.tags.contains("spicy"))
    }

    func testCategoryTagsAndQuickFromMinutes() {
        let tags = RecipeTagger.tag(caption: "Vegan chocolate cake", totalMinutes: 15)
        XCTAssertTrue(tags.tags.contains("dessert"))
        XCTAssertTrue(tags.tags.contains("vegan"))
        XCTAssertFalse(tags.tags.contains("vegetarian"))
        XCTAssertTrue(tags.tags.contains("quick"))
    }

    func testUnknownCuisineIsNil() {
        XCTAssertNil(RecipeTagger.tag(caption: "My favourite toast").cuisine)
    }
}

final class InstagramTests: XCTestCase {
    func testShortcodeAndCanonicalURL() {
        let link = "https://www.instagram.com/reel/C9xYz12AbCd/?igsh=MWQ1ZGUxMzBkMA=="
        XCTAssertEqual(InstagramLink.shortcode(in: link), "C9xYz12AbCd")
        XCTAssertEqual(InstagramLink.canonicalURL(from: link)?.absoluteString, "https://www.instagram.com/reel/C9xYz12AbCd/")
        XCTAssertEqual(InstagramLink.shortcode(in: "https://instagram.com/chef.anna/p/ABC_123/"), "ABC_123")
        XCTAssertNil(InstagramLink.shortcode(in: "https://example.com/reel/abc"))
    }

    func testParsesOpenGraphCaption() {
        let html = """
        <html><head>
        <meta property="og:image" content="https://cdn.example.com/thumb.jpg?a=1&amp;b=2" />
        <meta property="og:description" content="1,234 likes, 56 comments - chef.anna on March 1, 2025: &quot;Lemon pasta &#x1f34b;&#10;Ingredients:&#10;200g spaghetti&quot;. " />
        </head></html>
        """
        let metadata = InstagramMetadataFetcher.parse(html: html)
        XCTAssertEqual(metadata.caption, "Lemon pasta 🍋\nIngredients:\n200g spaghetti")
        XCTAssertEqual(metadata.authorHandle, "chef.anna")
        XCTAssertEqual(metadata.imageURL?.absoluteString, "https://cdn.example.com/thumb.jpg?a=1&b=2")
    }

    func testHTMLEntityDecoding() {
        XCTAssertEqual("Tom &amp; Jerry&#39;s &quot;pie&quot; &#x1F967;".decodingHTMLEntities, "Tom & Jerry's \"pie\" 🥧")
        XCTAssertEqual("no entities here".decodingHTMLEntities, "no entities here")
        XCTAssertEqual("AT&T".decodingHTMLEntities, "AT&T")
    }
}

final class RecipeClassifierTests: XCTestCase {
    func testRecipeCaptionsAreRecipes() {
        XCTAssertTrue(RecipeClassifier.isLikelyRecipe("""
        Lemon garlic salmon 🍋
        Ingredients:
        2 salmon fillets
        1 tbsp butter
        2 cloves garlic
        Method:
        1. Season the salmon.
        2. Pan fry 4 minutes each side.
        """))
        XCTAssertTrue(RecipeClassifier.isLikelyRecipe("Comment RECIPE and I'll send you my homemade lasagna recipe! #foodie"))
        XCTAssertTrue(RecipeClassifier.isLikelyRecipe("Mercimek çorbası tarifi 🍲 #yemektarifleri"))
    }

    func testNonRecipeCaptionsAreNot() {
        XCTAssertFalse(RecipeClassifier.isLikelyRecipe("Sunset in Bali never gets old 🌅 #travel #wanderlust"))
        XCTAssertFalse(RecipeClassifier.isLikelyRecipe("POV: it's Monday again 😂 #memes #relatable"))
        XCTAssertFalse(RecipeClassifier.isLikelyRecipe("New leg day routine 💪 3 sets of 12 squats #gym #fitness"))
    }
}

final class InstagramExportTests: XCTestCase {
    func testFindsLinksInSavedPostsJSON() {
        let json = #"""
        {"saved_saved_media": [
          {"title": "chef.anna", "string_map_data": {"Saved on": {"href": "https:\/\/www.instagram.com\/reel\/ABC123\/", "timestamp": 1700000000}}},
          {"title": "travelguy", "string_map_data": {"Saved on": {"href": "https://www.instagram.com/p/XYZ_9/", "timestamp": 1690000000}}},
          {"title": "chef.anna", "string_map_data": {"Saved on": {"href": "https://www.instagram.com/reel/ABC123/?igsh=1", "timestamp": 1700000000}}}
        ]}
        """#
        XCTAssertEqual(InstagramExport.reelLinks(in: json).map(\.absoluteString), [
            "https://www.instagram.com/reel/ABC123/",
            "https://www.instagram.com/reel/XYZ_9/",
        ])
    }
}
