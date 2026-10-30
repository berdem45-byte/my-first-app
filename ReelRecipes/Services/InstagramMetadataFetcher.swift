import Foundation

struct InstagramMetadata: Equatable {
    var caption: String?
    var authorHandle: String?
    var imageURL: URL?
}

/// Reads a reel's public caption and thumbnail from the Open Graph tags Instagram serves to link
/// previewers. Instagram has no public caption API, so this is best effort: private posts, login
/// walls or rate limiting return no caption, and the app then asks the user to paste it.
enum InstagramMetadataFetcher {
    enum FetchError: Error { case badResponse }

    static func fetch(_ url: URL) async throws -> InstagramMetadata {
        var request = URLRequest(url: InstagramLink.canonicalURL(from: url.absoluteString) ?? url, timeoutInterval: 15)
        // Link-preview crawlers get the server-rendered page with og: tags.
        request.setValue("facebookexternalhit/1.1 (+http://www.facebook.com/externalhit_uatext.php)", forHTTPHeaderField: "User-Agent")
        request.setValue("en-US,en;q=0.9", forHTTPHeaderField: "Accept-Language")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<400).contains(http.statusCode) else {
            throw FetchError.badResponse
        }
        return parse(html: String(decoding: data, as: UTF8.self))
    }

    static func parse(html: String) -> InstagramMetadata {
        let description = metaContent("og:description", in: html) ?? metaContent("description", in: html)
        let title = metaContent("og:title", in: html)
        let image = metaContent("og:image", in: html).flatMap(URL.init(string:))

        var caption: String?
        var author: String?
        // og:description: `1,234 likes, 56 comments - chefname on March 1, 2025: "Caption text…".`
        if let description {
            caption = description.firstMatch(#":\s*["“]([\s\S]*)["”]\.?\s*$"#, options: [])
            author = description.firstMatch(#"(?:comments?|likes?)\s*-\s*([A-Za-z0-9_.]+)\s+on\s"#)
        }
        // og:title: `Chef Name on Instagram: "Caption text…"`
        if caption == nil, let title {
            caption = title.firstMatch(#"on Instagram:\s*["“]([\s\S]*)["”]\s*$"#, options: [])
        }
        if author == nil {
            author = html.firstMatch(#""username"\s*:\s*"([A-Za-z0-9_.]+)""#)
        }

        let cleanedCaption = caption?.trimmed
        return InstagramMetadata(
            caption: cleanedCaption?.isEmpty == false ? cleanedCaption : nil,
            authorHandle: author,
            imageURL: image
        )
    }

    /// The decoded `content` of `<meta property|name="…" content="…">`, in either attribute order.
    static func metaContent(_ property: String, in html: String) -> String? {
        let p = NSRegularExpression.escapedPattern(for: property)
        let patterns = [
            #"<meta[^>]+(?:property|name)=["']"# + p + #"["'][^>]*?content="([^"]*)""#,
            #"<meta[^>]+content="([^"]*)"[^>]*?(?:property|name)=["']"# + p + #"["']"#,
        ]
        for pattern in patterns {
            if let value = html.firstMatch(pattern) {
                return value.decodingHTMLEntities
            }
        }
        return nil
    }

    static func downloadImage(_ url: URL) async -> Data? {
        guard let (data, response) = try? await URLSession.shared.data(from: url),
              (response as? HTTPURLResponse)?.statusCode == 200 else { return nil }
        return data
    }
}
