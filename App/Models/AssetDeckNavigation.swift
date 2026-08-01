import Foundation

/// Pure deck-index math for swipe navigation. Left advances; right retreats.
enum AssetDeckNavigation {
    static func index(after current: Int, direction: SwipeDirection, count: Int) -> Int {
        guard count > 0 else { return 0 }
        let delta = direction == .left ? 1 : -1
        return (current + delta + count) % count
    }
}
