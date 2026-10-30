import SwiftData
import SwiftUI

struct AddRecipeView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var link = ""
    @State private var caption = ""

    private var canSave: Bool {
        InstagramLink.firstURL(in: link) != nil || !caption.trimmed.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("https://www.instagram.com/reel/…", text: $link, axis: .vertical)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    PasteButton(payloadType: String.self) { strings in
                        if let text = strings.first { link = text }
                    }
                } header: {
                    Text("Reel link")
                } footer: {
                    Text("In Instagram tap ••• or Share → Copy link. Tip: sharing directly to Reel Recipes from Instagram skips this step.")
                }

                Section {
                    TextEditor(text: $caption)
                        .frame(minHeight: 160)
                } header: {
                    Text("Caption (optional)")
                } footer: {
                    Text("Leave empty and the caption is fetched automatically. If that fails, copy the reel's description and paste it here.")
                }
            }
            .navigationTitle("Add reel")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save).disabled(!canSave)
                }
            }
        }
    }

    private func save() {
        let url = InstagramLink.canonicalURL(from: link) ?? InstagramLink.firstURL(in: link)
        let recipe = Recipe(sourceURL: url?.absoluteString ?? "", rawCaption: caption.trimmed)
        context.insert(recipe)
        dismiss()
        Task { await RecipeImporter.process(recipe) }
    }
}
