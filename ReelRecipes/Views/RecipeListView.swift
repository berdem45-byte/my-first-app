import SwiftData
import SwiftUI

struct RecipeListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Recipe.createdAt, order: .reverse) private var recipes: [Recipe]

    @State private var searchText = ""
    @State private var selectedCuisine: String?
    @State private var selectedTags: Set<String> = []
    @State private var favoritesOnly = false
    @State private var isAdding = false

    private var filtered: [Recipe] {
        recipes.filter { recipe in
            (selectedCuisine == nil || recipe.cuisine == selectedCuisine)
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
        selectedCuisine != nil || !selectedTags.isEmpty || favoritesOnly
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
                ToolbarItem(placement: .primaryAction) {
                    Button { isAdding = true } label: { Label("Add reel", systemImage: "plus") }
                }
            }
            .sheet(isPresented: $isAdding) { AddRecipeView() }
        }
    }

    private var list: some View {
        List {
            if !tags.isEmpty {
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
                }
            }
        } label: {
            Label("Filter", systemImage: isFiltering ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No recipes yet", systemImage: "fork.knife.circle")
        } description: {
            Text("In Instagram, tap **Share** on a recipe reel and choose **Reel Recipes**. Or tap **+** to paste a reel link.")
        } actions: {
            Button("Add a reel") { isAdding = true }
                .buttonStyle(.borderedProminent)
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
