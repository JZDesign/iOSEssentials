import Foundation

public final class LocalFeedLoader: FeedLoader {
    let store: FeedStore
    let currentDate: () -> Date
    
    public init(store: FeedStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }
    
    public func load(completion: @escaping (LoadFeedResult) -> Void) {
        store.retrieve { [weak self] result in
            guard self != nil else { return }
            switch result {
            case let .failure(error):
                completion(.failure(error))
            case let .found(feed: images, timeStamp: date) where Self.validate(date):
                    completion(.success(images.toFeedImage()))
            case .found, .empty:
                completion(.success([]))
            }
        }
    }
    
    public func save(_ items: [FeedImage], completion: @escaping (Error?) -> Void) {
        store.deleteCachedFeed { [weak self] error in
            guard let self else { return }
            if error == nil {
                self.cache(items, with: completion)
            } else {
                completion(error)
            }
        }
    }
    
    public func validateCache() {
        store.retrieve { [weak self]  result in
            guard let self else { return }
            switch result {
            case .failure:
                self.store.deleteCachedFeed { _ in }
            case let .found(feed: _, timeStamp: date) where Self.validate(date):
                break
            case .found:
                self.store.deleteCachedFeed { _ in }
            case .empty:
                break
            }
        }
    }
    
    private func cache(_ items: [FeedImage], with completion: @escaping (Error?) -> Void) {
        store.insert(items.toLocal(), timeStamp: currentDate()) { [weak self] error in
            guard self != nil else { return }

            completion(error)
        }
    }
    
    private static var MAX_CACHE_AGE_IN_DAYS: Int { 7 }
    
    private static func validate(_ timeStamp: Date) -> Bool {
        let calendar = Calendar(identifier: .gregorian)
        guard let cacheExpiration = calendar.date(byAdding: .day, value: -MAX_CACHE_AGE_IN_DAYS, to: Date()) else {
            return false
        }
        return timeStamp > cacheExpiration
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
