import Foundation
import SwiftData

enum RecipeStatus: String, Codable {
    /// Saved, not yet processed.
    case pending
    /// Caption is being fetched / parsed.
    case processing
    /// The caption could not be fetched; the user needs to paste it.
    case needsCaption
    case ready
}

@Model
final class Recipe {
    var id: UUID = UUID()
    var title: String = ""
    var sourceURL: String = ""
    var authorHandle: String?
    @Attribute(.externalStorage) var thumbnailData: Data?
    var rawCaption: String = ""
    var ingredients: [String] = []
    var steps: [String] = []
    var cuisine: String?
    var country: String?
    var tags: [String] = []
    var servings: Int?
    var totalMinutes: Int?
    var notes: String = ""
    var isFavorite: Bool = false
    var statusRaw: String = RecipeStatus.pending.rawValue
    var createdAt: Date = Date()

    init(sourceURL: String, rawCaption: String = "", createdAt: Date = .now) {
        self.sourceURL = sourceURL
        self.rawCaption = rawCaption
        self.createdAt = createdAt
    }

    var status: RecipeStatus {
        get { RecipeStatus(rawValue: statusRaw) ?? .pending }
        set { statusRaw = newValue.rawValue }
    }

    var displayTitle: String {
        title.isEmpty ? "Untitled recipe" : title
    }

    var url: URL? { URL(string: sourceURL) }

    var countryFlag: String? {
        country.flatMap(CuisineCatalog.flag(forCountry:))
    }

    func matches(_ query: String) -> Bool {
        let q = query.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return true }
        let haystack = [title, cuisine ?? "", country ?? "", authorHandle ?? "", notes]
            + ingredients + tags
        return haystack.contains { $0.localizedCaseInsensitiveContains(q) }
    }
}
