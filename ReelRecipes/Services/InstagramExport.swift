import Foundation

/// Reads the post links out of Instagram's "Download your information" export.
///
/// The saved-posts file (`your_instagram_activity/saved/saved_posts.json`, or `.html` if the
/// HTML format was chosen) has changed shape over the years, so rather than decode a specific
/// schema this scans the whole file for post / reel links.
enum InstagramExport {
    static func reelLinks(in text: String) -> [URL] {
        // JSON exports may escape slashes: https:\/\/www.instagram.com\/reel\/…
        let unescaped = text.replacingOccurrences(of: "\\/", with: "/")
        var seen = Set<String>()
        return unescaped
            .allMatches(#"(instagram\.com/(?:[A-Za-z0-9_.]+/)?(?:reel|reels|p|tv)/[A-Za-z0-9_-]+)"#)
            .compactMap { InstagramLink.canonicalURL(from: $0) }
            .filter { seen.insert($0.absoluteString).inserted }
    }

    static func reelLinks(inFileAt url: URL) throws -> [URL] {
        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }
        let data = try Data(contentsOf: url)
        return reelLinks(in: String(decoding: data, as: UTF8.self))
    }
}
