import SwiftData
import SwiftUI

struct RecipeDetailView: View {
    @Bindable var recipe: Recipe
    @Environment(\.openURL) private var openURL

    @State private var isEditing = false
    @State private var checkedIngredients: Set<Int> = []
    @State private var isReprocessing = false

    var body: some View {
        List {
            header

            if recipe.status == .notRecipe {
                Section {
                    Text("This reel's caption doesn't look like a recipe, so it's hidden from your cookbook.")
                        .font(.subheadline)
                    Button("It's a recipe") { reprocess { await RecipeImporter.setIsRecipe(true, for: recipe) } }
                }
            }

            if recipe.status == .needsCaption {
                Section {
                    Text("Instagram didn't share this reel's caption. Open the reel, copy its description, and paste it here.")
                        .font(.subheadline)
                    Button("Open reel in Instagram") { openReel() }
                    Button("Paste caption") { isEditing = true }
                } header: {
                    Label("Caption needed", systemImage: "exclamationmark.circle")
                }
            }

            if !recipe.ingredients.isEmpty {
                Section("Ingredients") {
                    ForEach(Array(recipe.ingredients.enumerated()), id: \.offset) { index, ingredient in
                        if ingredient.hasSuffix(":") {
                            Text(ingredient.dropLast())
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)
                        } else {
                            Button {
                                if checkedIngredients.contains(index) { checkedIngredients.remove(index) } else { checkedIngredients.insert(index) }
                            } label: {
                                HStack(alignment: .firstTextBaseline, spacing: 10) {
                                    Image(systemName: checkedIngredients.contains(index) ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(Color.accentColor)
                                    Text(ingredient)
                                        .strikethrough(checkedIngredients.contains(index))
                                        .foregroundStyle(checkedIngredients.contains(index) ? Color.secondary : Color.primary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            if !recipe.steps.isEmpty {
                Section("Steps") {
                    ForEach(Array(recipe.steps.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .firstTextBaseline, spacing: 10) {
                            Text("\(index + 1)")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(Color.accentColor)
                                .frame(minWidth: 18)
                            Text(step)
                        }
                    }
                }
            }

            if recipe.status == .ready && recipe.ingredients.isEmpty && recipe.steps.isEmpty {
                Section {
                    Text("No ingredients or steps were found in the caption. The full text is below — you can tidy it up with Edit.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            if !recipe.notes.isEmpty {
                Section("My notes") { Text(recipe.notes) }
            }

            if !recipe.rawCaption.isEmpty {
                Section {
                    DisclosureGroup("Original caption") {
                        Text(recipe.rawCaption)
                            .font(.callout)
                            .textSelection(.enabled)
                    }
                }
            }
        }
        .navigationTitle(recipe.displayTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    recipe.isFavorite.toggle()
                } label: {
                    Label("Favorite", systemImage: recipe.isFavorite ? "heart.fill" : "heart")
                }
                .tint(.pink)

                Menu {
                    Button { isEditing = true } label: { Label("Edit", systemImage: "pencil") }
                    Button {
                        reprocess { await RecipeImporter.process(recipe) }
                    } label: {
                        Label("Re-extract from caption", systemImage: "wand.and.stars")
                    }
                    .disabled(isReprocessing)
                    if recipe.status == .ready {
                        Button {
                            reprocess { await RecipeImporter.setIsRecipe(false, for: recipe) }
                        } label: {
                            Label("Not a recipe", systemImage: "eye.slash")
                        }
                    }
                    if let url = recipe.url {
                        ShareLink(item: url) { Label("Share reel", systemImage: "square.and.arrow.up") }
                    }
                    ShareLink(item: shareText) { Label("Share recipe as text", systemImage: "doc.text") }
                } label: {
                    Label("More", systemImage: "ellipsis.circle")
                }
            }
        }
        .overlay {
            if isReprocessing || recipe.status == .processing {
                ProgressView("Extracting…")
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .sheet(isPresented: $isEditing) { RecipeEditView(recipe: recipe) }
    }

    private var header: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                if let data = recipe.thumbnailData, let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity, maxHeight: 260)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }

                Text(recipe.displayTitle)
                    .font(.title2.weight(.bold))

                if let author = recipe.authorHandle {
                    Text("@\(author)").font(.subheadline).foregroundStyle(.secondary)
                }

                HStack(spacing: 16) {
                    if let cuisine = recipe.cuisine {
                        Label(cuisine, systemImage: "globe")
                    }
                    if let country = recipe.country {
                        Text("\(recipe.countryFlag ?? "📍") \(country)")
                    }
                    if let minutes = recipe.totalMinutes {
                        Label("\(minutes) min", systemImage: "clock")
                    }
                    if let servings = recipe.servings {
                        Label("\(servings)", systemImage: "person.2")
                    }
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)

                if !recipe.tags.isEmpty {
                    FlowLayout {
                        ForEach(recipe.tags, id: \.self) { TagChip(text: $0) }
                    }
                }

                if recipe.url != nil {
                    Button {
                        openReel()
                    } label: {
                        Label("Watch reel", systemImage: "play.rectangle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(.vertical, 4)
        }
    }

    private func reprocess(_ work: @escaping () async -> Void) {
        Task {
            isReprocessing = true
            await work()
            isReprocessing = false
        }
    }

    /// instagram.com links are universal links, so this opens the Instagram app when installed.
    private func openReel() {
        if let url = recipe.url { openURL(url) }
    }

    private var shareText: String {
        var lines = [recipe.displayTitle, ""]
        if !recipe.ingredients.isEmpty {
            lines.append("Ingredients:")
            lines += recipe.ingredients.map { "• \($0)" }
            lines.append("")
        }
        if !recipe.steps.isEmpty {
            lines.append("Steps:")
            lines += recipe.steps.enumerated().map { "\($0.offset + 1). \($0.element)" }
            lines.append("")
        }
        lines.append(recipe.sourceURL)
        return lines.joined(separator: "\n")
    }
}
