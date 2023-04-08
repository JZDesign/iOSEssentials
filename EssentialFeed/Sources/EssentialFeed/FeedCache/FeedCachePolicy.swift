import Foundation

struct FeedCachePolicy {
    private init() {}

    private static let calendar: Calendar = .init(identifier: .gregorian)
    private static let maxCacheAgeInDays: Int = 7

    static func validate(_ timeStamp: Date, against date: Date) -> Bool {
        guard let maxCacheAge = calendar.date(
            byAdding: .day,
            value: maxCacheAgeInDays,
            to: timeStamp
        ) else {
            return false
        }

        return date < maxCacheAge
    }
}
