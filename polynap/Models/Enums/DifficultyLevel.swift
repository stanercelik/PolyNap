import Foundation

/// Represents the difficulty level of a sleep schedule
public enum DifficultyLevel: String, CaseIterable, Identifiable, Comparable {
    /// Basic sleep schedules suitable for beginners
    case beginner
    
    /// Moderately challenging sleep schedules
    case intermediate
    
    /// Challenging sleep schedules requiring dedication
    case advanced
    
    /// Extremely challenging sleep schedules requiring significant adaptation
    case extreme
    
    public var id: String { rawValue }
    
    var numericValue: Int {
        switch self {
        case .beginner: return 0
        case .intermediate: return 1
        case .advanced: return 2
        case .extreme: return 3
        }
    }
    
    public static func < (lhs: DifficultyLevel, rhs: DifficultyLevel) -> Bool {
        lhs.numericValue < rhs.numericValue
    }
    
    /// Returns a localized description of the difficulty level
    var localizedDescription: String {
        switch self {
        case .beginner:
            return NSLocalizedString("difficulty.beginner", tableName: "Common", comment: "Beginner difficulty")
        case .intermediate:
            return NSLocalizedString("difficulty.intermediate", tableName: "Common", comment: "Intermediate difficulty")
        case .advanced:
            return NSLocalizedString("difficulty.advanced", tableName: "Common", comment: "Advanced difficulty")
        case .extreme:
            return NSLocalizedString("difficulty.extreme", tableName: "Common", comment: "Extreme difficulty")
        }
    }
    
    /// Returns the recommended minimum adaptation period in days
    var recommendedAdaptationPeriod: Int {
        switch self {
        case .beginner: return 7
        case .intermediate: return 14
        case .advanced: return 21
        case .extreme: return 28
        }
    }
}
