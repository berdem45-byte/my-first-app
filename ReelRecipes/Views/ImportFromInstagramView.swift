import SwiftData
import SwiftUI
import UniformTypeIdentifiers

/// Bulk-imports every saved post from Instagram's "Download your information" export.
struct ImportFromInstagramView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var isPickingFile = false
    @State private var result: (found: Int, added: Int)?
    @State private var errorMessage: String?

    private let steps = [
        "Open Instagram → your profile → ☰ menu → **Accounts Center**.",
        "Tap **Your information and permissions** → **Download your information**.",
        "Choose **Download or transfer information** → your account → **Some of your information**.",
        "Under *Your Instagram activity*, select **Saved**, then **Download to device**.",
        "Set **Format: JSON** and **Date range: All time**, then **Create files**.",
        "When Instagram notifies you (minutes to a few hours), download the .zip and open it in the **Files** app. Tap it to unzip.",
        "Come back here, tap **Choose file**, and pick `your_instagram_activity/saved/saved_posts.json`.",
    ]

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Instagram doesn't let apps read your saved posts directly. You can download them from Instagram yourself, and Reel Recipes imports the file, fetches each caption, and keeps only the reels that look like recipes.")
                        .font(.subheadline)
                }

                Section("Get your saved posts from Instagram") {
                    ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .firstTextBaseline, spacing: 10) {
                            Text("\(index + 1)")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(Color.accentColor)
                                .frame(minWidth: 16)
                            Text(LocalizedStringKey(step))
                                .font(.subheadline)
                        }
                    }
                }

                Section {
                    Button {
                        isPickingFile = true
                    } label: {
                        Label("Choose file", systemImage: "doc.badge.plus")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .listRowBackground(Color.clear)
                } footer: {
                    Text("Only the list of links is read. Nothing is uploaded anywhere.")
                }

                if let result {
                    Section("Imported") {
                        Label("Found \(result.found) saved posts, \(result.added) new.", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        if result.added > 0 {
                            Text("They're being checked in the background (about a second each). Reels that aren't recipes are hidden — find them under Filter → Show non-recipe reels.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                if let errorMessage {
                    Section {
                        Label(errorMessage, systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.orange)
                    }
                }
            }
            .navigationTitle("Import from Instagram")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .fileImporter(isPresented: $isPickingFile, allowedContentTypes: [.json, .html, .plainText, .text]) { picked in
                switch picked {
                case .success(let url): importFile(url)
                case .failure(let error): errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func importFile(_ url: URL) {
        errorMessage = nil
        do {
            let links = try InstagramExport.reelLinks(inFileAt: url)
            guard !links.isEmpty else {
                errorMessage = "No Instagram posts found in that file. Make sure you picked saved_posts.json."
                return
            }
            result = RecipeImporter.addExportedReels(links, into: context)
            Task { await RecipeImporter.importSharedReels(into: context) }
        } catch {
            errorMessage = "Couldn't read the file: \(error.localizedDescription)"
        }
    }
}
