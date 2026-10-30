import SwiftData
import SwiftUI

struct RecipeEditView: View {
    let recipe: Recipe
    @Environment(\.dismiss) private var dismiss

    @State private var title: String
    @State private var cuisine: String
    @State private var country: String
    @State private var tags: String
    @State private var ingredients: String
    @State private var steps: String
    @State private var notes: String
    @State private var caption: String
    @State private var isSaving = false

    init(recipe: Recipe) {
        self.recipe = recipe
        _title = State(initialValue: recipe.title)
        _cuisine = State(initialValue: recipe.cuisine ?? "")
        _country = State(initialValue: recipe.country ?? "")
        _tags = State(initialValue: recipe.tags.joined(separator: ", "))
        _ingredients = State(initialValue: recipe.ingredients.joined(separator: "\n"))
        _steps = State(initialValue: recipe.steps.joined(separator: "\n"))
        _notes = State(initialValue: recipe.notes)
        _caption = State(initialValue: recipe.rawCaption)
    }

    private var captionChanged: Bool {
        caption.trimmed != recipe.rawCaption.trimmed
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Title") {
                    TextField("Recipe name", text: $title)
                }

                Section {
                    HStack {
                        TextField("Cuisine", text: $cuisine)
                        Menu {
                            ForEach(CuisineCatalog.all) { item in
                                Button("\(item.flag) \(item.name)") {
                                    cuisine = item.name
                                    country = item.country
                                }
                            }
                        } label: {
                            Image(systemName: "list.bullet.circle")
                        }
                    }
                    TextField("Country", text: $country)
                    TextField("Tags, separated by commas", text: $tags)
                        .textInputAutocapitalization(.never)
                } header: {
                    Text("Cuisine & tags")
                }

                Section {
                    TextEditor(text: $ingredients).frame(minHeight: 120)
                } header: {
                    Text("Ingredients")
                } footer: {
                    Text("One per line. End a line with “:” to make it a sub-heading.")
                }

                Section {
                    TextEditor(text: $steps).frame(minHeight: 140)
                } header: {
                    Text("Steps")
                } footer: {
                    Text("One step per line.")
                }

                Section("My notes") {
                    TextEditor(text: $notes).frame(minHeight: 60)
                }

                Section {
                    TextEditor(text: $caption).frame(minHeight: 140)
                } header: {
                    Text("Original caption")
                } footer: {
                    Text(captionChanged
                         ? "The caption changed — the recipe will be re-extracted from it when you save."
                         : "Paste the reel's description here if it's missing.")
                }
            }
            .navigationTitle("Edit recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { Task { await save() } }
                        .disabled(isSaving)
                }
            }
        }
    }

    private func save() async {
        isSaving = true
        defer { isSaving = false }

        if captionChanged {
            // New caption: extract from scratch, then keep the user's notes.
            recipe.rawCaption = caption
            recipe.notes = notes.trimmed
            await RecipeImporter.process(recipe)
            dismiss()
            return
        }

        recipe.title = title.trimmed
        recipe.cuisine = cuisine.trimmed.isEmpty ? nil : cuisine.trimmed
        recipe.country = country.trimmed.isEmpty ? nil : country.trimmed
        recipe.tags = tags.split(separator: ",").map { String($0).trimmed.lowercased() }.filter { !$0.isEmpty }
        recipe.ingredients = lines(ingredients)
        recipe.steps = lines(steps)
        recipe.notes = notes.trimmed
        dismiss()
    }

    private func lines(_ text: String) -> [String] {
        text.components(separatedBy: .newlines).map(\.trimmed).filter { !$0.isEmpty }
    }
}
