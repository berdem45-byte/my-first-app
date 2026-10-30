import SwiftUI
import UIKit
import UniformTypeIdentifiers

/// Receives a reel from Instagram's share sheet and queues it for the main app.
final class ShareViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        Task { @MainActor in
            let (url, text) = await loadSharedContent()
            let shareView = ShareView(
                url: url,
                sharedText: text,
                onSave: { [weak self] caption in
                    if let url {
                        PendingShareQueue.enqueue(PendingShare(url: url.absoluteString, caption: caption, sharedAt: .now))
                    }
                    self?.extensionContext?.completeRequest(returningItems: nil)
                },
                onCancel: { [weak self] in
                    self?.extensionContext?.cancelRequest(withError: CocoaError(.userCancelled))
                }
            )
            let host = UIHostingController(rootView: shareView)
            addChild(host)
            host.view.frame = view.bounds
            host.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            view.addSubview(host.view)
            host.didMove(toParent: self)
        }
    }

    /// Instagram shares the reel as a URL; some apps share it as plain text containing the link.
    private func loadSharedContent() async -> (URL?, String?) {
        let providers = (extensionContext?.inputItems as? [NSExtensionItem] ?? [])
            .flatMap { $0.attachments ?? [] }

        var url: URL?
        var text: String?
        for provider in providers {
            if url == nil, provider.hasItemConformingToTypeIdentifier(UTType.url.identifier),
               let item = try? await provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) {
                url = (item as? URL) ?? (item as? Data).flatMap { URL(dataRepresentation: $0, relativeTo: nil) }
            }
            if text == nil, provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier),
               let item = try? await provider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) {
                text = (item as? String) ?? (item as? Data).flatMap { String(data: $0, encoding: .utf8) }
            }
        }

        if url == nil, let text { url = InstagramLink.firstURL(in: text) }
        if let found = url, let canonical = InstagramLink.canonicalURL(from: found.absoluteString) { url = canonical }
        return (url, text)
    }
}

struct ShareView: View {
    let url: URL?
    let sharedText: String?
    let onSave: (String) -> Void
    let onCancel: () -> Void

    @State private var caption: String
    @State private var saved = false

    init(url: URL?, sharedText: String?, onSave: @escaping (String) -> Void, onCancel: @escaping () -> Void) {
        self.url = url
        self.sharedText = sharedText
        self.onSave = onSave
        self.onCancel = onCancel
        // If the shared text is more than just the link, it is probably the caption.
        var initial = sharedText ?? ""
        if let url { initial = initial.replacingOccurrences(of: url.absoluteString, with: "") }
        initial = initial.trimmingCharacters(in: .whitespacesAndNewlines)
        _caption = State(initialValue: initial.count > 40 ? initial : "")
    }

    private var isInstagram: Bool {
        url.map { InstagramLink.shortcode(in: $0.absoluteString) != nil } ?? false
    }

    var body: some View {
        NavigationStack {
            Form {
                if let url {
                    Section {
                        Label(isInstagram ? "Instagram reel" : url.host() ?? "Link", systemImage: "play.rectangle")
                            .font(.headline)
                        Text(url.absoluteString)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                    Section {
                        TextEditor(text: $caption)
                            .frame(minHeight: 120)
                    } header: {
                        Text("Caption (optional)")
                    } footer: {
                        Text("Reel Recipes fetches the caption automatically when you open the app. Paste it here only if a reel's recipe doesn't come through.")
                    }
                } else {
                    Section {
                        Text("No link found. Share a reel from Instagram using the Share button.")
                    }
                }
            }
            .navigationTitle(saved ? "Saved!" : "Save recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saved = true
                        onSave(caption.trimmingCharacters(in: .whitespacesAndNewlines))
                    }
                    .disabled(url == nil || saved)
                }
            }
        }
    }
}
