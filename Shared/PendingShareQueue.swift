import Foundation

/// A reel shared from Instagram via the Share Extension, waiting to be imported by the app.
struct PendingShare: Codable, Equatable {
    var url: String
    var caption: String
    var sharedAt: Date
}

/// Hands shared reels from the Share Extension to the main app through the App Group's
/// UserDefaults. The extension only enqueues; the app drains the queue when it becomes active.
enum PendingShareQueue {
    static let appGroupID = "group.com.berdem45.reelrecipes"
    private static let key = "pendingShares"

    private static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroupID) ?? .standard
    }

    static func enqueue(_ share: PendingShare) {
        var items = peek()
        items.append(share)
        save(items)
    }

    static func peek() -> [PendingShare] {
        guard let data = defaults.data(forKey: key) else { return [] }
        return (try? JSONDecoder().decode([PendingShare].self, from: data)) ?? []
    }

    /// Returns every queued share and empties the queue.
    static func drain() -> [PendingShare] {
        let items = peek()
        if !items.isEmpty { save([]) }
        return items
    }

    private static func save(_ items: [PendingShare]) {
        let data = try? JSONEncoder().encode(items)
        defaults.set(data, forKey: key)
    }
}
