# Reel Recipes 🍝

An iOS app that saves the recipe reels you find on Instagram, pulls the recipe out of the caption, and tags each one by cuisine, country and type. That makes your saved reels a cookbook you can search.

## Features

- **Save from Instagram in one tap.** On a reel, tap **Share → Reel Recipes**. The Share Extension queues the reel, and the app imports it the next time you open it.
- **Paste a link.** Tap **+** in the app and paste a reel link, plus the caption if you have it.
- **Import everything you've saved.** Use Instagram's *Download your information* export (Saved → JSON) to bring in every saved post at once.
- **Recipe detection.** Reels from an import are scored on their caption: ingredient lists, steps, quantities, words like "recipe"/"tarif", and food hashtags. Non-recipes (travel, memes, workouts) are hidden in a "non-recipe reels" filter, and you can correct any mistake with one tap.
- **Automatic caption fetch.** The app reads the reel's public caption and thumbnail.
- **Recipe extraction.**
  - Rule-based parser: finds the *Ingredients* and *Method/Steps* sections (in English, Turkish, Spanish, French, German and Italian) and strips bullets, emoji, numbering, hashtags and "follow for more" lines. If a caption has no section headings, it sorts lines by their shape: quantities go to ingredients, cooking verbs and numbered lines go to steps.
  - On devices with Apple Intelligence (iOS 26+), Apple's on-device model (`FoundationModels`) handles messy captions. It runs fully on the device, so there is no API key and no cost.
- **Auto-tagging:** cuisine and country with a flag (🇹🇷 Turkish, 🇮🇹 Italian, 🇯🇵 Japanese, …, 18 cuisines), plus tags like `dessert`, `breakfast`, `pasta`, `chicken`, `vegan`, `quick`, `air fryer` and `spicy`.
- **Browse:** search recipes, ingredients and tags, filter by cuisine or tag, and keep favourites.
- **Cook:** tick off ingredients as you go, read numbered steps, open the reel in Instagram, and share a recipe as text.
- **Edit anything:** title, cuisine, tags, ingredients, steps and personal notes. Paste a new caption and the recipe is extracted again.

## Running it

**Step-by-step guide for running on your iPhone and what to test: [TESTING.md](TESTING.md).**

Requirements: a Mac with **Xcode 16 or later** (Xcode 26 to enable the Apple Intelligence extractor), and **iOS 17+**.

```bash
brew install xcodegen      # once
xcodegen generate          # creates ReelRecipes.xcodeproj from project.yml
open ReelRecipes.xcodeproj
```

Then in Xcode:

1. Select the **ReelRecipes** target → *Signing & Capabilities* → choose your **Team**. Do the same for the **ReelRecipesShare** target.
2. Both targets use the App Group `group.com.berdem45.reelrecipes`. If Xcode reports it's unavailable, change the bundle IDs and group in `project.yml` and `Shared/PendingShareQueue.swift` to your own, then run `xcodegen generate` again.
3. Run on your iPhone. In Instagram, share a reel. If **Reel Recipes** isn't in the share sheet, tap **More** and enable it.

Run the tests with ⌘U, or:

```bash
xcodebuild test -project ReelRecipes.xcodeproj -scheme ReelRecipes \
  -destination 'platform=iOS Simulator,name=iPhone 16' CODE_SIGNING_ALLOWED=NO
```

CI (`.github/workflows/ios.yml`) builds the app and runs the tests on every push.

## How it works

```
Instagram ──share──▶ ShareExtension ──(App Group queue)──▶ App (on open)
                                                            │
                         InstagramMetadataFetcher ◀─────────┤  caption + thumbnail (og: tags)
                         AIRecipeExtractor (iOS 26) ◀───────┤  title / ingredients / steps
                         RecipeParser (fallback) ◀──────────┤
                         RecipeTagger ◀─────────────────────┘  cuisine, country, tags
                                                            ▼
                                                     SwiftData store
```

| Path | What's there |
| --- | --- |
| `ReelRecipes/Models/Recipe.swift` | SwiftData model |
| `ReelRecipes/Services/RecipeParser.swift` | Rule-based caption → ingredients / steps |
| `ReelRecipes/Services/RecipeTagger.swift` | Cuisine catalogue and tagging rules |
| `ReelRecipes/Services/AIRecipeExtractor.swift` | On-device Apple Intelligence extraction |
| `ReelRecipes/Services/InstagramMetadataFetcher.swift` | Caption and thumbnail fetch |
| `ReelRecipes/Services/RecipeImporter.swift` | Runs the whole import pipeline |
| `ReelRecipes/Views/` | SwiftUI screens |
| `ShareExtension/` | The "Share → Reel Recipes" extension |
| `Shared/` | Code shared by the app and the extension |

## Limitations

Instagram has no public API for reading captions. The app reads the caption from the preview data Instagram serves to link-preview bots. That works for most public reels, but it can fail for private accounts, when you hit rate limits, or when Instagram changes its pages. In that case the recipe is marked **Caption needed**: open the reel, copy the description, and paste it in **Edit**.

To support more cuisines or tags, add keywords in `RecipeTagger.swift`.
