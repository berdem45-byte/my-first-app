# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Reel Recipes: a SwiftUI + SwiftData iOS app (iOS 17+, Swift 5) that saves Instagram recipe reels, extracts the recipe from the caption, and tags it by cuisine/country/type. There are no third-party dependencies. User-facing docs are in `README.md` and `TESTING.md`.

## Commands

The Xcode project is **generated** from `project.yml` by XcodeGen and is gitignored. Never edit `ReelRecipes.xcodeproj` by hand. After adding/removing files or changing targets or settings, edit `project.yml` and regenerate.

```bash
xcodegen generate                      # creates ReelRecipes.xcodeproj
xcodebuild test -project ReelRecipes.xcodeproj -scheme ReelRecipes \
  -destination 'platform=iOS Simulator,name=iPhone 16' CODE_SIGNING_ALLOWED=NO

# Single test class or method:
xcodebuild test ... -only-testing:ReelRecipesTests/RecipeParserTests
xcodebuild test ... -only-testing:ReelRecipesTests/RecipeParserTests/testTurkishHeaders
```

Building needs macOS and Xcode 16+. Xcode 26 / the iOS 26 SDK is needed to compile the `FoundationModels` path. On a Linux container (no `swift`/`xcodebuild`), you can't build or test locally. CI (`.github/workflows/ios.yml`, macos-15) runs on every push and is the way to verify changes there. There is no linter configured.

## Architecture

Three targets (defined in `project.yml`):
- **ReelRecipes**: the app. Compiles `ReelRecipes/` **and** `Shared/`.
- **ReelRecipesShare**: the Share Extension (`ShareExtension/`). Also compiles `Shared/`. Code used by both must live in `Shared/` and must not depend on app-only types (SwiftData model, services).
- **ReelRecipesTests**: all unit tests are in `ReelRecipesTests/RecipeParserTests.swift` (parser, tagger, Instagram link/OG parsing, classifier, export parsing). They use `@testable import ReelRecipes`.

### Share Extension → app handoff
The extension does no processing. It only calls `PendingShareQueue.enqueue` (JSON in App Group `UserDefaults`, suite `group.com.berdem45.reelrecipes`). The app drains the queue each time the scene becomes active (`ReelRecipesApp` → `RecipeImporter.importSharedReels`). The App Group ID is duplicated in `project.yml` (both entitlements) and `Shared/PendingShareQueue.swift`. Keep them in sync.

### Import pipeline (`Services/RecipeImporter.swift`, `@MainActor`)
Status-driven: `Recipe.statusRaw` holds a `RecipeStatus` (`pending → processing → ready | needsCaption | notRecipe`). `importSharedReels` re-fetches every `pending`/`processing` recipe in a loop until none remain, so anything that inserts `pending` recipes (shares, the Instagram export import, "retry missing captions") gets processed by the same loop. It sleeps 1s between reels for large batches to avoid Instagram rate limits.

`process(recipe)`:
1. `InstagramMetadataFetcher` fetches the reel page with a `facebookexternalhit` User-Agent and reads `og:` meta tags for the caption, author and thumbnail. No caption → `.needsCaption` (the user pastes it).
2. The recipe check only applies to `importedFromExport` reels: `RecipeClassifier` (a keyword/structure score, threshold 3). The user's `isRecipeOverride` always wins. Reels shared individually are assumed to be recipes.
3. Extraction: `AIRecipeExtractor` (Apple on-device `FoundationModels`, iOS 26+, guarded by `#if canImport` + `#available`, returns nil when unavailable) is preferred field by field. `RecipeParser` (rule-based, multilingual section headers EN/TR/ES/FR/DE/IT, line-shape fallback) fills any gaps and always provides servings/minutes.
4. `RecipeTagger`/`CuisineCatalog` detect cuisine, country (flag) and tags by keyword. Its results take priority over the AI's cuisine/country. Add cuisines or tags here.

Text matching uses helpers in `Services/TextUtils.swift` (e.g. `normalizedForMatching` folds accents such as Turkish characters, and `trimmed`). Reuse these instead of ad-hoc normalization.

### Instagram export import
`InstagramExport` parses the `saved_posts.json` from Instagram's "Download your information". `RecipeImporter.addExportedReels` dedupes by `sourceURL` and inserts the new reels as `pending` with `importedFromExport = true`.
