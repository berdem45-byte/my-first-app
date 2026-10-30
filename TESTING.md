# Running and testing Reel Recipes on your iPhone

## 1. What you need

| | |
| --- | --- |
| A Mac | Running macOS 14 or later, with **Xcode 16+** from the Mac App Store (Xcode 26 enables the Apple Intelligence extractor) |
| An iPhone | iOS 17 or later, plus a USB cable (or the same Wi-Fi network after the first run) |
| An Apple ID | A free Apple ID works for trying the app. To use **Share → Reel Recipes** from Instagram you need the paid **Apple Developer Program** ($99/yr), because free accounts can't use *App Groups*, which the Share Extension needs to pass reels to the app. |

## 2. Build it

```bash
git clone https://github.com/berdem45-byte/my-first-app.git
cd my-first-app
git checkout claude/ios-app-development-cof1uc
brew install xcodegen        # once (needs Homebrew: https://brew.sh)
xcodegen generate
open ReelRecipes.xcodeproj
```

## 3. Sign it

1. In Xcode: **Settings → Accounts → +** and sign in with your Apple ID.
2. Click the blue **ReelRecipes** project at the top of the file list.
3. Target **ReelRecipes** → **Signing & Capabilities** → **Team**: pick your account.
4. Do the same for the **ReelRecipesShare** target.
5. If Xcode says the bundle ID or App Group is taken, change `com.berdem45` and `group.com.berdem45.reelrecipes` to something unique in `project.yml` and `Shared/PendingShareQueue.swift`. Then run `xcodegen generate` again.

**Free Apple ID only:** Xcode will report *"Personal development teams do not support the App Groups capability."* Delete the two `entitlements:` blocks in `project.yml`, run `xcodegen generate` again, and use the paste-link and import features. The share button won't hand reels to the app without App Groups. Apps signed with a free account also stop opening after 7 days; just run them from Xcode again.

## 4. Run it on the phone

1. Plug in the iPhone and tap **Trust** on the phone.
2. On the iPhone: **Settings → Privacy & Security → Developer Mode → On** (the phone restarts).
3. In Xcode's top bar, choose your iPhone as the run destination and press **▶︎ Run** (⌘R).
4. The first time only: on the iPhone go to **Settings → General → VPN & Device Management** → your Apple ID → **Trust**.

To share the app with friends without a cable, a paid account lets you upload it to **TestFlight**: **Product → Archive → Distribute App → TestFlight**.

## 5. Things to try

| # | Test | What should happen |
| --- | --- | --- |
| 1 | **Share a single reel.** In Instagram open a recipe reel → **Share** (paper plane) → scroll the app row → **More** → enable **Reel Recipes** → tap it → **Save**. Open Reel Recipes. | The reel appears with "Extracting recipe…", then shows a title, thumbnail, cuisine and flag, tags, ingredients and steps. |
| 2 | **Paste a link.** In Instagram tap **Share → Copy link**. In the app tap **+ → Paste a reel link → Paste → Save**. | Same as test 1. |
| 3 | **Caption fallback.** If a reel says *Caption needed*: open the reel, long-press the caption and copy it. Then in the app go to the recipe → **Paste caption** → paste → **Save**. | The recipe is extracted from the pasted text. |
| 4 | **Import all saved posts.** In the app tap **+ → Import saved posts from Instagram** and follow the steps shown to request your export (Instagram can take minutes to hours to prepare it). Unzip it in Files and pick `saved_posts.json`. | "Found N saved posts, M new". A "Checking N saved reels…" bar counts down at about one reel per second. |
| 5 | **Recipe detection.** After test 4, go to **Filter → Show non-recipe reels**. | Travel, fitness and meme reels are listed here, not in the cookbook. Open one and tap **It's a recipe** to move it over. In a real recipe, **⋯ → Not a recipe** does the opposite. |
| 6 | **Rate limits.** If many imported reels say *Caption needed*, wait about 10 minutes, then tap **+ → Retry missing captions**. | More captions come through. |
| 7 | **Search and filter.** Search for an ingredient ("garlic"). Tap tag chips (`dessert`, `quick`). Use **Filter → Cuisine**. | The list narrows as expected. |
| 8 | **Cooking mode.** Open a recipe and tap ingredients. | They're checked off and struck through. **Watch reel** opens Instagram. |
| 9 | **Editing.** **⋯ → Edit**: change the cuisine with the list button, add tags, and fix ingredients. | Changes are saved, and the list's filters update. |

## 6. Automated tests

- In Xcode: **⌘U** runs the unit tests (parser, tagger, recipe classifier, Instagram link and export parsing).
- On GitHub: every push runs **Actions → iOS build & test**.

## Known limitations

- Instagram has no public API for reading your saved posts or captions. The import uses Instagram's own data export, and captions are read from the public preview data of each reel. Private accounts' reels always need the caption pasted.
- Recipe detection reads the caption only, not the video. A reel whose caption just says "🔥🔥" can't be classified. Fix those by hand with **It's a recipe** or **Not a recipe**.
