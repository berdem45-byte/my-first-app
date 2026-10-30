import Foundation

/// Helpers for recognising and normalising Instagram post / reel links.
enum InstagramLink {
    private static let pattern = try! NSRegularExpression(
        pattern: #"instagram\.com/(?:[A-Za-z0-9_.]+/)?(reel|reels|p|tv)/([A-Za-z0-9_-]+)"#,
        options: [.caseInsensitive]
    )

    /// The post shortcode, e.g. `C9xYz12AbCd` for `https://www.instagram.com/reel/C9xYz12AbCd/?igsh=...`.
    static func shortcode(in text: String) -> String? {
        let range = NSRange(text.startIndex..., in: text)
        guard let match = pattern.firstMatch(in: text, range: range),
              let codeRange = Range(match.range(at: 2), in: text) else { return nil }
        return String(text[codeRange])
    }

    /// A clean canonical URL without tracking parameters, or nil if `text` has no Instagram link.
    static func canonicalURL(from text: String) -> URL? {
        guard let code = shortcode(in: text) else { return nil }
        return URL(string: "https://www.instagram.com/reel/\(code)/")
    }

    /// The first http(s) URL found anywhere in `text`.
    static func firstURL(in text: String) -> URL? {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else { return nil }
        let range = NSRange(text.startIndex..., in: text)
        return detector.matches(in: text, range: range)
            .compactMap(\.url)
            .first { $0.scheme?.hasPrefix("http") == true }
    }
}
