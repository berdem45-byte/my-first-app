import SwiftData
import SwiftUI

struct RecipeListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Recipe.createdAt, order: .reverse) private var recipes: [Recipe]

    @State private var searchText = ""
    @State private var selectedCuisine: String?
    @State private var selectedTags: Set<String> = []
    @State private var favoritesOnly = false
    @State private var showNonRecipes = false
    @State private var isAdding = false
    @State private var isImporting = false

    private var filtered: [Recipe] {
        recipes.filter { recipe in
            (recipe.status == .notRecipe) == showNonRecipes
                && (selectedCuisine == nil || recipe.cuisine == selectedCuisine)
                && (!favoritesOnly || recipe.isFavorite)
                && selectedTags.isSubset(of: Set(recipe.tags))
                && recipe.matches(searchText)
        }
    }

    private var cuisines: [String] {
        Set(recipes.compactMap(\.cuisine)).sorted()
    }

    /// Tags ordered by how many recipes use them.
    private var tags: [String] {
        let counts = recipes.flatMap(\.tags).reduce(into: [String: Int]()) { $0[$1, default: 0] += 1 }
        return counts.keys.sorted { (counts[$0]!, $1) > (counts[$1]!, $0) }
    }

    private var isFiltering: Bool {
        selectedCuisine != nil || !selectedTags.isEmpty || favoritesOnly || showNonRecipes
    }

    private var inProgressCount: Int {
        recipes.filter { $0.status == .pending || $0.status == .processing }.count
    }

    private var missingCaptionCount: Int {
        recipes.filter { $0.status == .needsCaption }.count
    }

    private var nonRecipeCount: Int {
        recipes.filter { $0.status == .notRecipe }.count
    }

    var body: some View {
        NavigationStack {
            Group {
                if recipes.isEmpty {
                    emptyState
                } else {
                    list
                }
            }
            .navigationTitle("Reel Recipes")
            .navigationDestination(for: Recipe.self) { RecipeDetailView(recipe: $0) }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { filterMenu }
                ToolbarItem(placement: .primaryAction) { addMenu }
            }
            .sheet(isPresented: $isAdding) { AddRecipeView() }
            .sheet(isPresented: $isImporting) { ImportFromInstagramView() }
        }
    }

    private var list: some View {
        List {
            if inProgressCount > 0 {
                HStack(spacing: 10) {
                    ProgressView()
                    Text("Checking \(inProgressCount) saved reel\(inProgressCount == 1 ? "" : "s")…")
                        .font(.subheadline)
                }
            }

            if showNonRecipes {
                Text("These reels didn't look like recipes. Open one and tap **It's a recipe** if we got it wrong.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if !tags.isEmpty && !showNonRecipes {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(tags, id: \.self) { tag in
                            Button {
                                if selectedTags.contains(tag) { selectedTags.remove(tag) } else { selectedTags.insert(tag) }
                            } label: {
                                TagChip(text: tag, isSelected: selectedTags.contains(tag))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                .listRowBackground(Color.clear)
            }

            ForEach(filtered) { recipe in
                NavigationLink(value: recipe) { RecipeRow(recipe: recipe) }
            }
            .onDelete { offsets in
                let toDelete = offsets.map { filtered[$0] }
                toDelete.forEach { context.delete($0) }
            }

            if filtered.isEmpty {
                ContentUnavailableView.search(text: searchText)
                    .listRowBackground(Color.clear)
            }
        }
        .searchable(text: $searchText, prompt: "Search recipes, ingredients, tags")
        .refreshable { await RecipeImporter.importSharedReels(into: context) }
    }

    private var filterMenu: some View {
        Menu {
            Toggle(isOn: $favoritesOnly) { Label("Favorites only", systemImage: "heart") }
            Toggle(isOn: $showNonRecipes) { Label("Show non-recipe reels (\(nonRecipeCount))", systemImage: "eye.slash") }
            Picker("Cuisine", selection: $selectedCuisine) {
                Text("All cuisines").tag(String?.none)
                ForEach(cuisines, id: \.self) { cuisine in
                    Text("\(CuisineCatalog.cuisine(named: cuisine)?.flag ?? "🍽️") \(cuisine)").tag(String?.some(cuisine))
                }
            }
            if isFiltering {
                Button("Clear filters", role: .destructive) {
                    selectedCuisine = nil
                    selectedTags = []
                    favoritesOnly = false
                    showNonRecipes = false
                }
            }
        } label: {
            Label("Filter", systemImage: isFiltering ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
        }
    }

    private var addMenu: some View {
        Menu {
            Button { isAdding = true } label: { Label("Paste a reel link", systemImage: "link") }
            Button { isImporting = true } label: { Label("Import saved posts from Instagram", systemImage: "square.and.arrow.down.on.square") }
            if missingCaptionCount > 0 {
                Button {
                    Task { await RecipeImporter.retryMissingCaptions(in: context) }
                } label: {
                    Label("Retry \(missingCaptionCount) missing caption\(missingCaptionCount == 1 ? "" : "s")", systemImage: "arrow.clockwise")
                }
            }
        } label: {
            Label("Add", systemImage: "plus")
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No recipes yet", systemImage: "fork.knife.circle")
        } description: {
            Text("In Instagram, tap **Share** on a recipe reel and choose **Reel Recipes**. Or import everything you've saved on Instagram at once.")
        } actions: {
            Button("Import saved posts from Instagram") { isImporting = true }
                .buttonStyle(.borderedProminent)
            Button("Paste a reel link") { isAdding = true }
        }
    }
}

private struct RecipeRow: View {
    let recipe: Recipe

    var body: some View {
        HStack(spacing: 12) {
            RecipeThumbnail(data: recipe.thumbnailData)
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    Text(recipe.displayTitle)
                        .font(.headline)
                        .lineLimit(2)
                    if recipe.isFavorite {
                        Image(systemName: "heart.fill").font(.caption).foregroundStyle(.pink)
                    }
                }
                subtitle
                if !recipe.tags.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(recipe.tags.prefix(3), id: \.self) { TagChip(text: $0, compact: true) }
                    }
                }
            }
        }
        .padding(.vertical, 2)
    }

    @ViewBuilder
    private var subtitle: some View {
        switch recipe.status {
        case .pending, .processing:
            HStack(spacing: 6) {
                ProgressView().controlSize(.mini)
                Text("Extracting recipe…")
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        case .needsCaption:
            Label("Paste the caption to finish", systemImage: "exclamationmark.circle")
                .font(.subheadline)
                .foregroundStyle(.orange)
        case .notRecipe:
            Text("Not a recipe")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        case .ready:
            let parts = [recipe.cuisine, recipe.country.map { "\(recipe.countryFlag ?? "") \($0)".trimmed }].compactMap { $0 }
            if !parts.isEmpty {
                Text(parts.joined(separator: " · "))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
