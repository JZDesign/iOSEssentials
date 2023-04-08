import Foundation

public final class LocalFeedLoader: FeedLoader {
    let store: FeedStore
    let currentDate: () -> Date
    let cachePolicy = FeedCachePolicy()
    public typealias LoadResult = LoadFeedResult
    
    public init(store: FeedStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }
    
    public func load(completion: @escaping (LoadResult) -> Void) {
        store.retrieve { [weak self] result in
            guard let self else { return }

            switch result {
            case let .failure(error):
                completion(.failure(error))
        
            case let .found(feed: images, timeStamp: date) where self.cachePolicy.validate(date, against: self.currentDate()):
                    completion(.success(images.toFeedImage()))

            case .found, .empty:
                completion(.success([]))
            }
        }
    }
}

// MARK: - Save

public extension LocalFeedLoader {
    typealias SaveResult = Error?

    func save(_ items: [FeedImage], completion: @escaping (SaveResult) -> Void) {
        store.deleteCachedFeed { [weak self] error in
            guard let self else { return }

            if let cacheDeletionError = error{
                completion(cacheDeletionError)
            } else {
                self.cache(items, with: completion)
            }
        }
    }
}

// MARK: - Validate Cache

public extension LocalFeedLoader {
    func validateCache() {
        store.retrieve { [weak self]  result in
            guard let self else { return }

            switch result {
            case .failure:
                self.store.deleteCachedFeed { _ in }

            case let .found(feed: _, timeStamp: date) where !self.cachePolicy.validate(date, against: self.currentDate()):
                self.store.deleteCachedFeed { _ in }

            case .found, .empty:
                break
            }
        }
    }
}

// MARK: - Helpers

private extension LocalFeedLoader {
    func cache(_ items: [FeedImage], with completion: @escaping (Error?) -> Void) {
        store.insert(items.toLocal(), timeStamp: currentDate()) { [weak self] error in
            guard self != nil else { return }
            
            completion(error)
        }
    }
}

final class FeedCachePolicy {
    private let calendar: Calendar
    private let maxCacheAgeInDays: Int

    init(
        calendar: Calendar = .init(identifier: .gregorian),
        maxCacheAgeInDays: Int = 7
    ) {
        self.calendar = calendar
        self.maxCacheAgeInDays = maxCacheAgeInDays
    }
        
    func validate(_ timeStamp: Date, against date: Date) -> Bool {
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

private extension Array where Element == LocalFeedImage {
    func toFeedImage() -> [FeedImage] {
        map {
            FeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.url)
        }
    }
}

private extension Array where Element == FeedImage {
    func toLocal() -> [LocalFeedImage] {
        map(LocalFeedImage.from)
    }
}
