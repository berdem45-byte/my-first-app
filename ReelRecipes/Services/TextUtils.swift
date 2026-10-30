import Foundation

extension String {
    /// Capture group `group` of the first match of `pattern`, or nil.
    func firstMatch(_ pattern: String, group: Int = 1, options: NSRegularExpression.Options = [.caseInsensitive]) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else { return nil }
        let range = NSRange(startIndex..., in: self)
        guard let match = regex.firstMatch(in: self, range: range),
              group <= match.numberOfRanges - 1,
              let r = Range(match.range(at: group), in: self) else { return nil }
        return String(self[r])
    }

    /// Capture group `group` of every match of `pattern`.
    func allMatches(_ pattern: String, group: Int = 1, options: NSRegularExpression.Options = [.caseInsensitive]) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else { return [] }
        let range = NSRange(startIndex..., in: self)
        return regex.matches(in: self, range: range).compactMap { match in
            Range(match.range(at: group), in: self).map { String(self[$0]) }
        }
    }

    func replacingMatches(_ pattern: String, with template: String, options: NSRegularExpression.Options = [.caseInsensitive]) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else { return self }
        let range = NSRange(startIndex..., in: self)
        return regex.stringByReplacingMatches(in: self, range: range, withTemplate: template)
    }

    func matches(_ pattern: String, options: NSRegularExpression.Options = [.caseInsensitive]) -> Bool {
        firstMatch(pattern, group: 0, options: options) != nil
    }

    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }

    /// Lowercased, accent-insensitive form used for keyword matching ("Köfte" → "kofte", "Çılbır" → "cilbir").
    var normalizedForMatching: String {
        folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en_US"))
            .replacingOccurrences(of: "ı", with: "i")
    }

    /// Drops leading bullets, emoji, dashes, etc. — anything before the first letter or number.
    var strippingLeadingSymbols: String {
        String(drop { !$0.isLetter && !$0.isNumber }).trimmed
    }

    /// Decodes HTML entities such as `&amp;`, `&quot;`, `&#39;` and `&#x1f35d;`.
    var decodingHTMLEntities: String {
        guard contains("&") else { return self }
        let named = ["amp": "&", "quot": "\"", "apos": "'", "lt": "<", "gt": ">", "nbsp": " "]
        var result = ""
        var index = startIndex
        while index < endIndex {
            if self[index] == "&", let semicolon = self[index...].prefix(12).firstIndex(of: ";") {
                let entity = String(self[self.index(after: index)..<semicolon])
                var decoded: String?
                if entity.hasPrefix("#x") || entity.hasPrefix("#X") {
                    decoded = UInt32(entity.dropFirst(2), radix: 16).flatMap { Unicode.Scalar($0) }.map { String(Character($0)) }
                } else if entity.hasPrefix("#") {
                    decoded = UInt32(entity.dropFirst()).flatMap { Unicode.Scalar($0) }.map { String(Character($0)) }
                } else {
                    decoded = named[entity]
                }
                if let decoded {
                    result += decoded
                    index = self.index(after: semicolon)
                    continue
                }
            }
            result.append(self[index])
            index = self.index(after: index)
        }
        return result
    }
}
