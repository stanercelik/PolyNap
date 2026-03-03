import SwiftUI

// MARK: - Badge Definition
struct BadgeDefinition: Identifiable, Equatable {
    let id: String               // e.g., "badge-starter", "badge-streak-3"
    let assetName: String        // matches NimmyBadges imageset name
    let gradientStart: Color
    let gradientEnd: Color
    let ringColor: Color
    var isEarned: Bool

    var name: String { L("badge.\(locKey).name", table: "Profile") }
    var description: String { L("badge.\(locKey).desc", table: "Profile") }
    var howToEarn: String { L("badge.\(locKey).how", table: "Profile") }

    // Converts "badge-first-log" → "firstLog" for key lookup (strips "badge-" prefix first)
    private var locKey: String {
        let stripped = id.hasPrefix("badge-") ? String(id.dropFirst(6)) : id
        let parts = stripped.split(separator: "-")
        let first = parts.first.map(String.init) ?? stripped
        let rest = parts.dropFirst().map { str -> String in
            let s = String(str)
            return s.prefix(1).uppercased() + s.dropFirst()
        }
        return ([first] + rest).joined()
    }

    static func == (lhs: BadgeDefinition, rhs: BadgeDefinition) -> Bool {
        lhs.id == rhs.id && lhs.isEarned == rhs.isEarned
    }
}

// MARK: - Badge Catalog
extension BadgeDefinition {
    static func all(earnedIds: Set<String>) -> [BadgeDefinition] {
        [
            BadgeDefinition(
                id: "badge-starter",
                assetName: "badge-starter",
                gradientStart: Color(red: 0.05, green: 0.11, blue: 0.24),
                gradientEnd:   Color(red: 0.10, green: 0.23, blue: 0.43),
                ringColor: .appBorder,
                isEarned: earnedIds.contains("badge-starter")
            ),
            BadgeDefinition(
                id: "badge-first-log",
                assetName: "badge-first-log",
                gradientStart: Color(red: 0.05, green: 0.11, blue: 0.24),
                gradientEnd:   Color(red: 0.10, green: 0.29, blue: 0.29),
                ringColor: .metricTeal,
                isEarned: earnedIds.contains("badge-first-log")
            ),
            BadgeDefinition(
                id: "badge-streak-3",
                assetName: "badge-streak-3",
                gradientStart: Color(red: 0.10, green: 0.06, blue: 0.00),
                gradientEnd:   Color(red: 0.24, green: 0.15, blue: 0.00),
                ringColor: .metricAmber,
                isEarned: earnedIds.contains("badge-streak-3")
            ),
            BadgeDefinition(
                id: "badge-bounce-back",
                assetName: "badge-bounce-back",
                gradientStart: Color(red: 0.10, green: 0.04, blue: 0.00),
                gradientEnd:   Color(red: 0.05, green: 0.13, blue: 0.13),
                ringColor: .appSecondary,
                isEarned: earnedIds.contains("badge-bounce-back")
            ),
            BadgeDefinition(
                id: "badge-one-week",
                assetName: "badge-one-week",
                gradientStart: Color(red: 0.10, green: 0.07, blue: 0.00),
                gradientEnd:   Color(red: 0.05, green: 0.11, blue: 0.24),
                ringColor: Color(red: 0.96, green: 0.78, blue: 0.26),
                isEarned: earnedIds.contains("badge-one-week")
            ),
            BadgeDefinition(
                id: "badge-night-owl",
                assetName: "badge-night-owl",
                gradientStart: Color(red: 0.02, green: 0.04, blue: 0.10),
                gradientEnd:   Color(red: 0.05, green: 0.11, blue: 0.24),
                ringColor: .appAccent,
                isEarned: earnedIds.contains("badge-night-owl")
            ),
            BadgeDefinition(
                id: "badge-halfway",
                assetName: "badge-halfway",
                gradientStart: Color(red: 0.10, green: 0.04, blue: 0.18),
                gradientEnd:   Color(red: 0.18, green: 0.11, blue: 0.41),
                ringColor: .metricPurple,
                isEarned: earnedIds.contains("badge-halfway")
            ),
            BadgeDefinition(
                id: "badge-adaptation-done",
                assetName: "badge-adaptation-done",
                gradientStart: Color(red: 0.05, green: 0.11, blue: 0.24),
                gradientEnd:   Color(red: 0.10, green: 0.36, blue: 0.24),
                ringColor: .metricEmerald,
                isEarned: earnedIds.contains("badge-adaptation-done")
            ),
            BadgeDefinition(
                id: "badge-one-month",
                assetName: "badge-one-month",
                gradientStart: Color(red: 0.10, green: 0.04, blue: 0.24),
                gradientEnd:   Color(red: 0.24, green: 0.10, blue: 0.00),
                ringColor: .metricAmber,
                isEarned: earnedIds.contains("badge-one-month")
            ),
            BadgeDefinition(
                id: "badge-premium",
                assetName: "badge-premium",
                gradientStart: Color(red: 0.05, green: 0.11, blue: 0.24),
                gradientEnd:   Color(red: 0.10, green: 0.07, blue: 0.00),
                ringColor: Color(red: 0.96, green: 0.78, blue: 0.26),
                isEarned: earnedIds.contains("badge-premium")
            ),
        ]
    }
}
